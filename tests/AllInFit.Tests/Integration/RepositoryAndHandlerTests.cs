using AllInFit.Application.Queries.Users;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Domain.Entities.Identity;
using AllInFit.Persistence.Data;
using AllInFit.Persistence.Repositories;
using AllInFit.Shared.Result;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AllInFit.Tests.Integration;

public sealed class RepositoryAndHandlerTests : IClassFixture<TestDatabaseFixture>
{
    private readonly TestDatabaseFixture _fixture;

    public RepositoryAndHandlerTests(TestDatabaseFixture fixture) => _fixture = fixture;

    [Fact]
    public async Task GenericRepository_ReturnsStoredGymById()
    {
        await _fixture.ResetAsync(context =>
        {
            var owner = TestSeed.CreateUser();
            context.Users.Add(owner);
            context.Gyms.Add(TestSeed.CreateGym(owner.Id));
        });

        await using var context = _fixture.CreateContext();
        var repo = new GenericRepository<Gym>(context);
        var gym = await context.Gyms.AsNoTracking().FirstAsync();

        var fetched = await repo.GetByIdAsync(gym.Id);

        Assert.NotNull(fetched);
        Assert.Equal(gym.Id, fetched!.Id);
        Assert.Equal(gym.Name, fetched.Name);
    }

    [Fact]
    public async Task SoftDeleteFilter_HidesDeletedEntities()
    {
        await _fixture.ResetAsync(context =>
        {
            var owner = TestSeed.CreateUser("owner@example.com");
            context.Users.Add(owner);

            var gym = TestSeed.CreateGym(owner.Id, "Hidden Gym");
            gym.IsDeleted = true;
            context.Gyms.Add(gym);
        });

        await using var context = _fixture.CreateContext();
        var repo = new GenericRepository<Gym>(context);

        var gyms = await repo.GetAllAsync();

        Assert.Empty(gyms);
    }

    [Fact]
    public async Task GetCurrentUserQuery_ReturnsUserProfile()
    {
        User user = TestSeed.CreateUser();

        await _fixture.ResetAsync(context =>
        {
            context.Users.Add(user);
        });

        await using var context = _fixture.CreateContext();
        var unitOfWork = new TestUnitOfWork(context);
        var handler = new GetCurrentUserQueryHandler(unitOfWork);

        var result = await handler.Handle(new GetCurrentUserQuery(user.Id), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(user.Email, result.Value.Email);
        Assert.Equal(user.FirstName, result.Value.FirstName);
    }

    [Fact]
    public async Task GetCurrentUserQuery_EmptyId_ReturnsUnauthorized()
    {
        await using var context = _fixture.CreateContext();
        var unitOfWork = new TestUnitOfWork(context);
        var handler = new GetCurrentUserQueryHandler(unitOfWork);

        var result = await handler.Handle(new GetCurrentUserQuery(Guid.Empty), CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(ErrorType.Unauthorized, result.Error.Type);
    }
}