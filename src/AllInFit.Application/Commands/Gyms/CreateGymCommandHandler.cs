using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Gyms;
using AllInFit.Shared.Result;
using MediatR;

namespace AllInFit.Application.Commands.Gyms;

public sealed class CreateGymCommandHandler : IRequestHandler<CreateGymCommand, Result<Guid>>
{
    private readonly IUnitOfWork _unitOfWork;

    public CreateGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result<Guid>> Handle(CreateGymCommand request, CancellationToken cancellationToken)
    {
        var gym = new Gym(request.Name, request.LegalName, request.LogoUrl, request.Description, request.Website, request.OwnerUserId);
        var repo = _unitOfWork.Repository<Gym>();
        await repo.AddAsync(gym, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success(gym.Id);
    }
}

public sealed class UpdateGymCommandHandler : IRequestHandler<UpdateGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    public UpdateGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result> Handle(UpdateGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure(new Error("Gym.NotFound", "Gym not found"));
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}

public sealed class DeleteGymCommandHandler : IRequestHandler<DeleteGymCommand, Result>
{
    private readonly IUnitOfWork _unitOfWork;
    public DeleteGymCommandHandler(IUnitOfWork unitOfWork) => _unitOfWork = unitOfWork;

    public async Task<Result> Handle(DeleteGymCommand request, CancellationToken cancellationToken)
    {
        var repo = _unitOfWork.Repository<Gym>();
        var gym = await repo.GetByIdAsync(request.GymId, cancellationToken);
        if (gym is null) return Result.Failure(new Error("Gym.NotFound", "Gym not found"));
        await repo.DeleteAsync(gym);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return Result.Success();
    }
}