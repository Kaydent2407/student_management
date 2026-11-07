
using System.Data;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

[ApiController]
[Route("api/warehouses")]
public sealed class WarehousesController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<WarehousesController> _logger;

    public WarehousesController(
        IConfiguration config,
        ILogger<WarehousesController> logger)
    {
        _config = config;
        _logger = logger;
    }

    // Lay ID nguoi dung tu JWT da duoc xac thuc.
    private long? GetCurrentUserId()
    {
        string? idText =
            User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        return long.TryParse(idText, out long id) && id > 0
            ? id
            : null;
    }

    private string? GetConnectionString()
    {
        return _config.GetConnectionString("StorixDb");
    }

    // Chi truy cap noi luu tru da duoc phan cong.
    private static async Task<bool> HasWarehouseAccessAsync(
        SqlConnection conn,
        long userId,
        long warehouseId,
        CancellationToken ct)
    {
        const string sql = @"
            SELECT 1
            FROM dbo.NOI_LUU_TRU n
            WHERE n.id = @warehouseId
              AND EXISTS (
                  SELECT 1
                  FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.noi_luu_tru_id = n.id
                    AND a.nguoi_dung_id = @userId
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (
                        a.den_ngay IS NULL
                        OR a.den_ngay > SYSUTCDATETIME()
                    )
              );
        ";

        await using var cmd = new SqlCommand(sql, conn);

        cmd.Parameters.Add("@userId", SqlDbType.BigInt)
            .Value = userId;

        cmd.Parameters.Add("@warehouseId", SqlDbType.BigInt)
            .Value = warehouseId;

        object? result = await cmd.ExecuteScalarAsync(ct);

        return result != null && result != DBNull.Value;
    }

    // =========================================
    // 1. DANH SACH KHO / BAI / CUA HANG
    // GET /api/warehouses
    // =========================================
    [HttpGet]
    [HasPermission("NOI_LUU_TRU.xem")]
    public async Task<IActionResult> GetWarehouses(
        CancellationToken ct)
    {
        long? userId = GetCurrentUserId();

        if (!userId.HasValue)
            return Unauthorized();

        string? cs = GetConnectionString();

        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503);

        const string sql = @"
            SELECT
                n.id,
                n.ma,
                n.ten,
                n.loai,
                n.dia_chi,
                n.nguoi_phu_trach_id,
                n.suc_chua,
                n.don_vi_suc_chua,
                n.trang_thai,
                n.row_version
            FROM dbo.NOI_LUU_TRU n
            WHERE EXISTS (
                SELECT 1
                FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                WHERE a.noi_luu_tru_id = n.id
                  AND a.nguoi_dung_id = @userId
                  AND a.trang_thai = 'ACTIVE'
                  AND a.tu_ngay <= SYSUTCDATETIME()
                  AND (
                      a.den_ngay IS NULL
                      OR a.den_ngay > SYSUTCDATETIME()
                  )
            )
            ORDER BY n.ma;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add("@userId", SqlDbType.BigInt)
                .Value = userId.Value;

            await using var reader =
                await cmd.ExecuteReaderAsync(ct);

            var items = new List<object>();

            while (await reader.ReadAsync(ct))
            {
                items.Add(new
                {
                    id = reader.GetInt64(0),
                    code = reader.GetString(1),
                    name = reader.GetString(2),
                    type = reader.GetString(3),
                    address = reader.GetString(4),

                    managerId = reader.IsDBNull(5)
                        ? (long?)null
                        : reader.GetInt64(5),

                    capacity = reader.IsDBNull(6)
                        ? (decimal?)null
                        : reader.GetDecimal(6),

                    capacityUnit = reader.IsDBNull(7)
                        ? null
                        : reader.GetString(7),

                    status = reader.GetString(8),

                    rowVersion = Convert.ToBase64String(
                        reader.GetFieldValue<byte[]>(9)
                    )
                });
            }

            return Ok(new
            {
                total = items.Count,
                items
            });
        }
        catch (SqlException ex)
        {
            _logger.LogError(
                ex,
                "Cannot load warehouses"
            );

            return StatusCode(503, new
            {
                message = "Khong the tai danh sach kho."
            });
        }
    }

    // =========================================
    // 2. DANH SACH VI TRI CUA MOT KHO
    // GET /api/warehouses/1/positions
    // =========================================
    [HttpGet("{warehouseId:long}/positions")]
    [HasPermission("NOI_LUU_TRU.xem")]
    public async Task<IActionResult> GetPositions(
        long warehouseId,
        CancellationToken ct)
    {
        long? userId = GetCurrentUserId();

        if (!userId.HasValue)
            return Unauthorized();

        if (warehouseId <= 0)
            return BadRequest(new
            {
                message = "WarehouseId khong hop le."
            });

        string? cs = GetConnectionString();

        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503);

        const string sql = @"
            SELECT
                v.id,
                v.noi_luu_tru_id,
                v.vi_tri_cha_id,
                v.ma,
                v.ten,
                v.cap_vi_tri,
                v.loai_vi_tri,
                v.suc_chua,
                v.don_vi_suc_chua,
                v.trang_thai,
                v.row_version
            FROM dbo.VI_TRI v
            WHERE v.noi_luu_tru_id = @warehouseId
            ORDER BY v.ma;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);

            bool allowed = await HasWarehouseAccessAsync(
                conn, userId.Value, warehouseId, ct);

            if (!allowed)
                return NotFound(new
                {
                    message = "Khong tim thay kho duoc phep truy cap."
                });

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add(
                "@warehouseId", SqlDbType.BigInt
            ).Value = warehouseId;

            await using var reader =
                await cmd.ExecuteReaderAsync(ct);

            var items = new List<object>();

            while (await reader.ReadAsync(ct))
            {
                items.Add(new
                {
                    id = reader.GetInt64(0),
                    warehouseId = reader.GetInt64(1),

                    parentId = reader.IsDBNull(2)
                        ? (long?)null
                        : reader.GetInt64(2),

                    code = reader.GetString(3),
                    name = reader.GetString(4),
                    level = reader.GetString(5),
                    type = reader.GetString(6),

                    capacity = reader.IsDBNull(7)
                        ? (decimal?)null
                        : reader.GetDecimal(7),

                    capacityUnit = reader.IsDBNull(8)
                        ? null
                        : reader.GetString(8),

                    status = reader.GetString(9),

                    rowVersion = Convert.ToBase64String(
                        reader.GetFieldValue<byte[]>(10)
                    )
                });
            }

            return Ok(new
            {
                warehouseId,
                total = items.Count,
                items
            });
        }
        catch (SqlException ex)
        {
            _logger.LogError(
                ex,
                "Cannot load warehouse positions"
            );

            return StatusCode(503, new
            {
                message = "Khong the tai vi tri luu tru."
            });
        }
    }

    // =========================================
    // 3. TRA CUU TON KHO THEO LO VA VI TRI
    // GET /api/warehouses/1/stock
    // =========================================
    [HttpGet("{warehouseId:long}/stock")]
    [HasPermission("TON_KHO.xem")]
    public async Task<IActionResult> GetStock(
        long warehouseId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken ct = default)
    {
        long? userId = GetCurrentUserId();

        if (!userId.HasValue)
            return Unauthorized();

        if (warehouseId <= 0 ||
            page < 1 ||
            pageSize < 1 ||
            pageSize > 100)
        {
            return BadRequest(new
            {
                message = "Tham so truy van khong hop le."
            });
        }

        string? cs = GetConnectionString();

        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503);

        const string sql = @"
            SELECT COUNT_BIG(*)
            FROM dbo.TON_KHO tk
            JOIN dbo.VI_TRI v
                ON v.id = tk.vi_tri_id
            WHERE v.noi_luu_tru_id = @warehouseId;

            SELECT
                tk.id,
                sp.id,
                sp.ma,
                sp.ten,
                l.id,
                l.ma_lo_noi_bo,
                l.han_su_dung,
                v.id,
                v.ma,
                v.ten,
                v.loai_vi_tri,
                v.trang_thai,
                tk.sl_tot,
                tk.sl_hong,
                tk.sl_giu
            FROM dbo.TON_KHO tk
            JOIN dbo.VI_TRI v
                ON v.id = tk.vi_tri_id
            JOIN dbo.LO_HANG l
                ON l.id = tk.lo_id
            JOIN dbo.SAN_PHAM sp
                ON sp.id = l.san_pham_id
            WHERE v.noi_luu_tru_id = @warehouseId
            ORDER BY sp.id, l.id, v.id, tk.id
            OFFSET @offset ROWS
            FETCH NEXT @pageSize ROWS ONLY;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(ct);

            bool allowed = await HasWarehouseAccessAsync(
                conn, userId.Value, warehouseId, ct);

            if (!allowed)
                return NotFound(new
                {
                    message = "Khong tim thay kho duoc phep truy cap."
                });

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add(
                "@warehouseId", SqlDbType.BigInt
            ).Value = warehouseId;

            cmd.Parameters.Add(
                "@offset", SqlDbType.BigInt
            ).Value = ((long)page - 1) * pageSize;

            cmd.Parameters.Add(
                "@pageSize", SqlDbType.Int
            ).Value = pageSize;

            await using var reader =
                await cmd.ExecuteReaderAsync(ct);

            await reader.ReadAsync(ct);
            long total = reader.GetInt64(0);

            await reader.NextResultAsync(ct);

            var items = new List<object>();

            while (await reader.ReadAsync(ct))
            {
                decimal good = reader.GetDecimal(12);
                decimal damaged = reader.GetDecimal(13);
                decimal reserved = reader.GetDecimal(14);

                items.Add(new
                {
                    stockId = reader.GetInt64(0),

                    productId = reader.GetInt64(1),
                    productCode = reader.GetString(2),
                    productName = reader.GetString(3),

                    lotId = reader.GetInt64(4),
                    lotCode = reader.GetString(5),

                    expiryDate = reader.IsDBNull(6)
                        ? (DateTime?)null
                        : reader.GetDateTime(6),

                    positionId = reader.GetInt64(7),
                    positionCode = reader.GetString(8),
                    positionName = reader.GetString(9),
                    positionType = reader.GetString(10),
                    positionStatus = reader.GetString(11),

                    goodQuantity = good,
                    damagedQuantity = damaged,
                    reservedQuantity = reserved,

                    availableGoodQuantity = good - reserved
                });
            }

            return Ok(new
            {
                warehouseId,
                page,
                pageSize,
                total,
                items
            });
        }
        catch (SqlException ex)
        {
            _logger.LogError(
                ex,
                "Cannot load warehouse stock"
            );

            return StatusCode(503, new
            {
                message = "Khong the tai ton kho."
            });
        }
    }
}
