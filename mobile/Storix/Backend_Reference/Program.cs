
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Storix.Api.Security;
using Microsoft.AspNetCore.Authorization;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();
builder.Services.AddOpenApi();

// CORS chỉ cần khi giao diện web ở origin KHÁC với API.
// Khi frontend cùng chạy tại https://storixapi.duckdns.org, trình duyệt không cần CORS.
// Cấu hình origin qua biến môi trường Cors__AllowedOrigins__0 (KHÔNG dùng *).
var allowedWebOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? Array.Empty<string>();

builder.Services.AddCors(options => options.AddPolicy("StorixWeb", policy =>
{
    if (allowedWebOrigins.Length > 0)
        policy.WithOrigins(allowedWebOrigins).AllowAnyHeader().AllowAnyMethod();
}));


// JWT configuration
string issuer = builder.Configuration["Jwt:Issuer"]
    ?? throw new InvalidOperationException("Missing Jwt:Issuer");

string audience = builder.Configuration["Jwt:Audience"]
    ?? throw new InvalidOperationException("Missing Jwt:Audience");

string key = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Missing Jwt:Key");

byte[] keyBytes;

try
{
    keyBytes = Convert.FromBase64String(key);
}
catch (FormatException ex)
{
    throw new InvalidOperationException(
        "Jwt:Key must be Base64 encoded.", ex);
}

if (keyBytes.Length < 32)
{
    throw new InvalidOperationException(
        "JWT key must be at least 32 bytes.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters =
            new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = issuer,

                ValidateAudience = true,
                ValidAudience = audience,

                ValidateLifetime = true,

                ValidateIssuerSigningKey = true,
                IssuerSigningKey =
                    new SymmetricSecurityKey(keyBytes),

                ClockSkew = TimeSpan.FromSeconds(30)
                
            };
            options.Events = new JwtBearerEvents
            {
                OnTokenValidated = JwtAccountValidator.ValidateAsync
            };
    });

builder.Services.AddAuthorization();
builder.Services.AddSingleton<
    IAuthorizationPolicyProvider,
    PermissionPolicyProvider>();

builder.Services.AddScoped<
    IAuthorizationHandler,
    PermissionAuthorizationHandler>();

var app = builder.Build();

// Preflight CORS cần đi trước HTTPS redirection trong cấu hình host tách domain.
app.UseCors("StorixWeb");

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
else
{
    app.UseHttpsRedirection();
}

// Authentication phải đứng trước Authorization
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
