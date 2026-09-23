using CoopSol.Infrastructure.HealthChecks;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Default")
                       ?? throw new InvalidOperationException(
                           "Falta la connection string 'Default'. Configúrala con " +
                           "'dotnet user-secrets set \"ConnectionStrings:Default\" \"...\"' en desarrollo, " +
                           "o con la variable de entorno ConnectionStrings__Default en producción.");

builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" })
    .AddTypeActivatedCheck<PostgresHealthCheck>(
        "postgresql",
        failureStatus:null,
        tags: new[] { "ready" },
        args: new object[] { connectionString });

var app = builder.Build();

app.MapGet("/", () => "CoopSol API");

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.Run();