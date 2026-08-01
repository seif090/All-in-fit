using AllInFit.Domain.Entities.Identity;

namespace AllInFit.Domain.Specifications;

public sealed class UserByPhoneSpecification : BaseSpecification<User>
{
    public UserByPhoneSpecification(string phoneNumber)
        : base(u => u.PhoneNumber != null && u.PhoneNumber == phoneNumber && !u.IsDeleted)
    {
    }
}