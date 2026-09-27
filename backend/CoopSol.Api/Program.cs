using CoopSol.Api.Endpoints;
using CoopSol.Api.Extensions;
using CoopSol.Application;
using CoopSol.Infrastructure;
using CoopSol.Infrastructure.HealthChecks;
using CoopSol.Infrastructure.Persistence;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using CorsServiceCollectionExtensions = CoopSol.Api.Extensions.CorsServiceCollectionExtensions;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Default")
                       ?? throw new InvalidOperationException(
                           "Falta la connection string 'Default'. Configúrala con " +
                           "'dotnet user-secrets set \"ConnectionStrings:Default\" \"...\"' en desarrollo, " +
                           "o con la variable de entorno ConnectionStrings__Default en producción.");

builder.Services.AddApplication();
builder.Services.AddInfrastructure(connectionString);
builder.Services.AddJwtSettings(builder.Configuration);
builder.Services.AddJwtAuthentication();
builder.Services.AddAuthorization();
builder.Services.AddAuthRateLimiting(builder.Configuration);
builder.Services.AddWebCors(builder.Configuration);
builder.Services.AddProblemDetails();

builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new []{"live"})
    .AddTypeActivatedCheck<PostgresHealthCheck>(
    "postgresql",
    failureStatus: null,
    tags: new[] { "ready" },
    args: new object[] { connectionString }
);
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
}

var seedEmail = app.Configuration["Seed:AdminEmail"];
var seedPassword = app.Configuration["Seed:AdminPassword"];
if (!string.IsNullOrWhiteSpace(seedEmail) && !string.IsNullOrWhiteSpace(seedPassword))
{
    await AdminSeeder.SeedAsync(app.Services, seedEmail, seedPassword);
}

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors(CorsServiceCollectionExtensions.WebCorsPolicy);
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "CoopSol API");

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live"),
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
});

app.MapAuthEndpoints();
app.MapAdminUsersEndpoints();
app.Run();

public partial class Program;