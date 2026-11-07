using System.Data;
using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

public sealed record CreateWarehouseRequest(
    string Code, string Name, string Type, string Address,
    decimal? Capacity, string? CapacityUnit, string? Notes);

public sealed record UpdateWarehouseRequest(
    string Name, string Address, string? Notes, string RowVersion);

public sealed record CreatePositionRequest(
    string Code, string Name, string Level, string PositionType,
    long? ParentId, decimal? Capacity, string? CapacityUnit, string? Notes);

public sealed record UpdatePositionRequest(
    string Name, string? Notes, string RowVersion);

[ApiController]
[Route("api/warehouses")]
public sealed class WarehousesWriteController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<WarehousesWriteController> _logger;

    public WarehousesWriteController(
        IConfiguration config, ILogger<WarehousesWriteController> logger)
    {
        _config = config;
        _logger = logger;
    }

    private long? CurrentUserId()
    {
        string? value = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;
        return long.TryParse(value, out long id) && id > 0 ? id : null;
    }

    private static bool ValidCode(string value, int max) =>
        value.Length is > 0 && value.Length <= max &&
        Regex.IsMatch(value, @"^[A-Za-z0-9][A-Za-z0-9_.-]*$");

    private static bool ValidName(string value) =>
        value.Length is > 0 && value.Length <= 200;

    private static bool ValidNotes(string? value) =>
        value is null || value.Length <= 500;

    private static bool ValidCapacity(decimal? capacity, string? unit)
    {
        if (capacity is null)
            return string.IsNullOrWhiteSpace(unit);
        return capacity.Value > 0 &&
            capacity.Value <= 999999999999999m &&
            decimal.Round(capacity.Value, 3) == capacity.Value &&
            unit is "KG" or "M3";
    }

    private static byte[]? ReadVersion(string? base64)
    {
        try
        {
            byte[] bytes = Convert.FromBase64String(base64 ?? "");
            return bytes.Length == 8 ? bytes : null;
        }
        catch (FormatException) { return null; }
    }

    private static void Add(SqlCommand cmd, string name, SqlDbType type,
        object? value, int size = 0)
    {
        var p = size > 0
            ? cmd.Parameters.Add(name, type, size)
            : cmd.Parameters.Add(name, type);
        if (type == SqlDbType.Decimal)
        {
            p.Precision = 18;
            p.Scale = 3;
        }
        p.Value = value ?? DBNull.Value;
    }

    private IActionResult DatabaseError(SqlException ex)
    {
        _logger.LogError(ex, "Warehouse write operation failed");
        return ex.Number switch
        {
            2601 or 2627 => Conflict(new { message = "Ma da ton tai." }),
            547 => BadRequest(new { message = "Du lieu tham chieu khong hop le." }),
            _ => StatusCode(503, new { message = "Khong the xu ly du lieu kho." })
        };
    }

    // POST /api/warehouses
    [HttpPost]
    [HasPermission("NOI_LUU_TRU.tao")]
    public async Task<IActionResult> CreateWarehouse(
        [FromBody] CreateWarehouseRequest request, CancellationToken ct)
    {
        string code = (request.Code ?? "").Trim();
        string name = (request.Name ?? "").Trim();
        string type = (request.Type ?? "").Trim().ToUpperInvariant();
        string address = (request.Address ?? "").Trim();
        string? unit = request.CapacityUnit?.Trim().ToUpperInvariant();
        string? notes = request.Notes?.Trim();

        if (!ValidCode(code, 32) || !ValidName(name) ||
            address.Length is < 1 or > 500 ||
            type is not ("KHO" or "BAI" or "CUA_HANG") ||
            !ValidCapacity(request.Capacity, unit) || !ValidNotes(notes))
            return BadRequest(new { message = "Thong tin kho khong hop le." });

        const string sql = @"
            INSERT dbo.NOI_LUU_TRU
                (ma, ten, loai, dia_chi, suc_chua, don_vi_suc_chua, ghi_chu)
            VALUES
                (@code, @name, @type, @address, @capacity, @unit, @notes);
            SELECT CONVERT(BIGINT, SCOPE_IDENTITY());";

        string? cs = _config.GetConnectionString("StorixDb");
        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503, new { message = "Chua cau hinh StorixDb." });

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            Add(cmd, "@code", SqlDbType.VarChar, code, 32);
            Add(cmd, "@name", SqlDbType.NVarChar, name, 200);
            Add(cmd, "@type", SqlDbType.VarChar, type, 16);
            Add(cmd, "@address", SqlDbType.NVarChar, address, 500);
            Add(cmd, "@capacity", SqlDbType.Decimal, request.Capacity);
            Add(cmd, "@unit", SqlDbType.VarChar, unit, 8);
            Add(cmd, "@notes", SqlDbType.NVarChar, notes, 500);
            long id = Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));
            return StatusCode(201, new
            {
                id, message = "Tao noi luu tru thanh cong.",
                assignmentRequired = true
            });
        }
        catch (SqlException ex) { return DatabaseError(ex); }
    }

    // PUT /api/warehouses/{id}: chi sua ten/dia chi/ghi chu
    [HttpPut("{id:long}")]
    [HasPermission("NOI_LUU_TRU.sua")]
    public async Task<IActionResult> UpdateWarehouse(
        long id, [FromBody] UpdateWarehouseRequest request,
        CancellationToken ct)
    {
        long? userId = CurrentUserId();
        byte[]? version = ReadVersion(request.RowVersion);
        string name = (request.Name ?? "").Trim();
        string address = (request.Address ?? "").Trim();
        string? notes = request.Notes?.Trim();
        if (id <= 0 || !userId.HasValue || version is null ||
            !ValidName(name) || address.Length is < 1 or > 500 ||
            !ValidNotes(notes))
            return BadRequest(new { message = "Thong tin hoac rowVersion khong hop le." });

        const string sql = @"
            UPDATE n SET ten = @name, dia_chi = @address,
                ghi_chu = @notes, updated_at = SYSUTCDATETIME()
            FROM dbo.NOI_LUU_TRU n
            WHERE n.id = @id AND n.row_version = @version
              AND EXISTS (
                  SELECT 1 FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.noi_luu_tru_id = n.id
                    AND a.nguoi_dung_id = @userId
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
              );
            DECLARE @changed INT = @@ROWCOUNT;
            SELECT row_version FROM dbo.NOI_LUU_TRU
            WHERE id = @id AND @changed = 1;";

        string? cs = _config.GetConnectionString("StorixDb");
        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503, new { message = "Chua cau hinh StorixDb." });

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            Add(cmd, "@id", SqlDbType.BigInt, id);
            Add(cmd, "@userId", SqlDbType.BigInt, userId.Value);
            Add(cmd, "@version", SqlDbType.Binary, version, 8);
            Add(cmd, "@name", SqlDbType.NVarChar, name, 200);
            Add(cmd, "@address", SqlDbType.NVarChar, address, 500);
            Add(cmd, "@notes", SqlDbType.NVarChar, notes, 500);
            object? result = await cmd.ExecuteScalarAsync(ct);
            if (result is not byte[] next)
                return Conflict(new { message = "Khong co quyen, khong ton tai hoac du lieu da thay doi." });
            return Ok(new { id, rowVersion = Convert.ToBase64String(next) });
        }
        catch (SqlException ex) { return DatabaseError(ex); }
    }

    // POST /api/warehouses/{warehouseId}/positions
    [HttpPost("{warehouseId:long}/positions")]
    [HasPermission("NOI_LUU_TRU.tao")]
    public async Task<IActionResult> CreatePosition(
        long warehouseId, [FromBody] CreatePositionRequest request,
        CancellationToken ct)
    {
        long? userId = CurrentUserId();
        string code = (request.Code ?? "").Trim();
        string name = (request.Name ?? "").Trim();
        string level = (request.Level ?? "").Trim().ToUpperInvariant();
        string type = (request.PositionType ?? "").Trim().ToUpperInvariant();
        string? unit = request.CapacityUnit?.Trim().ToUpperInvariant();
        string? notes = request.Notes?.Trim();

        if (warehouseId <= 0 || !userId.HasValue ||
            !ValidCode(code, 50) || !ValidName(name) ||
            level is not ("KHU" or "DAY" or "KE" or "TANG" or "O" or "QUAY") ||
            type is not ("THUONG" or "CACH_LY") ||
            request.ParentId is <= 0 ||
            !ValidCapacity(request.Capacity, unit) || !ValidNotes(notes))
            return BadRequest(new { message = "Thong tin vi tri khong hop le." });

        const string sql = @"
            INSERT dbo.VI_TRI
                (noi_luu_tru_id, vi_tri_cha_id, ma, ten, cap_vi_tri,
                 loai_vi_tri, suc_chua, don_vi_suc_chua, ghi_chu)
            SELECT
                @warehouseId, @parentId, @code, @name, @level,
                @type, @capacity, @unit, @notes
            WHERE EXISTS (
                SELECT 1 FROM dbo.NOI_LUU_TRU n
                JOIN dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  ON a.noi_luu_tru_id = n.id
                WHERE n.id = @warehouseId AND n.trang_thai = 'ACTIVE'
                  AND a.nguoi_dung_id = @userId
                  AND a.trang_thai = 'ACTIVE'
                  AND a.tu_ngay <= SYSUTCDATETIME()
                  AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
            )
            AND (
                @parentId IS NULL OR EXISTS (
                    SELECT 1 FROM dbo.VI_TRI parent
                    WHERE parent.id = @parentId
                      AND parent.noi_luu_tru_id = @warehouseId
                      AND parent.trang_thai = 'ACTIVE'
                      AND NOT EXISTS (
                          SELECT 1 FROM dbo.TON_KHO tk
                          WHERE tk.vi_tri_id = parent.id
                      )
                )
            );
            DECLARE @changed INT = @@ROWCOUNT;
            SELECT CASE WHEN @changed = 1
                THEN CONVERT(BIGINT, SCOPE_IDENTITY())
                ELSE CAST(NULL AS BIGINT) END;";

        string? cs = _config.GetConnectionString("StorixDb");
        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503, new { message = "Chua cau hinh StorixDb." });

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            Add(cmd, "@warehouseId", SqlDbType.BigInt, warehouseId);
            Add(cmd, "@userId", SqlDbType.BigInt, userId.Value);
            Add(cmd, "@parentId", SqlDbType.BigInt, request.ParentId);
            Add(cmd, "@code", SqlDbType.VarChar, code, 50);
            Add(cmd, "@name", SqlDbType.NVarChar, name, 200);
            Add(cmd, "@level", SqlDbType.VarChar, level, 16);
            Add(cmd, "@type", SqlDbType.VarChar, type, 16);
            Add(cmd, "@capacity", SqlDbType.Decimal, request.Capacity);
            Add(cmd, "@unit", SqlDbType.VarChar, unit, 8);
            Add(cmd, "@notes", SqlDbType.NVarChar, notes, 500);
            object? result = await cmd.ExecuteScalarAsync(ct);
            if (result is null || result == DBNull.Value)
                return Conflict(new { message = "Kho khong duoc phan cong, da khoa, hoac vi tri cha khong hop le." });
            long id = Convert.ToInt64(result);
            return StatusCode(201, new { id, warehouseId });
        }
        catch (SqlException ex) { return DatabaseError(ex); }
    }

    // PUT /api/warehouses/{warehouseId}/positions/{positionId}
    // Chi sua ten/ghi chu, KHONG doi cha, ma, loai hay suc chua.
    [HttpPut("{warehouseId:long}/positions/{positionId:long}")]
    [HasPermission("NOI_LUU_TRU.sua")]
    public async Task<IActionResult> UpdatePosition(
        long warehouseId, long positionId,
        [FromBody] UpdatePositionRequest request, CancellationToken ct)
    {
        long? userId = CurrentUserId();
        byte[]? version = ReadVersion(request.RowVersion);
        string name = (request.Name ?? "").Trim();
        string? notes = request.Notes?.Trim();
        if (warehouseId <= 0 || positionId <= 0 || !userId.HasValue ||
            version is null || !ValidName(name) || !ValidNotes(notes))
            return BadRequest(new { message = "Thong tin hoac rowVersion khong hop le." });

        const string sql = @"
            UPDATE v SET ten = @name, ghi_chu = @notes,
                updated_at = SYSUTCDATETIME()
            FROM dbo.VI_TRI v
            WHERE v.id = @positionId
              AND v.noi_luu_tru_id = @warehouseId
              AND v.row_version = @version
              AND EXISTS (
                  SELECT 1 FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.noi_luu_tru_id = v.noi_luu_tru_id
                    AND a.nguoi_dung_id = @userId
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
              );
            DECLARE @changed INT = @@ROWCOUNT;
            SELECT row_version FROM dbo.VI_TRI
            WHERE id = @positionId AND @changed = 1;";

        string? cs = _config.GetConnectionString("StorixDb");
        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503, new { message = "Chua cau hinh StorixDb." });

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            Add(cmd, "@warehouseId", SqlDbType.BigInt, warehouseId);
            Add(cmd, "@positionId", SqlDbType.BigInt, positionId);
            Add(cmd, "@userId", SqlDbType.BigInt, userId.Value);
            Add(cmd, "@version", SqlDbType.Binary, version, 8);
            Add(cmd, "@name", SqlDbType.NVarChar, name, 200);
            Add(cmd, "@notes", SqlDbType.NVarChar, notes, 500);
            object? result = await cmd.ExecuteScalarAsync(ct);
            if (result is not byte[] next)
                return Conflict(new { message = "Khong co quyen, khong ton tai hoac du lieu da thay doi." });
            return Ok(new
            {
                warehouseId, positionId,
                rowVersion = Convert.ToBase64String(next)
            });
        }
        catch (SqlException ex) { return DatabaseError(ex); }
    }
}
