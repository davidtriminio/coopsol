using Microsoft.Extensions.Diagnostics.HealthChecks;
using Npgsql;

namespace CoopSol.Infrastructure.HealthChecks;

/// <summary>
/// Verifica que PostgreSQL acepte conexiones reales (no solo que el proceso esté vivo).
/// Se usa en el endpoint de readiness, nunca en el de liveness.
/// </summary>

public sealed class PostgresHealthCheck : IHealthCheck
{
    private readonly string _connectionString;

    public PostgresHealthCheck(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var connection = new NpgsqlConnection(_connectionString);
            await connection.OpenAsync(cancellationToken);

            await using var command = connection.CreateCommand();
            command.CommandText = "SELECT 1";
            return HealthCheckResult.Healthy("PostgreSQL respondió correctamente.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("No se pudo conectar a PostgreSQL", ex);
        }
    }

}