using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class UserSessionsByUserSpecification : BaseSpecification<UserSession>
{
    public UserSessionsByUserSpecification(Guid userId)
        : base(session => session.UserId == userId)
    {
        ApplyOrderByDescending(session => session.StartedAt);
    }
}

public sealed class UserSessionsByUserAndDeviceSpecification : BaseSpecification<UserSession>
{
    public UserSessionsByUserAndDeviceSpecification(Guid userId, string deviceId)
        : base(session => session.UserId == userId && session.DeviceId == deviceId)
    {
        ApplyOrderByDescending(session => session.StartedAt);
    }
}

public sealed class UserDevicesByUserSpecification : BaseSpecification<UserDevice>
{
    public UserDevicesByUserSpecification(Guid userId)
        : base(device => device.UserId == userId)
    {
        ApplyOrderByDescending(device => device.LastUsedAt);
    }
}

public sealed class UserDevicesByUserAndDeviceSpecification : BaseSpecification<UserDevice>
{
    public UserDevicesByUserAndDeviceSpecification(Guid userId, string deviceId)
        : base(device => device.UserId == userId && device.DeviceId == deviceId)
    {
        ApplyOrderByDescending(device => device.LastUsedAt);
    }
}

public sealed class RefreshTokensByUserSpecification : BaseSpecification<RefreshToken>
{
    public RefreshTokensByUserSpecification(Guid userId)
        : base(token => token.UserId == userId)
    {
    }
}

public sealed class RefreshTokensByUserAndDeviceSpecification : BaseSpecification<RefreshToken>
{
    public RefreshTokensByUserAndDeviceSpecification(Guid userId, string deviceId)
        : base(token => token.UserId == userId && token.DeviceId == deviceId)
    {
    }
}