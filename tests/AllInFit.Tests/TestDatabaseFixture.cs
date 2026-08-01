using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Persistence.Data;
using AllInFit.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.Sqlite;
using Xunit;

namespace AllInFit.Tests;

public sealed class TestDatabaseFixture : IAsyncLifetime
{
    private SqliteConnection _connection = null!;

    public DbContextOptions<ApplicationDbContext> Options { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        _connection = new SqliteConnection("Data Source=:memory:");
        await _connection.OpenAsync();

        Options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlite(_connection)
            .EnableSensitiveDataLogging()
            .Options;

        await using var context = new ApplicationDbContext(Options);
        await context.Database.EnsureCreatedAsync();
    }

    public async Task DisposeAsync()
    {
        await _connection.DisposeAsync();
    }

    public ApplicationDbContext CreateContext() => new(Options);

    public async Task ResetAsync(Action<ApplicationDbContext> seed)
    {
        await using var context = CreateContext();
        await context.Database.EnsureDeletedAsync();
        await context.Database.EnsureCreatedAsync();
        seed(context);
        await context.SaveChangesAsync();
    }
}

public sealed class TestUnitOfWork : AllInFit.Application.Ports.IUnitOfWork
{
    private readonly ApplicationDbContext _context;

    public TestUnitOfWork(ApplicationDbContext context) => _context = context;

    public AllInFit.Application.Ports.IGenericRepository<T> Repository<T>() where T : class => new AllInFit.Persistence.Repositories.GenericRepository<T>(_context);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) => _context.SaveChangesAsync(cancellationToken);
    public Task BeginTransactionAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task CommitTransactionAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task RollbackTransactionAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public void Dispose() => _context.Dispose();
}

public static class TestSeed
{
    public static User CreateUser(string email = "user@example.com")
    {
        var user = new User(email, "Jane", "Doe", "hashed-password");
        user.UpdateProfile("Jane", "Doe", "+15551234567", null, null, AllInFit.Domain.Enums.Gender.Other);
        return user;
    }

    public static Gym CreateGym(Guid ownerUserId, string name = "Downtown Fitness")
        => new(name, "Downtown Fitness LLC", null, "Premium gym", "https://downtown.example.com", ownerUserId);
}