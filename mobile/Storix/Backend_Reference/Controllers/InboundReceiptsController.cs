using System.Data;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Storix.Api.Security;

namespace Storix.Api.Controllers;

[ApiController]
[Route("api/inbound-receipts")]
public sealed class InboundReceiptsController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<InboundReceiptsController> _logger;

    public InboundReceiptsController(
        IConfiguration configuration,
        ILogger<InboundReceiptsController> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    private bool TryGetUserId(out long userId)
    {
        string? text = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;
        return long.TryParse(text, out userId) && userId > 0;
    }

    private string? ConnectionString =>
        _configuration.GetConnectionString("StorixDb");

    // GET /api/inbound-receipts?page=1&pageSize=20
    // Chỉ trả phiếu ở nơi lưu trữ đang được phân công.
    [HttpGet]
    [HasPermission("PHIEU_NHAP.xem")]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetUserId(out long userId)) return Unauthorized();
        if (page < 1 || pageSize < 1 || pageSize > 100)
            return BadRequest(new { message = "page hoac pageSize khong hop le." });
        if (string.IsNullOrWhiteSpace(ConnectionString)) return StatusCode(503);

        const string sql = @"
            SELECT COUNT_BIG(*)
            FROM dbo.PHIEU_NHAP p
            INNER JOIN dbo.CHUNG_TU c ON c.id = p.chung_tu_id
            WHERE c.loai_chung_tu = 'NHAP'
              AND EXISTS (
                  SELECT 1
                  FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.nguoi_dung_id = @userId
                    AND a.noi_luu_tru_id = p.noi_luu_tru_id
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
              );

            SELECT p.id, c.ma_chung_tu, c.trang_thai,
                   p.noi_luu_tru_id, n.ten,
                   p.nha_cung_cap_id, s.ten,
                   p.ngay_du_kien, c.created_at,
                   c.row_version
            FROM dbo.PHIEU_NHAP p
            INNER JOIN dbo.CHUNG_TU c ON c.id = p.chung_tu_id
            INNER JOIN dbo.NOI_LUU_TRU n ON n.id = p.noi_luu_tru_id
            INNER JOIN dbo.NHA_CUNG_CAP s ON s.id = p.nha_cung_cap_id
            WHERE c.loai_chung_tu = 'NHAP'
              AND EXISTS (
                  SELECT 1
                  FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.nguoi_dung_id = @userId
                    AND a.noi_luu_tru_id = p.noi_luu_tru_id
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
              )
            ORDER BY c.created_at DESC, p.id DESC
            OFFSET @offset ROWS FETCH NEXT @pageSize ROWS ONLY;
        ";

        try
        {
            await using var connection = new SqlConnection(ConnectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = new SqlCommand(sql, connection);
            command.Parameters.Add("@userId", SqlDbType.BigInt).Value = userId;
            command.Parameters.Add("@offset", SqlDbType.BigInt).Value = ((long)page - 1) * pageSize;
            command.Parameters.Add("@pageSize", SqlDbType.Int).Value = pageSize;

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                return StatusCode(503, new { message = "Khong doc duoc tong so phieu." });
            long total = reader.GetInt64(0);
            await reader.NextResultAsync(cancellationToken);

            var items = new List<object>();
            while (await reader.ReadAsync(cancellationToken))
            {
                items.Add(new
                {
                    id = reader.GetInt64(0),
                    code = reader.GetString(1),
                    status = reader.GetString(2),
                    warehouseId = reader.GetInt64(3),
                    warehouseName = reader.GetString(4),
                    supplierId = reader.GetInt64(5),
                    supplierName = reader.GetString(6),
                    expectedDate = reader.IsDBNull(7) ? (DateTime?)null : reader.GetDateTime(7),
                    createdAt = reader.GetDateTime(8),
                    rowVersion = Convert.ToBase64String(reader.GetFieldValue<byte[]>(9))
                });
            }
            return Ok(new { page, pageSize, total, items });
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Get inbound receipts failed");
            return StatusCode(503, new { message = "Khong the doc danh sach phieu nhap." });
        }
    }

    // GET /api/inbound-receipts/1
    [HttpGet("{id:long}")]
    [HasPermission("PHIEU_NHAP.xem")]
    public async Task<IActionResult> GetById(long id, CancellationToken cancellationToken)
    {
        if (id <= 0) return BadRequest(new { message = "ID khong hop le." });
        if (!TryGetUserId(out long userId)) return Unauthorized();
        if (string.IsNullOrWhiteSpace(ConnectionString)) return StatusCode(503);

        const string headerSql = @"
            SELECT p.id, p.chung_tu_id, c.ma_chung_tu, c.trang_thai,
                   p.noi_luu_tru_id, n.ten,
                   p.nha_cung_cap_id, s.ten,
                   p.ngay_du_kien, p.nguoi_nhan_id, p.received_at,
                   p.ghi_chu, c.created_at, c.row_version
            FROM dbo.PHIEU_NHAP p
            INNER JOIN dbo.CHUNG_TU c ON c.id = p.chung_tu_id
            INNER JOIN dbo.NOI_LUU_TRU n ON n.id = p.noi_luu_tru_id
            INNER JOIN dbo.NHA_CUNG_CAP s ON s.id = p.nha_cung_cap_id
            WHERE p.id = @id AND c.loai_chung_tu = 'NHAP'
              AND EXISTS (
                  SELECT 1 FROM dbo.NGUOI_DUNG_NOI_LUU_TRU a
                  WHERE a.nguoi_dung_id = @userId
                    AND a.noi_luu_tru_id = p.noi_luu_tru_id
                    AND a.trang_thai = 'ACTIVE'
                    AND a.tu_ngay <= SYSUTCDATETIME()
                    AND (a.den_ngay IS NULL OR a.den_ngay > SYSUTCDATETIME())
              );
        ";

        const string detailSql = @"
            SELECT c.id, c.so_dong, c.san_pham_id, sp.ma, sp.ten,
                   c.lo_id, l.ma_lo_noi_bo,
                   c.don_vi_giao_dich_id, c.he_so_quy_doi_chot,
                   c.sl_du_kien_giao_dich, c.sl_nhan_tot_co_so,
                   c.sl_nhan_hong_co_so, c.sl_tu_choi_co_so,
                   c.don_gia_nhap_giao_dich, c.ly_do_chenh_lech
            FROM dbo.CT_PHIEU_NHAP c
            INNER JOIN dbo.SAN_PHAM sp ON sp.id = c.san_pham_id
            LEFT JOIN dbo.LO_HANG l ON l.id = c.lo_id
            WHERE c.phieu_nhap_id = @id
            ORDER BY c.so_dong;

            SELECT b.id, b.ct_phieu_nhap_id, b.vi_tri_id,
                   v.ma, v.ten, b.tinh_trang, b.sl_phan_bo_co_so
            FROM dbo.PHAN_BO_NHAP b
            INNER JOIN dbo.CT_PHIEU_NHAP c ON c.id = b.ct_phieu_nhap_id
            INNER JOIN dbo.VI_TRI v ON v.id = b.vi_tri_id
            WHERE c.phieu_nhap_id = @id
            ORDER BY c.so_dong, b.id;
        ";

        try
        {
            await using var connection = new SqlConnection(ConnectionString);
            await connection.OpenAsync(cancellationToken);

            object? header;
            await using (var headerCmd = new SqlCommand(headerSql, connection))
            {
                headerCmd.Parameters.Add("@id", SqlDbType.BigInt).Value = id;
                headerCmd.Parameters.Add("@userId", SqlDbType.BigInt).Value = userId;
                await using var reader = await headerCmd.ExecuteReaderAsync(cancellationToken);
                if (!await reader.ReadAsync(cancellationToken))
                    return NotFound(new { message = "Khong tim thay phieu nhap duoc phep xem." });

                header = new
                {
                    id = reader.GetInt64(0),
                    documentId = reader.GetInt64(1),
                    code = reader.GetString(2),
                    status = reader.GetString(3),
                    warehouseId = reader.GetInt64(4),
                    warehouseName = reader.GetString(5),
                    supplierId = reader.GetInt64(6),
                    supplierName = reader.GetString(7),
                    expectedDate = reader.IsDBNull(8) ? (DateTime?)null : reader.GetDateTime(8),
                    receiverId = reader.IsDBNull(9) ? (long?)null : reader.GetInt64(9),
                    receivedAt = reader.IsDBNull(10) ? (DateTime?)null : reader.GetDateTime(10),
                    note = reader.IsDBNull(11) ? null : reader.GetString(11),
                    createdAt = reader.GetDateTime(12),
                    rowVersion = Convert.ToBase64String(reader.GetFieldValue<byte[]>(13))
                };
            }

            var lines = new List<object>();
            var allocations = new List<object>();
            await using (var detailCmd = new SqlCommand(detailSql, connection))
            {
                detailCmd.Parameters.Add("@id", SqlDbType.BigInt).Value = id;
                await using var reader = await detailCmd.ExecuteReaderAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    lines.Add(new
                    {
                        id = reader.GetInt64(0),
                        lineNumber = reader.GetInt32(1),
                        productId = reader.GetInt64(2),
                        productCode = reader.GetString(3),
                        productName = reader.GetString(4),
                        lotId = reader.IsDBNull(5) ? (long?)null : reader.GetInt64(5),
                        lotCode = reader.IsDBNull(6) ? null : reader.GetString(6),
                        transactionUnitId = reader.GetInt64(7),
                        lockedConversionFactor = reader.GetDecimal(8),
                        expectedTransactionQuantity = reader.GetDecimal(9),
                        receivedGoodBaseQuantity = reader.GetDecimal(10),
                        receivedDamagedBaseQuantity = reader.GetDecimal(11),
                        rejectedBaseQuantity = reader.GetDecimal(12),
                        transactionUnitCost = reader.GetDecimal(13),
                        discrepancyReason = reader.IsDBNull(14) ? null : reader.GetString(14)
                    });
                }
                await reader.NextResultAsync(cancellationToken);
                while (await reader.ReadAsync(cancellationToken))
                {
                    allocations.Add(new
                    {
                        id = reader.GetInt64(0),
                        receiptLineId = reader.GetInt64(1),
                        positionId = reader.GetInt64(2),
                        positionCode = reader.GetString(3),
                        positionName = reader.GetString(4),
                        condition = reader.GetString(5),
                        baseQuantity = reader.GetDecimal(6)
                    });
                }
            }

            return Ok(new { receipt = header, lines, allocations });
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Get inbound receipt {ReceiptId} failed", id);
            return StatusCode(503, new { message = "Khong the doc chi tiet phieu nhap." });
        }
    }

    // POST /api/inbound-receipts/1/complete
    // Chỉ gọi Stored Procedure: không viết UPDATE TON_KHO trong C#.
    [HttpPost("{id:long}/complete")]
    [HasPermission("PHIEU_NHAP.hoan_thanh")]
    public async Task<IActionResult> Complete(long id, CancellationToken cancellationToken)
    {
        if (id <= 0) return BadRequest(new { message = "ID khong hop le." });
        if (!TryGetUserId(out long userId)) return Unauthorized();
        if (string.IsNullOrWhiteSpace(ConnectionString)) return StatusCode(503);

        try
        {
            await using var connection = new SqlConnection(ConnectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = new SqlCommand(
                "dbo.usp_Storix_HoanThanhNhap", connection)
            {
                CommandType = CommandType.StoredProcedure,
                CommandTimeout = 60
            };
            command.Parameters.Add("@phieu_nhap_id", SqlDbType.BigInt).Value = id;
            // ID lấy từ JWT do server xác thực, KHÔNG lấy từ request body.
            command.Parameters.Add("@nguoi_thuc_hien_id", SqlDbType.BigInt).Value = userId;

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken))
                return StatusCode(503, new { message = "Stored Procedure khong tra ket qua." });

            return Ok(new
            {
                receiptId = reader.GetInt64(0),
                newlyPosted = reader.GetBoolean(1),
                message = reader.GetString(2)
            });
        }
        catch (SqlException ex) when (ex.Number == 56401)
        {
            return NotFound(new { message = "Khong tim thay phieu nhap." });
        }
        catch (SqlException ex) when (ex.Number >= 56402 && ex.Number <= 56499)
        {
            _logger.LogWarning(ex, "Inbound receipt {ReceiptId} rejected", id);
            return Conflict(new
            {
                message = "Phieu nhap khong dat dieu kien hoan thanh.",
                sqlErrorNumber = ex.Number
            });
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Complete inbound receipt {ReceiptId} failed", id);
            return StatusCode(503, new
            {
                message = "Khong the hoan thanh nhap hang.",
                sqlErrorNumber = ex.Number
            });
        }
    }
}
