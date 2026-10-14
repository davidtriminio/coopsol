using CoopSol.Application.Abstractions;
using CoopSol.Domain.Entities;
using CoopSol.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace CoopSol.Infrastructure.Persistence;

public static class AdminSeeder
{
    public static async Task SeedAsync(IServiceProvider services, string email, string password,
        CancellationToken ct = default)
    {
        if(password.Length < 8)
            throw new InvalidOperationException("Seed:AdminPassword debe tener al menos 8 caracteres.");

        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher>();
        var clock = scope.ServiceProvider.GetRequiredService<TimeProvider>();

        if (await db.Users.AnyAsync(u => u.Role == UserRole.Admin, ct))
            return;

        var admin = User.Create(email, hasher.Hash(password), "Administrador", UserRole.Admin,
            clock.GetUtcNow().UtcDateTime);
        db.Users.Add(admin);
        await db.SaveChangesAsync(ct);
    }
}