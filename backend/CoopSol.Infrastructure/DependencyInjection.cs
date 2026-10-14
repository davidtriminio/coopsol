using CoopSol.Application.Abstractions;
using CoopSol.Infrastructure.Persistence;
using CoopSol.Infrastructure.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;
using CoopSol.Infrastructure.Security;
using Microsoft.Extensions.DependencyInjection;

namespace CoopSol.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, string connectionString)
    {
        services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<AppDbContext>());
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();

        services.AddSingleton(TimeProvider.System);
        services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();
        services.AddSingleton<ITokenService, JwtTokenService>();

        return services;
    }
}