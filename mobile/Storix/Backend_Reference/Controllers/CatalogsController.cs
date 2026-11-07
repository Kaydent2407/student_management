
using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

// ==========================================
// DTO - LOAI SAN PHAM
// ==========================================
public record CategoryDto(
    long Id,
    string Code,
    string Name,
    long? ParentId,
    string? Description,
    string Status,
    string RowVersion
);

// ==========================================
// DTO - DON VI TINH
// ==========================================
public record UnitDto(
    long Id,
    string Code,
    string Name,
    string? Symbol,
    bool AllowDecimal,
    string Status,
    string RowVersion
);

// ==========================================
// DTO - QUY DOI DON VI
// ==========================================
public record ConversionDto(
    long Id,
    long ProductId,
    long UnitId,
    string UnitCode,
    string UnitName,
    decimal Factor,
    string Status
);

// ==========================================
// DTO - MA VACH
// ==========================================
public record BarcodeDto(
    string Code,
    string Type,
    long ProductId,
    string ProductCode,
    string ProductName,
    long? UnitId
);

[ApiController]
[Route("api/catalogs")]
public sealed class CatalogsController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<CatalogsController> _logger;

    public CatalogsController(
        IConfiguration config,
        ILogger<CatalogsController> logger)
    {
        _config = config;
        _logger = logger;
    }

    // ==========================================
    // HAM DUNG CHUNG DOC DU LIEU SQL SERVER
    // ==========================================
    private async Task<IActionResult> ReadListAsync<T>(
        string sql,
        Func<SqlDataReader, T> mapper,
        Action<SqlParameterCollection>? addParameters,
        CancellationToken ct)
    {
        string? connectionString =
            _config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return StatusCode(503, new
            {
                message = "Database chua duoc cau hinh."
            });
        }

        try
        {
            await using var connection =
                new SqlConnection(connectionString);

            await connection.OpenAsync(ct);

            await using var command =
                new SqlCommand(sql, connection);

            addParameters?.Invoke(command.Parameters);

            await using var reader =
                await command.ExecuteReaderAsync(ct);

            var results = new List<T>();

            while (await reader.ReadAsync(ct))
            {
                results.Add(mapper(reader));
            }

            return Ok(results);
        }
        catch (SqlException ex)
        {
            _logger.LogError(
                ex,
                "Cannot load catalog data"
            );

            return StatusCode(503, new
            {
                message = "Khong the tai du lieu danh muc."
            });
        }
    }

    // ==========================================
    // 1. LAY DANH SACH LOAI SAN PHAM
    // GET /api/catalogs/categories
    // ==========================================
    [HttpGet("categories")]
    [HasPermission("DANH_MUC.xem")]
    public Task<IActionResult> GetCategories(
        [FromQuery] bool activeOnly = true,
        CancellationToken ct = default)
    {
        const string sql = @"
            SELECT
                id,
                ma,
                ten,
                loai_cha_id,
                mo_ta,
                trang_thai,
                row_version
            FROM dbo.LOAI_SAN_PHAM
            WHERE
                @activeOnly = 0
                OR trang_thai = 'ACTIVE'
            ORDER BY ten, id;
        ";

        return ReadListAsync<CategoryDto>(
            sql,
            r => new CategoryDto(
                Id: r.GetInt64(0),
                Code: r.GetString(1),
                Name: r.GetString(2),
                ParentId: r.IsDBNull(3)
                    ? null
                    : r.GetInt64(3),
                Description: r.IsDBNull(4)
                    ? null
                    : r.GetString(4),
                Status: r.GetString(5),
                RowVersion: Convert.ToBase64String(
                    r.GetFieldValue<byte[]>(6)
                )
            ),
            p =>
            {
                p.Add("@activeOnly", SqlDbType.Bit)
                    .Value = activeOnly;
            },
            ct
        );
    }

    // ==========================================
    // 2. LAY DANH SACH DON VI TINH
    // GET /api/catalogs/units
    // ==========================================
    [HttpGet("units")]
    [HasPermission("DANH_MUC.xem")]
    public Task<IActionResult> GetUnits(
        [FromQuery] bool activeOnly = true,
        CancellationToken ct = default)
    {
        const string sql = @"
            SELECT
                id,
                ma,
                ten,
                ky_hieu,
                cho_so_le,
                trang_thai,
                row_version
            FROM dbo.DON_VI_TINH
            WHERE
                @activeOnly = 0
                OR trang_thai = 'ACTIVE'
            ORDER BY ten, id;
        ";

        return ReadListAsync<UnitDto>(
            sql,
            r => new UnitDto(
                Id: r.GetInt64(0),
                Code: r.GetString(1),
                Name: r.GetString(2),
                Symbol: r.IsDBNull(3)
                    ? null
                    : r.GetString(3),
                AllowDecimal: r.GetBoolean(4),
                Status: r.GetString(5),
                RowVersion: Convert.ToBase64String(
                    r.GetFieldValue<byte[]>(6)
                )
            ),
            p =>
            {
                p.Add("@activeOnly", SqlDbType.Bit)
                    .Value = activeOnly;
            },
            ct
        );
    }

    // ==========================================
    // 3. LAY QUY DOI DON VI CUA SAN PHAM
    // GET /api/catalogs/products/1/conversions
    // ==========================================
    [HttpGet("products/{productId:long}/conversions")]
    [HasPermission("DANH_MUC.xem")]
    public Task<IActionResult> GetConversions(
        long productId,
        CancellationToken ct)
    {
        if (productId <= 0)
        {
            return Task.FromResult<IActionResult>(
                BadRequest(new
                {
                    message = "ID san pham khong hop le."
                })
            );
        }

        const string sql = @"
            SELECT
                q.id,
                q.san_pham_id,
                q.don_vi_id,
                d.ma,
                d.ten,
                q.he_so_sang_co_so,
                q.trang_thai
            FROM dbo.QUY_DOI_DON_VI q
            INNER JOIN dbo.DON_VI_TINH d
                ON d.id = q.don_vi_id
            WHERE q.san_pham_id = @productId
            ORDER BY
                q.he_so_sang_co_so,
                q.id;
        ";

        return ReadListAsync<ConversionDto>(
            sql,
            r => new ConversionDto(
                Id: r.GetInt64(0),
                ProductId: r.GetInt64(1),
                UnitId: r.GetInt64(2),
                UnitCode: r.GetString(3),
                UnitName: r.GetString(4),
                Factor: r.GetDecimal(5),
                Status: r.GetString(6)
            ),
            p =>
            {
                p.Add("@productId", SqlDbType.BigInt)
                    .Value = productId;
            },
            ct
        );
    }

    // ==========================================
    // 4. TIM SAN PHAM BANG MA VACH
    // GET /api/catalogs/barcodes?code=ABC123
    // ==========================================
    [HttpGet("barcodes")]
    [HasPermission("MA_VACH.quet")]
    public Task<IActionResult> ResolveBarcode(
        [FromQuery] string? code,
        CancellationToken ct)
    {
        string barcode = code?.Trim() ?? "";

        if (barcode.Length == 0 ||
            barcode.Length > 160)
        {
            return Task.FromResult<IActionResult>(
                BadRequest(new
                {
                    message = "Ma vach khong hop le."
                })
            );
        }

        const string sql = @"
            SELECT
                mv.ma,
                mv.loai_ma,
                sp.id,
                sp.ma,
                sp.ten,
                mv.don_vi_id
            FROM dbo.MA_VACH mv
            INNER JOIN dbo.SAN_PHAM sp
                ON sp.id = mv.san_pham_id
            WHERE mv.ma = @code
              AND mv.trang_thai = 'ACTIVE'
              AND sp.trang_thai = 'ACTIVE';
        ";

        return ReadListAsync<BarcodeDto>(
            sql,
            r => new BarcodeDto(
                Code: r.GetString(0),
                Type: r.GetString(1),
                ProductId: r.GetInt64(2),
                ProductCode: r.GetString(3),
                ProductName: r.GetString(4),
                UnitId: r.IsDBNull(5)
                    ? null
                    : r.GetInt64(5)
            ),
            p =>
            {
                p.Add("@code", SqlDbType.VarChar, 160)
                    .Value = barcode;
            },
            ct
        );
    }
}
