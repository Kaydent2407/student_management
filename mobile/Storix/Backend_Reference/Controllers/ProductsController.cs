
using System.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

[ApiController]
[Route("api/products")]
public sealed class ProductsController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IConfiguration config,
        ILogger<ProductsController> logger)
    {
        _config = config;
        _logger = logger;
    }

    private const string ProductColumns = @"
        SELECT
            sp.id,
            sp.ma,
            sp.ten,
            sp.loai_id,
            l.ten AS ten_loai,
            sp.don_vi_co_so_id,
            d.ten AS ten_don_vi,
            sp.gia_ban_hien_tai,
            sp.theo_doi_hsd,
            sp.duong_dan_anh,
            sp.trang_thai,
            sp.row_version
    ";

    private const string ProductTables = @"
        FROM dbo.SAN_PHAM sp
        JOIN dbo.LOAI_SAN_PHAM l
            ON l.id = sp.loai_id
        JOIN dbo.DON_VI_TINH d
            ON d.id = sp.don_vi_co_so_id
    ";

    // GET /api/products
    [HttpGet]
    [HasPermission("SAN_PHAM.xem")]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (page < 1 || pageSize < 1 || pageSize > 100)
        {
            return BadRequest(new
            {
                message = "Page phai >= 1, pageSize tu 1 den 100."
            });
        }

        string keyword = search?.Trim() ?? "";

        if (keyword.Length > 100)
        {
            return BadRequest(new
            {
                message = "Tu khoa toi da 100 ky tu."
            });
        }

        string? filterStatus =
            status?.Trim().ToUpperInvariant();

        if (string.IsNullOrWhiteSpace(filterStatus))
            filterStatus = null;

        if (filterStatus != null &&
            filterStatus != "ACTIVE" &&
            filterStatus != "INACTIVE")
        {
            return BadRequest(new
            {
                message = "Status phai la ACTIVE hoac INACTIVE."
            });
        }

        string? cs = _config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503);

        const string filter = @"
            WHERE (
                @search = N''
                OR CHARINDEX(@search, sp.ma) > 0
                OR CHARINDEX(@search, sp.ten) > 0
            )
            AND (
                @status IS NULL
                OR sp.trang_thai = @status
            )
        ";

        string sql = $@"
            SELECT COUNT_BIG(*)
            {ProductTables}
            {filter};

            {ProductColumns}
            {ProductTables}
            {filter}
            ORDER BY sp.id DESC
            OFFSET @offset ROWS
            FETCH NEXT @pageSize ROWS ONLY;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(cancellationToken);

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add(
                "@search", SqlDbType.NVarChar, 100
            ).Value = keyword;

            cmd.Parameters.Add(
                "@status", SqlDbType.VarChar, 16
            ).Value = (object?)filterStatus ?? DBNull.Value;

            cmd.Parameters.Add(
                "@offset", SqlDbType.BigInt
            ).Value = ((long)page - 1) * pageSize;

            cmd.Parameters.Add(
                "@pageSize", SqlDbType.Int
            ).Value = pageSize;

            await using var reader =
                await cmd.ExecuteReaderAsync(cancellationToken);

            await reader.ReadAsync(cancellationToken);
            long total = reader.GetInt64(0);

            await reader.NextResultAsync(cancellationToken);

            var products = new List<object>();

            while (await reader.ReadAsync(cancellationToken))
            {
                products.Add(MapProduct(reader));
            }

            return Ok(new
            {
                page,
                pageSize,
                total,
                totalPages = (long)Math.Ceiling(
                    (double)total / pageSize
                ),
                items = products
            });
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Cannot load products");

            return StatusCode(503, new
            {
                message = "Khong the tai danh sach san pham."
            });
        }
    }

    // GET /api/products/1
    [HttpGet("{id:long}")]
    [HasPermission("SAN_PHAM.xem")]
    public async Task<IActionResult> GetById(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
            return BadRequest();

        string? cs = _config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(cs))
            return StatusCode(503);

        string sql = $@"
            {ProductColumns}
            {ProductTables}
            WHERE sp.id = @id;
        ";

        try
        {
            await using var conn = new SqlConnection(cs);
            await conn.OpenAsync(cancellationToken);

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add(
                "@id", SqlDbType.BigInt
            ).Value = id;

            await using var reader =
                await cmd.ExecuteReaderAsync(cancellationToken);

            if (!await reader.ReadAsync(cancellationToken))
            {
                return NotFound(new
                {
                    message = "Khong tim thay san pham."
                });
            }

            return Ok(MapProduct(reader));
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Cannot load product");

            return StatusCode(503, new
            {
                message = "Khong the tai san pham."
            });
        }
    }

    private static object MapProduct(SqlDataReader r)
    {
        return new
        {
            id = r.GetInt64(0),
            code = r.GetString(1),
            name = r.GetString(2),
            categoryId = r.GetInt64(3),
            categoryName = r.GetString(4),
            baseUnitId = r.GetInt64(5),
            baseUnitName = r.GetString(6),
            sellingPrice = r.GetDecimal(7),
            trackExpiry = r.GetBoolean(8),
            imageUrl = r.IsDBNull(9)
                ? null
                : r.GetString(9),
            status = r.GetString(10),
            rowVersion = Convert.ToBase64String(
                r.GetFieldValue<byte[]>(11))
                
        };
    }
}
