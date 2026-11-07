
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace Storix.Api.Controllers;

[ApiController]
[Route("api/health/database")]
public class DatabaseHealthController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly IWebHostEnvironment _env;

    public DatabaseHealthController(
        IConfiguration config,
        IWebHostEnvironment env)
    {
        _config = config;
        _env = env;
    }

    [HttpGet]
    public async Task<IActionResult> Check()
    {
        if (!_env.IsDevelopment())
            return NotFound();

        var connectionString =
            _config.GetConnectionString("StorixDb");

        if (string.IsNullOrEmpty(connectionString))
        {
            return StatusCode(500, new
            {
                status = "missing_connection_string"
            });
        }

        try
        {
            await using var conn =
                new SqlConnection(connectionString);

            await conn.OpenAsync();

            await using var cmd =
                new SqlCommand("SELECT DB_NAME()", conn);

            var database = Convert.ToString(
                await cmd.ExecuteScalarAsync()
            );

            return Ok(new
            {
                status = database == "StorixDB"
                    ? "connected"
                    : "wrong_database",
                database
            });
        }
        catch (SqlException ex)
        {
            return StatusCode(503, new
            {
                status = "connection_failed",
                sqlErrorNumber = ex.Number
            });
        }
    }
}
