using CoopSol.Application.Abstractions;
using CoopSol.Domain.Entities;
using CoopSol.Domain.Enums;
using CoopSol.Infrastructure.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace CoopSol.Tests.Integration;

[Collection(ApiCollection.Name)]
public class UniqueViolationTranslationTests(ApiFactory factory)
{
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static User NewUser(string email) =>
        User.Create(email, "hash:irrelevante", "Usuario de Prueba", UserRole.Socio, DateTime.UtcNow);

    [Fact]
    public async Task SaveChanges_DuplicateEmail_ThrowsUniqueConstraintViolation()
    {
        var email = $"{Guid.NewGuid():N}@coopsol.test";

        await using (var first = factory.Services.CreateAsyncScope())
        {
            var db = first.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Users.Add(NewUser(email));
            await db.SaveChangesAsync(Ct);
        }

        await using var second = factory.Services.CreateAsyncScope();
        var otherDb = second.ServiceProvider.GetRequiredService<AppDbContext>();
        otherDb.Users.Add(NewUser(email));

        await Assert.ThrowsAsync<UniqueConstraintViolationException>(() => otherDb.SaveChangesAsync(Ct));
    }
}