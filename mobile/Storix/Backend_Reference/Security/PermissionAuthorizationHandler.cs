
using System.Data;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Data.SqlClient;

namespace Storix.Api.Security;

public sealed class PermissionAuthorizationHandler
    : AuthorizationHandler<PermissionRequirement>
{
    private readonly IConfiguration _config;
    private readonly ILogger<PermissionAuthorizationHandler> _logger;

    public PermissionAuthorizationHandler(
        IConfiguration config,
        ILogger<PermissionAuthorizationHandler> logger)
    {
        _config = config;
        _logger = logger;
    }

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionRequirement requirement)
    {
        if (context.User.Identity?.IsAuthenticated != true)
            return;

        string? idText = context.User
            .FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!long.TryParse(idText, out long userId))
            return;

        string? connectionString =
            _config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(connectionString))
            return;

        const string sql = @"
            DECLARE @now DATETIME2(3) = SYSUTCDATETIME();

            SELECT
                CASE
                    -- DENY có độ ưu tiên cao nhất.
                    WHEN EXISTS (
                        SELECT 1
                        FROM dbo.NGUOI_DUNG_QUYEN nq
                        WHERE nq.nguoi_dung_id = @userId
                          AND nq.quyen_id = q.id
                          AND nq.loai_ngoai_le = 'DENY'
                          AND nq.trang_thai = 'ACTIVE'
                          AND nq.revoked_at IS NULL
                          AND nq.hieu_luc_tu <= @now
                          AND (
                              nq.hieu_luc_den IS NULL
                              OR nq.hieu_luc_den > @now
                          )
                    ) THEN 0

                    -- Ngoại lệ GRANT hợp lệ.
                    WHEN EXISTS (
                        SELECT 1
                        FROM dbo.NGUOI_DUNG_QUYEN nq
                        WHERE nq.nguoi_dung_id = @userId
                          AND nq.quyen_id = q.id
                          AND nq.loai_ngoai_le = 'GRANT'
                          AND nq.trang_thai = 'ACTIVE'
                          AND nq.revoked_at IS NULL
                          AND nq.hieu_luc_tu <= @now
                          AND (
                              nq.hieu_luc_den IS NULL
                              OR nq.hieu_luc_den > @now
                          )
                    ) THEN 1

                    -- Quyền được cấp theo vai trò chính.
                    WHEN EXISTS (
                        SELECT 1
                        FROM dbo.NGUOI_DUNG nd
                        JOIN dbo.VAI_TRO_QUYEN vtq
                          ON vtq.vai_tro_id = nd.vai_tro_id
                        WHERE nd.id = @userId
                          AND vtq.quyen_id = q.id
                          AND vtq.trang_thai = 'ACTIVE'
                    ) THEN 1

                    ELSE 0
                END AS duoc_phep
            FROM dbo.QUYEN q
            WHERE q.ma_quyen = @permission
              AND q.trang_thai = 'ACTIVE';
        ";

        try
        {
            await using var connection =
                new SqlConnection(connectionString);

            await connection.OpenAsync();

            await using var command =
                new SqlCommand(sql, connection);

            command.Parameters.Add(
                "@userId",
                SqlDbType.BigInt
            ).Value = userId;

            command.Parameters.Add(
                "@permission",
                SqlDbType.VarChar,
                100
            ).Value = requirement.Permission;

            object? result = await command.ExecuteScalarAsync();

            if (result != null &&
                result != DBNull.Value &&
                Convert.ToInt32(result) == 1)
            {
                context.Succeed(requirement);
            }
        }
        catch (SqlException ex)
        {
            _logger.LogError(
                ex,
                "Permission check failed for user {UserId}",
                userId);

            // Không cấp quyền nếu database lỗi.
        }
    }
}
