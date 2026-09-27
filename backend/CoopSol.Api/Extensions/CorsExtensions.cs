namespace CoopSol.Api.Extensions;

public static class CorsServiceCollectionExtensions
{
    public const string WebCorsPolicy = "'web'";

    public static IServiceCollection AddWebCors(this IServiceCollection services, IConfiguration configuration)
    {
        var webOrigin = configuration["Cors:WebOrigin"];
        if (string.IsNullOrWhiteSpace(webOrigin) || !Uri.TryCreate(webOrigin, UriKind.Absolute, out _))
            throw new InvalidOperationException(
                "Falta 'Cors:WebOrigin' o no es una URL absoluta válida. Configúralo en appsettings.Development.json" +
                "(ej. \"http://localhost:4200\" o con la variable de entorno Cors__WebOrigin en producción.");

        services.AddCors(options =>
            options.AddPolicy(WebCorsPolicy, policy => policy
                .WithOrigins(webOrigin)
                .WithMethods("GET", "POST")
                .WithHeaders("Authorization", "Content-Type")
            ));
        return services;
    }
}