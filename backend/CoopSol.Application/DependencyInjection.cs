using CoopSol.Application.Auth;
using Microsoft.Extensions.DependencyInjection;

namespace CoopSol.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<AuthService>();
        return services;
    }
}