using System.Data;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

public sealed class CreateCategoryRequest
{
    [Required] public string Code { get; set; } = "";
    [Required] public string Name { get; set; } = "";
    public long? ParentId { get; set; }
    public string? Description { get; set; }
}

public sealed class UpdateCategoryRequest
{
    [Required] public string Name { get; set; } = "";
    public string? Description { get; set; }
    [Required] public string RowVersion { get; set; } = "";
}

public sealed class CreateUnitRequest
{
    [Required] public string Code { get; set; } = "";
    [Required] public string Name { get; set; } = "";
    public string? Symbol { get; set; }
    public bool AllowDecimal { get; set; }
}

public sealed class UpdateUnitRequest
{
    [Required] public string Name { get; set; } = "";
    public string? Symbol { get; set; }
    [Required] public string RowVersion { get; set; } = "";
}

public sealed class CreateConversionRequest
{
    public long UnitId { get; set; }
    public decimal Factor { get; set; }
}

public sealed class CreateProductBarcodeRequest
{
    [Required] public string Code { get; set; } = "";
    [Required] public string Type { get; set; } = "BARCODE";
    public long ProductId { get; set; }
    public long? UnitId { get; set; }
}

[ApiController]
[Route("api/catalogs")]
public sealed class CatalogsWriteController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<CatalogsWriteController> _logger;

    public CatalogsWriteController(
        IConfiguration config, ILogger<CatalogsWriteController> logger)
    {
        _config = config;
        _logger = logger;
    }

    private static byte[]? ParseRowVersion(string? value)
    {
        try
        {
            byte[] decoded = Convert.FromBase64String(value ?? "");
            return decoded.Length == 8 ? decoded : null;
        }
        catch (FormatException)
        {
            return null;
        }
    }

    private static bool ValidCode(string value, int maxLength) =>
        value.Length > 0 && value.Length <= maxLength &&
        System.Text.RegularExpressions.Regex.IsMatch(
            value, @"^[A-Za-z0-9][A-Za-z0-9_.-]*$");

    private string GetConnectionString() =>
        _config.GetConnectionString("StorixDb") ??
        throw new InvalidOperationException("Missing ConnectionStrings:StorixDb");

    private IActionResult SqlProblem(SqlException ex)
    {
        _logger.LogError(ex, "Catalog write SQL error {SqlErrorNumber}", ex.Number);
        return ex.Number switch
        {
            2601 or 2627 => Conflict(new { message = "Ma hoac lien ket da ton tai." }),
            547 => BadRequest(new { message = "Vi pham rang buoc tham chieu / du lieu." }),
            229 => StatusCode(503, new { message = "Tai khoan SQL chua duoc cap du quyen." }),
            _ => StatusCode(503, new { message = "Khong the xu ly du lieu danh muc." })
        };
    }

    // 1. POST /api/catalogs/categories
    [HttpPost("categories")]
    [HasPermission("DANH_MUC.tao")]
    public async Task<IActionResult> CreateCategory(
        [FromBody] CreateCategoryRequest request, CancellationToken ct)
    {
        string code = (request.Code ?? "").Trim();
        string name = (request.Name ?? "").Trim();
        if (!ValidCode(code, 40) || name.Length is < 1 or > 180 ||
            (request.Description?.Length ?? 0) > 500 ||
            request.ParentId is <= 0)
            return BadRequest(new { message = "Thong tin loai san pham khong hop le." });

        const string sql = @"
            INSERT dbo.LOAI_SAN_PHAM(ma, ten, loai_cha_id, mo_ta)
            OUTPUT INSERTED.id
            SELECT @code, @name, @parent, @description
            WHERE @parent IS NULL OR EXISTS (
                SELECT 1 FROM dbo.LOAI_SAN_PHAM
                WHERE id = @parent AND trang_thai = 'ACTIVE'
            );";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@code", SqlDbType.VarChar, 40).Value = code;
            cmd.Parameters.Add("@name", SqlDbType.NVarChar, 180).Value = name;
            cmd.Parameters.Add("@parent", SqlDbType.BigInt).Value =
                (object?)request.ParentId ?? DBNull.Value;
            cmd.Parameters.Add("@description", SqlDbType.NVarChar, 500).Value =
                (object?)request.Description ?? DBNull.Value;
            object? id = await cmd.ExecuteScalarAsync(ct);
            return id is null
                ? BadRequest(new { message = "Loai cha khong ton tai hoac khong hoat dong." })
                : Created($"/api/catalogs/categories", new { id = Convert.ToInt64(id) });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }

    // 2. PUT /api/catalogs/categories/5
    // Chi sua ten/mo ta. Khong doi loai cha va trang thai trong giai doan nay.
    [HttpPut("categories/{id:long}")]
    [HasPermission("DANH_MUC.sua")]
    public async Task<IActionResult> UpdateCategory(
        long id, [FromBody] UpdateCategoryRequest request, CancellationToken ct)
    {
        string name = (request.Name ?? "").Trim();
        byte[]? version = ParseRowVersion(request.RowVersion);
        if (id <= 0 || version is null || name.Length is < 1 or > 180 ||
            (request.Description?.Length ?? 0) > 500)
            return BadRequest(new { message = "Ten hoac rowVersion khong hop le." });

        const string sql = @"
            UPDATE dbo.LOAI_SAN_PHAM
            SET ten = @name, mo_ta = @description, updated_at = SYSUTCDATETIME()
            OUTPUT INSERTED.row_version
            WHERE id = @id AND row_version = @version;";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@id", SqlDbType.BigInt).Value = id;
            cmd.Parameters.Add("@version", SqlDbType.Binary, 8).Value = version;
            cmd.Parameters.Add("@name", SqlDbType.NVarChar, 180).Value = name;
            cmd.Parameters.Add("@description", SqlDbType.NVarChar, 500).Value =
                (object?)request.Description ?? DBNull.Value;
            object? result = await cmd.ExecuteScalarAsync(ct);
            return result is byte[] updated
                ? Ok(new { id, rowVersion = Convert.ToBase64String(updated) })
                : Conflict(new { message = "Khong tim thay hoac danh muc da bi nguoi khac sua." });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }

    // 3. POST /api/catalogs/units
    [HttpPost("units")]
    [HasPermission("DANH_MUC.tao")]
    public async Task<IActionResult> CreateUnit(
        [FromBody] CreateUnitRequest request, CancellationToken ct)
    {
        string code = (request.Code ?? "").Trim();
        string name = (request.Name ?? "").Trim();
        if (!ValidCode(code, 24) || name.Length is < 1 or > 100 ||
            (request.Symbol?.Length ?? 0) > 24)
            return BadRequest(new { message = "Don vi tinh khong hop le." });

        const string sql = @"
            INSERT dbo.DON_VI_TINH(ma, ten, ky_hieu, cho_so_le)
            OUTPUT INSERTED.id
            VALUES (@code, @name, @symbol, @decimal);";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@code", SqlDbType.VarChar, 24).Value = code;
            cmd.Parameters.Add("@name", SqlDbType.NVarChar, 100).Value = name;
            cmd.Parameters.Add("@symbol", SqlDbType.NVarChar, 24).Value =
                (object?)request.Symbol ?? DBNull.Value;
            cmd.Parameters.Add("@decimal", SqlDbType.Bit).Value = request.AllowDecimal;
            long id = Convert.ToInt64(await cmd.ExecuteScalarAsync(ct));
            return Created("/api/catalogs/units", new { id });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }

    // 4. PUT /api/catalogs/units/3
    // Khong doi cho_so_le de khong lam sai so luong chung tu cu.
    [HttpPut("units/{id:long}")]
    [HasPermission("DANH_MUC.sua")]
    public async Task<IActionResult> UpdateUnit(
        long id, [FromBody] UpdateUnitRequest request, CancellationToken ct)
    {
        string name = (request.Name ?? "").Trim();
        byte[]? version = ParseRowVersion(request.RowVersion);
        if (id <= 0 || version is null || name.Length is < 1 or > 100 ||
            (request.Symbol?.Length ?? 0) > 24)
            return BadRequest(new { message = "Ten hoac rowVersion khong hop le." });

        const string sql = @"
            UPDATE dbo.DON_VI_TINH
            SET ten = @name, ky_hieu = @symbol, updated_at = SYSUTCDATETIME()
            OUTPUT INSERTED.row_version
            WHERE id = @id AND row_version = @version;";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@id", SqlDbType.BigInt).Value = id;
            cmd.Parameters.Add("@version", SqlDbType.Binary, 8).Value = version;
            cmd.Parameters.Add("@name", SqlDbType.NVarChar, 100).Value = name;
            cmd.Parameters.Add("@symbol", SqlDbType.NVarChar, 24).Value =
                (object?)request.Symbol ?? DBNull.Value;
            object? result = await cmd.ExecuteScalarAsync(ct);
            return result is byte[] updated
                ? Ok(new { id, rowVersion = Convert.ToBase64String(updated) })
                : Conflict(new { message = "Khong tim thay hoac don vi da bi nguoi khac sua." });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }

    // 5. POST /api/catalogs/products/1/conversions
    // Chi them moi; khong cho sua he so sau khi phat sinh giao dich.
    [HttpPost("products/{productId:long}/conversions")]
    [HasPermission("DANH_MUC.tao")]
    public async Task<IActionResult> CreateConversion(
        long productId, [FromBody] CreateConversionRequest request, CancellationToken ct)
    {
        if (productId <= 0 || request.UnitId <= 0 || request.Factor <= 0 ||
            request.Factor > 999999999999m ||
            decimal.Round(request.Factor, 6) != request.Factor)
            return BadRequest(new { message = "ID hoac he so quy doi khong hop le." });

        const string sql = @"
            INSERT dbo.QUY_DOI_DON_VI(san_pham_id, don_vi_id, he_so_sang_co_so)
            OUTPUT INSERTED.id
            SELECT sp.id, d.id, @factor
            FROM dbo.SAN_PHAM sp
            CROSS JOIN dbo.DON_VI_TINH d
            WHERE sp.id = @productId AND sp.trang_thai = 'ACTIVE'
              AND d.id = @unitId AND d.trang_thai = 'ACTIVE'
              AND (sp.don_vi_co_so_id <> d.id OR @factor = 1);";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@productId", SqlDbType.BigInt).Value = productId;
            cmd.Parameters.Add("@unitId", SqlDbType.BigInt).Value = request.UnitId;
            var factor = cmd.Parameters.Add("@factor", SqlDbType.Decimal);
            factor.Precision = 18;
            factor.Scale = 6;
            factor.Value = request.Factor;
            object? result = await cmd.ExecuteScalarAsync(ct);
            return result is null
                ? BadRequest(new { message = "San pham/don vi khong hoat dong; don vi co so phai co he so 1." })
                : Created($"/api/catalogs/products/{productId}/conversions",
                    new { id = Convert.ToInt64(result), productId });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }

    // 6. POST /api/catalogs/barcodes (chi gan cho san pham)
    [HttpPost("barcodes")]
    [HasPermission("MA_VACH.gan")]
    public async Task<IActionResult> CreateProductBarcode(
        [FromBody] CreateProductBarcodeRequest request, CancellationToken ct)
    {
        string code = (request.Code ?? "").Trim();
        string type = (request.Type ?? "").Trim().ToUpperInvariant();
        if (code.Length is < 1 or > 160 ||
            (type != "BARCODE" && type != "QR") ||
            request.ProductId <= 0 || request.UnitId is <= 0)
            return BadRequest(new { message = "Thong tin ma vach khong hop le." });

        const string sql = @"
            INSERT dbo.MA_VACH(ma, loai_ma, san_pham_id, don_vi_id)
            OUTPUT INSERTED.id
            SELECT @code, @type, sp.id, @unitId
            FROM dbo.SAN_PHAM sp
            WHERE sp.id = @productId AND sp.trang_thai = 'ACTIVE'
              AND (
                  @unitId IS NULL
                  OR EXISTS (
                      SELECT 1 FROM dbo.DON_VI_TINH d
                      WHERE d.id = @unitId AND d.trang_thai = 'ACTIVE'
                        AND (
                            d.id = sp.don_vi_co_so_id
                            OR EXISTS (
                                SELECT 1 FROM dbo.QUY_DOI_DON_VI q
                                WHERE q.san_pham_id = sp.id
                                  AND q.don_vi_id = d.id
                                  AND q.trang_thai = 'ACTIVE'
                            )
                        )
                  )
              );";
        try
        {
            await using var conn = new SqlConnection(GetConnectionString());
            await conn.OpenAsync(ct);
            await using var cmd = new SqlCommand(sql, conn);
            cmd.Parameters.Add("@code", SqlDbType.VarChar, 160).Value = code;
            cmd.Parameters.Add("@type", SqlDbType.VarChar, 12).Value = type;
            cmd.Parameters.Add("@productId", SqlDbType.BigInt).Value = request.ProductId;
            cmd.Parameters.Add("@unitId", SqlDbType.BigInt).Value =
                (object?)request.UnitId ?? DBNull.Value;
            object? result = await cmd.ExecuteScalarAsync(ct);
            return result is null
                ? BadRequest(new { message = "San pham/ quy cach khong hop le hoac khong hoat dong." })
                : Created("/api/catalogs/barcodes", new { id = Convert.ToInt64(result) });
        }
        catch (SqlException ex) { return SqlProblem(ex); }
    }
}
