
using System.ComponentModel.DataAnnotations;
using System.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;

namespace Storix.Api.Controllers;

public class LoginRequest
{
    [Required]
    [MaxLength(80)]
    public string Username { get; set; } = "";

    [Required]
    public string Password { get; set; } = "";
}

public class ChangePasswordRequest
{
    [Required]
    public string CurrentPassword { get; set; } = "";

    [Required]
    [MinLength(14)]
    [MaxLength(128)]
    public string NewPassword { get; set; } = "";
}


[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly PasswordHasher<object> _hasher = new();

    public AuthController(IConfiguration config)
    {
        _config = config;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        string username = request.Username.Trim();

        if (string.IsNullOrEmpty(username) ||
            string.IsNullOrEmpty(request.Password))
        {
            return Unauthorized(new
            {
                message = "Sai tên đăng nhập hoặc mật khẩu"
            });
        }

        // Kết nối SQL Server
        string? connectionString =
            _config.GetConnectionString("StorixDb");

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return StatusCode(500, new
            {
                message = "Chưa cấu hình SQL Server"
            });
        }

        await using var connection =
            new SqlConnection(connectionString);

        await connection.OpenAsync(cancellationToken);

        // Lấy tài khoản từ database StorixDB
        const string sql = @"
            SELECT
                nd.id,
                nd.ten_dang_nhap,
                nd.mat_khau_bam,
                nd.ho_ten,
                nd.trang_thai,
                nd.bat_buoc_doi_mat_khau,
                nd.khoa_den,
                nd.auth_version,
                vt.ma_vai_tro,
                vt.trang_thai AS trang_thai_vai_tro
            FROM dbo.NGUOI_DUNG nd
            INNER JOIN dbo.VAI_TRO vt
                ON nd.vai_tro_id = vt.id
            WHERE nd.ten_dang_nhap = @username;
        ";

        await using var command =
            new SqlCommand(sql, connection);

        command.Parameters.Add(
            "@username",
            SqlDbType.VarChar,
            80
        ).Value = username;

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return Unauthorized(new
            {
                message = "Sai tên đăng nhập hoặc mật khẩu"
            });
        }

        long userId = reader.GetInt64(0);
        string loginName = reader.GetString(1);
        string passwordHash = reader.GetString(2);
        string fullName = reader.GetString(3);
        string status = reader.GetString(4);
        bool mustChangePassword = reader.GetBoolean(5);

        DateTime? lockedUntil = reader.IsDBNull(6)
            ? null
            : reader.GetDateTime(6);

        int authVersion = reader.GetInt32(7);
        string role = reader.GetString(8);
        string roleStatus = reader.GetString(9);

        // Kiểm tra tài khoản và vai trò
        if (status != "ACTIVE" || roleStatus != "ACTIVE" ||
            (lockedUntil.HasValue &&
             lockedUntil.Value > DateTime.UtcNow))
        {
            return Unauthorized(new
            {
                message = "Không thể đăng nhập tài khoản này"
            });
        }

        // Xác minh mật khẩu băm ASP.NET Core Identity
        PasswordVerificationResult verification;

        try
        {
            verification = _hasher.VerifyHashedPassword(
                new object(),
                passwordHash,
                request.Password
            );
        }
        catch (FormatException)
        {
            verification = PasswordVerificationResult.Failed;
        }
        catch (ArgumentException)
        {
            verification = PasswordVerificationResult.Failed;
        }

        if (verification == PasswordVerificationResult.Failed)
        {
            return Unauthorized(new
            {
                message = "Sai tên đăng nhập hoặc mật khẩu"
            });
        }

        // Tạo JWT
        string issuer = _config["Jwt:Issuer"]!;
        string audience = _config["Jwt:Audience"]!;
        string key = _config["Jwt:Key"]!;

        var signingKey = new SymmetricSecurityKey(
            Convert.FromBase64String(key)
        );

        var credentials = new SigningCredentials(
            signingKey,
            SecurityAlgorithms.HmacSha256
        );

        var now = DateTime.UtcNow;
        var expires = now.AddMinutes(15);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(JwtRegisteredClaimNames.Jti,
                Guid.NewGuid().ToString("N")),
            new(ClaimTypes.Name, loginName),
            new(ClaimTypes.Role, role),
            new("auth_version", authVersion.ToString()),
            new("pwd_change_required",
                mustChangePassword ? "true" : "false")
        };

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            notBefore: now,
            expires: expires,
            signingCredentials: credentials
        );

        string jwt = new JwtSecurityTokenHandler()
            .WriteToken(token);

        return Ok(new
        {
            accessToken = jwt,
            tokenType = "Bearer",
            expiresInSeconds = 900,
            mustChangePassword,
            user = new
            {
                id = userId,
                username = loginName,
                fullName,
                role
            }
        });
    }
    
