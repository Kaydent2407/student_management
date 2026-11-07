
using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Data.SqlClient;

namespace Storix.Api.Security;

public static class JwtAccountValidator
{
    public static async Task ValidateAsync(
        TokenValidatedContext context)
    {
        var user = context.Principal;

        string? idText =
            user?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? user?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        string? versionText =
            user?.FindFirst("auth_version")?.Value;

        string? tokenRole =
            user?.FindFirst(ClaimTypes.Role)?.Value;

        if (!long.TryParse(idText, out long userId) ||
            !int.TryParse(versionText, out int tokenVersion) ||
            string.IsNullOrWhiteSpace(tokenRole))
        {
            context.Fail("Invalid token claims.");
            return;
        }

        var config = context.HttpContext.RequestServices
            .GetRequiredService<IConfiguration>();

        string? cs = config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(cs))
        {
            context.Fail("Database configuration unavailable.");
            return;
        }

        const string sql = @"
            SELECT
                nd.auth_version,
                nd.bat_buoc_doi_mat_khau,
                nd.trang_thai,
                vt.ma_vai_tro,
                vt.trang_thai,
                CASE
                    WHEN nd.khoa_den > SYSUTCDATETIME()
                    THEN CAST(1 AS BIT)
                    ELSE CAST(0 AS BIT)
                END
            FROM dbo.NGUOI_DUNG nd
            JOIN dbo.VAI_TRO vt
                ON vt.id = nd.vai_tro_id
            WHERE nd.id = @id;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(
                context.HttpContext.RequestAborted);

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add("@id", SqlDbType.BigInt)
                .Value = userId;

            await using var reader = await cmd.ExecuteReaderAsync(
                context.HttpContext.RequestAborted);

            if (!await reader.ReadAsync(
                context.HttpContext.RequestAborted))
            {
                context.Fail("Account not found.");
                return;
            }

            int dbVersion = reader.GetInt32(0);
            bool mustChange = reader.GetBoolean(1);
            string accountStatus = reader.GetString(2);
            string dbRole = reader.GetString(3);
            string roleStatus = reader.GetString(4);
            bool isLocked = reader.GetBoolean(5);

            if (dbVersion != tokenVersion ||
                accountStatus != "ACTIVE" ||
                roleStatus != "ACTIVE" ||
                dbRole != tokenRole ||
                isLocked)
            {
                context.Fail("Account or session is invalid.");
                return;
            }

            string path =
                context.HttpContext.Request.Path.Value ?? "";

            bool allowedForPasswordChange =
                path.Equals("/api/auth/me",
                    StringComparison.OrdinalIgnoreCase) ||
                path.Equals("/api/auth/change-password",
                    StringComparison.OrdinalIgnoreCase);

            if (mustChange && !allowedForPasswordChange)
            {
                context.Fail("Password change required.");
            }
        }
        catch (SqlException)
        {
            context.Fail("Cannot validate account.");
        }
    }
}
