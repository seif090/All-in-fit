using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Queries.Gyms;

public sealed class GetGymQueryHandler : IRequestHandler<GetGymQuery, Result<GymDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    public GetGymQueryHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<GymDto>> Handle(GetGymQuery request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure<GymDto>(new Error("Gym.NotFound", "Gym not found"));
        return Result.Success(new GymDto(gym.Id, gym.Name, gym.LegalName, gym.LogoUrl, gym.Description, gym.IsVerified, gym.IsActive, gym.Rating, gym.ReviewCount));
    }
}