[Authorize]
[HttpGet("me")]
public async Task<IActionResult> Me(
    CancellationToken cancellationToken)
{
    string? idText =
        User.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

    string? versionText =
        User.FindFirst("auth_version")?.Value;

    if (!long.TryParse(idText, out long userId) ||
        !int.TryParse(versionText, out int tokenVersion))
    {
        return Unauthorized();
    }

    string? connectionString =
        _config.GetConnectionString("StorixDb");

    if (string.IsNullOrWhiteSpace(connectionString))
        return StatusCode(503);

    const string sql = @"
        SELECT
            nd.ten_dang_nhap,
            nd.ho_ten,
            nd.trang_thai,
            nd.bat_buoc_doi_mat_khau,
            nd.auth_version,
            vt.ma_vai_tro,
            vt.trang_thai
        FROM dbo.NGUOI_DUNG nd
        JOIN dbo.VAI_TRO vt
            ON nd.vai_tro_id = vt.id
        WHERE nd.id = @id;
    ";

    try
    {
        await using var conn =
            new SqlConnection(connectionString);

        await conn.OpenAsync(cancellationToken);

        await using var cmd = new SqlCommand(sql, conn);

        cmd.Parameters.Add("@id", SqlDbType.BigInt)
            .Value = userId;

        await using var reader =
            await cmd.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
            return Unauthorized();

        string username = reader.GetString(0);
        string fullName = reader.GetString(1);
        string status = reader.GetString(2);
        bool mustChangePassword = reader.GetBoolean(3);
        int databaseVersion = reader.GetInt32(4);
        string role = reader.GetString(5);
        string roleStatus = reader.GetString(6);

        if (status != "ACTIVE" ||
            roleStatus != "ACTIVE" ||
            databaseVersion != tokenVersion)
        {
            return Unauthorized();
        }

        return Ok(new
        {
            id = userId,
            username,
            fullName,
            role,
            mustChangePassword
        });
    }
    catch (SqlException)
    {
        return StatusCode(503, new
        {
            message = "Không thể truy cập database"
        });
    }
}

[Authorize]
[HttpPost("change-password")]
public async Task<IActionResult> ChangePassword(
    [FromBody] ChangePasswordRequest request,
    CancellationToken cancellationToken)
{
    string? idText =
        User.FindFirst(ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

    string? versionText =
        User.FindFirst("auth_version")?.Value;

    if (!long.TryParse(idText, out long userId) ||
        !int.TryParse(versionText, out int tokenVersion))
    {
        return Unauthorized();
    }

    if (request.CurrentPassword == request.NewPassword)
    {
        return BadRequest(new
        {
            message = "Mat khau moi phai khac mat khau cu."
        });
    }

    string? connectionString =
        _config.GetConnectionString("StorixDb");

    if (string.IsNullOrWhiteSpace(connectionString))
        return StatusCode(503);

    await using var conn = new SqlConnection(connectionString);
    await conn.OpenAsync(cancellationToken);

    const string selectSql = @"
        SELECT
            nd.mat_khau_bam,
            nd.auth_version,
            nd.trang_thai,
            nd.khoa_den,
            vt.trang_thai
        FROM dbo.NGUOI_DUNG nd
        JOIN dbo.VAI_TRO vt
            ON vt.id = nd.vai_tro_id
        WHERE nd.id = @id;
    ";

    string oldHash;

    await using (var cmd = new SqlCommand(selectSql, conn))
    {
        cmd.Parameters.Add("@id", SqlDbType.BigInt).Value = userId;

        await using var reader =
            await cmd.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
            return Unauthorized();

        oldHash = reader.GetString(0);
        int dbVersion = reader.GetInt32(1);
        string status = reader.GetString(2);

        DateTime? lockedUntil = reader.IsDBNull(3)
            ? null
            : reader.GetDateTime(3);

        string roleStatus = reader.GetString(4);

        if (dbVersion != tokenVersion ||
            status != "ACTIVE" ||
            roleStatus != "ACTIVE" ||
            (lockedUntil.HasValue &&
             lockedUntil.Value > DateTime.UtcNow))
        {
            return Unauthorized();
        }
    }

    PasswordVerificationResult verification;

    try
    {
        verification = _hasher.VerifyHashedPassword(
            new object(),
            oldHash,
            request.CurrentPassword
        );
    }
    catch (FormatException)
    {
        verification = PasswordVerificationResult.Failed;
    }
    catch (ArgumentException)
    {
        verification = PasswordVerificationResult.Failed;
    }

    if (verification == PasswordVerificationResult.Failed)
    {
        return BadRequest(new
        {
            message = "Mat khau hien tai khong dung."
        });
    }

    string newHash = _hasher.HashPassword(
        new object(),
        request.NewPassword
    );

    const string updateSql = @"
        UPDATE nd
        SET
            mat_khau_bam = @newHash,
            bat_buoc_doi_mat_khau = 0,
            auth_version = auth_version + 1,
            updated_at = SYSUTCDATETIME()
        FROM dbo.NGUOI_DUNG nd
        JOIN dbo.VAI_TRO vt
            ON vt.id = nd.vai_tro_id
        WHERE nd.id = @id
          AND nd.mat_khau_bam = @oldHash
          AND nd.auth_version = @version
          AND nd.trang_thai = 'ACTIVE'
          AND vt.trang_thai = 'ACTIVE'
          AND (
              nd.khoa_den IS NULL
              OR nd.khoa_den <= SYSUTCDATETIME()
          );
    ";

    await using var updateCmd =
        new SqlCommand(updateSql, conn);

    updateCmd.Parameters.Add("@id", SqlDbType.BigInt)
        .Value = userId;

    updateCmd.Parameters.Add("@oldHash", SqlDbType.VarChar, 255)
        .Value = oldHash;

    updateCmd.Parameters.Add("@newHash", SqlDbType.VarChar, 255)
        .Value = newHash;

    updateCmd.Parameters.Add("@version", SqlDbType.Int)
        .Value = tokenVersion;

    int affected = await updateCmd.ExecuteNonQueryAsync(
        cancellationToken
    );

    if (affected != 1)
    {
        return Unauthorized(new
        {
            message = "Phien dang nhap da thay doi. Vui long dang nhap lai."
        });
    }

    return Ok(new
    {
        message = "Doi mat khau thanh cong.",
        mustChangePassword = false,
        loginAgain = true
    });
}

}


