
using System.Data;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

public class ProductValues
{
    public string Code { get; set; } = "";
    public string Name { get; set; } = "";
    public long CategoryId { get; set; }
    public decimal PurchasePrice { get; set; }
    public decimal SellingPrice { get; set; }
    public bool TrackExpiry { get; set; }
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? WeightKg { get; set; }
    public decimal? VolumeM3 { get; set; }
}

public sealed class CreateProductRequest : ProductValues
{
    public long BaseUnitId { get; set; }
}

public sealed class UpdateProductRequest : ProductValues
{
    public string RowVersion { get; set; } = "";
}

public sealed class ProductStatusRequest
{
    public string Status { get; set; } = "";
    public string RowVersion { get; set; } = "";
}

[ApiController]
[Route("api/products")]
public sealed class ProductsWriteController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly ILogger<ProductsWriteController> _logger;

    public ProductsWriteController(
        IConfiguration config,
        ILogger<ProductsWriteController> logger)
    {
        _config = config;
        _logger = logger;
    }

    private static string? Validate(ProductValues p)
    {
        p.Code = p.Code?.Trim() ?? "";
        p.Name = p.Name?.Trim() ?? "";

        if (p.Code.Length == 0 || p.Code.Length > 50 ||
            !Regex.IsMatch(p.Code,
                @"^[A-Za-z0-9][A-Za-z0-9_.-]*$"))
            return "Ma san pham khong hop le.";

        if (p.Name.Length == 0 || p.Name.Length > 250)
            return "Ten san pham khong hop le.";

        if (p.CategoryId <= 0)
            return "CategoryId khong hop le.";

        if (p.PurchasePrice < 0 || p.SellingPrice < 0 ||
            p.PurchasePrice > 999999999999999m ||
            p.SellingPrice > 999999999999999m ||
            decimal.Round(p.PurchasePrice, 4) != p.PurchasePrice ||
            decimal.Round(p.SellingPrice, 4) != p.SellingPrice)
            return "Gia san pham khong hop le.";

        if (p.WeightKg.HasValue &&
            (p.WeightKg <= 0 ||
             p.WeightKg > 999999999999m ||
             decimal.Round(p.WeightKg.Value, 6) != p.WeightKg))
            return "Khoi luong khong hop le.";

        if (p.VolumeM3.HasValue &&
            (p.VolumeM3 <= 0 ||
             p.VolumeM3 > 999999999m ||
             decimal.Round(p.VolumeM3.Value, 9) != p.VolumeM3))
            return "The tich khong hop le.";

        if (p.Description?.Length > 1000 ||
            p.ImageUrl?.Length > 1024)
            return "Mo ta hoac duong dan anh qua dai.";

        return null;
    }

    private static void AddProductParameters(
        SqlCommand cmd, ProductValues p)
    {
        cmd.Parameters.Add("@code", SqlDbType.VarChar, 50)
            .Value = p.Code;

        cmd.Parameters.Add("@name", SqlDbType.NVarChar, 250)
            .Value = p.Name;

        cmd.Parameters.Add("@category", SqlDbType.BigInt)
            .Value = p.CategoryId;

        var purchase = cmd.Parameters.Add(
            "@purchase", SqlDbType.Decimal);
        purchase.Precision = 19;
        purchase.Scale = 4;
        purchase.Value = p.PurchasePrice;

        var selling = cmd.Parameters.Add(
            "@selling", SqlDbType.Decimal);
        selling.Precision = 19;
        selling.Scale = 4;
        selling.Value = p.SellingPrice;

        cmd.Parameters.Add("@expiry", SqlDbType.Bit)
            .Value = p.TrackExpiry;

        cmd.Parameters.Add("@description",
            SqlDbType.NVarChar, 1000)
            .Value = (object?)p.Description ?? DBNull.Value;

        cmd.Parameters.Add("@image",
            SqlDbType.NVarChar, 1024)
            .Value = (object?)p.ImageUrl ?? DBNull.Value;

        var weight = cmd.Parameters.Add(
            "@weight", SqlDbType.Decimal);
        weight.Precision = 18;
        weight.Scale = 6;
        weight.Value = (object?)p.WeightKg ?? DBNull.Value;

        var volume = cmd.Parameters.Add(
            "@volume", SqlDbType.Decimal);
        volume.Precision = 18;
        volume.Scale = 9;
        volume.Value = (object?)p.VolumeM3 ?? DBNull.Value;
    }

    private static byte[]? DecodeVersion(string? version)
    {
        try
        {
            var bytes = Convert.FromBase64String(version ?? "");
            return bytes.Length == 8 ? bytes : null;
        }
        catch (FormatException)
        {
            return null;
        }
    }

    private IActionResult SqlError(SqlException ex)
    {
        _logger.LogError(ex, "Product write failed");

        return ex.Number switch
        {
            2601 or 2627 => Conflict(new
            {
                message = "Ma san pham da ton tai."
            }),
            547 => BadRequest(new
            {
                message = "Du lieu tham chieu khong hop le."
            }),
            _ => StatusCode(503, new
            {
                message = "Khong the xu ly san pham."
            })
        };
    }

    // POST /api/products
    [HttpPost]
    [HasPermission("SAN_PHAM.tao")]
    public async Task<IActionResult> Create(
        [FromBody] CreateProductRequest request,
        CancellationToken ct)
    {
        string? error = Validate(request);
        if (error != null)
            return BadRequest(new { message = error });

        if (request.BaseUnitId <= 0)
            return BadRequest(new
            {
                message = "BaseUnitId khong hop le."
            });

        try
        {
            await using var conn = new SqlConnection(
                _config.GetConnectionString("StorixDb"));

            await conn.OpenAsync(ct);
            await using var tx =
                (SqlTransaction)await conn.BeginTransactionAsync(ct);

            const string validateSql = @"
                SELECT CASE WHEN
                    EXISTS (
                        SELECT 1 FROM dbo.LOAI_SAN_PHAM
                        WHERE id = @category
                          AND trang_thai = 'ACTIVE'
                    )
                    AND EXISTS (
                        SELECT 1 FROM dbo.DON_VI_TINH
                        WHERE id = @unit
                          AND trang_thai = 'ACTIVE'
                    )
                THEN 1 ELSE 0 END;
            ";

            await using (var check =
                new SqlCommand(validateSql, conn, tx))
            {
                check.Parameters.Add(
                    "@category", SqlDbType.BigInt
                ).Value = request.CategoryId;

                check.Parameters.Add(
                    "@unit", SqlDbType.BigInt
                ).Value = request.BaseUnitId;

                int valid = Convert.ToInt32(
                    await check.ExecuteScalarAsync(ct));

                if (valid != 1)
                    return BadRequest(new
                    {
                        message = "Loai hoac don vi co so khong hop le."
                    });
            }

            const string insertSql = @"
                INSERT dbo.SAN_PHAM (
                    ma, ten, loai_id, don_vi_co_so_id,
                    gia_nhap_tham_khao, gia_ban_hien_tai,
                    theo_doi_hsd, mo_ta, duong_dan_anh,
                    khoi_luong_1_dv_co_so_kg,
                    the_tich_1_dv_co_so_m3
                )
                OUTPUT INSERTED.id
                VALUES (
                    @code, @name, @category, @unit,
                    @purchase, @selling,
                    @expiry, @description, @image,
                    @weight, @volume
                );
            ";

            long newId;

            await using (var insert =
                new SqlCommand(insertSql, conn, tx))
            {
                AddProductParameters(insert, request);

                insert.Parameters.Add(
                    "@unit", SqlDbType.BigInt
                ).Value = request.BaseUnitId;

                newId = Convert.ToInt64(
                    await insert.ExecuteScalarAsync(ct));
            }

            const string conversionSql = @"
                INSERT dbo.QUY_DOI_DON_VI (
                    san_pham_id, don_vi_id, he_so_sang_co_so
                )
                VALUES (@product, @unit, 1);
            ";

            await using (var conversion =
                new SqlCommand(conversionSql, conn, tx))
            {
                conversion.Parameters.Add(
                    "@product", SqlDbType.BigInt
                ).Value = newId;

                conversion.Parameters.Add(
                    "@unit", SqlDbType.BigInt
                ).Value = request.BaseUnitId;

                await conversion.ExecuteNonQueryAsync(ct);
            }

            await tx.CommitAsync(ct);

            return Created($"/api/products/{newId}", new
            {
                id = newId,
                message = "Tao san pham thanh cong."
            });
        }
        catch (SqlException ex)
        {
            return SqlError(ex);
        }
    }

    // PUT /api/products/{id}
    [HttpPut("{id:long}")]
    [HasPermission("SAN_PHAM.sua")]
    public async Task<IActionResult> Update(
        long id,
        [FromBody] UpdateProductRequest request,
        CancellationToken ct)
    {
        string? error = Validate(request);
        if (error != null)
            return BadRequest(new { message = error });

        byte[]? version = DecodeVersion(request.RowVersion);

        if (id <= 0 || version == null)
            return BadRequest(new
            {
                message = "ID hoac rowVersion khong hop le."
            });

        const string sql = @"
            UPDATE dbo.SAN_PHAM
            SET ma = @code,
                ten = @name,
                loai_id = @category,
                gia_nhap_tham_khao = @purchase,
                gia_ban_hien_tai = @selling,
                theo_doi_hsd = @expiry,
                mo_ta = @description,
                duong_dan_anh = @image,
                khoi_luong_1_dv_co_so_kg = @weight,
                the_tich_1_dv_co_so_m3 = @volume,
                updated_at = SYSUTCDATETIME()
            OUTPUT INSERTED.row_version
            WHERE id = @id
              AND row_version = @version
              AND EXISTS (
                  SELECT 1 FROM dbo.LOAI_SAN_PHAM
                  WHERE id = @category
                    AND trang_thai = 'ACTIVE'
              );
        ";

        try
        {
            await using var conn = new SqlConnection(
                _config.GetConnectionString("StorixDb"));

            await conn.OpenAsync(ct);

            await using var cmd = new SqlCommand(sql, conn);
            AddProductParameters(cmd, request);

            cmd.Parameters.Add("@id", SqlDbType.BigInt)
                .Value = id;

            cmd.Parameters.Add("@version", SqlDbType.Binary, 8)
                .Value = version;

            object? result = await cmd.ExecuteScalarAsync(ct);

            if (result is not byte[] newVersion)
                return Conflict(new
                {
                    message = "San pham da thay doi, khong ton tai, " +
                              "hoac loai san pham khong con hoat dong."
                });

            return Ok(new
            {
                id,
                rowVersion = Convert.ToBase64String(newVersion),
                message = "Cap nhat san pham thanh cong."
            });
        }
        catch (SqlException ex)
        {
            return SqlError(ex);
        }
    }

    // PATCH /api/products/{id}/status
    [HttpPatch("{id:long}/status")]
    [HasPermission("SAN_PHAM.ngung")]
    public async Task<IActionResult> ChangeStatus(
        long id,
        [FromBody] ProductStatusRequest request,
        CancellationToken ct)
    {
        string status = request.Status?.Trim()
            .ToUpperInvariant() ?? "";

        byte[]? version = DecodeVersion(request.RowVersion);

        if (id <= 0 || version == null ||
            (status != "ACTIVE" && status != "INACTIVE"))
        {
            return BadRequest(new
            {
                message = "ID, trang thai hoac rowVersion khong hop le."
            });
        }

        const string sql = @"
            UPDATE dbo.SAN_PHAM
            SET trang_thai = @status,
                updated_at = SYSUTCDATETIME()
            OUTPUT INSERTED.row_version
            WHERE id = @id
              AND row_version = @version
              AND (
                  @status = 'INACTIVE'
                  OR EXISTS (
                      SELECT 1
                      FROM dbo.LOAI_SAN_PHAM l
                      JOIN dbo.DON_VI_TINH d
                        ON d.id = don_vi_co_so_id
                      WHERE l.id = loai_id
                        AND l.trang_thai = 'ACTIVE'
                        AND d.trang_thai = 'ACTIVE'
                  )
              );
        ";

        try
        {
            await using var conn = new SqlConnection(
                _config.GetConnectionString("StorixDb"));

            await conn.OpenAsync(ct);

            await using var cmd = new SqlCommand(sql, conn);

            cmd.Parameters.Add("@id", SqlDbType.BigInt)
                .Value = id;

            cmd.Parameters.Add("@status", SqlDbType.VarChar, 16)
                .Value = status;

            cmd.Parameters.Add("@version", SqlDbType.Binary, 8)
                .Value = version;

            object? result = await cmd.ExecuteScalarAsync(ct);

            if (result is not byte[] newVersion)
                return Conflict(new
                {
                    message = "Khong the doi trang thai. " +
                              "Hay tai lai san pham."
                });

            return Ok(new
            {
                id,
                status,
                rowVersion = Convert.ToBase64String(newVersion)
            });
        }
        catch (SqlException ex)
        {
            return SqlError(ex);
        }
    }
}
