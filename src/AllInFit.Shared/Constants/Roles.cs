namespace AllInFit.Shared.Constants;

public static class Roles
{
    public const string SuperAdmin = "SuperAdmin";
    public const string Admin = "Admin";
    public const string User = "User";
    public const string GymOwner = "GymOwner";
    public const string Trainer = "Trainer";
    public const string Doctor = "Doctor";
    public const string Nutritionist = "Nutritionist";
    public const string RestaurantOwner = "RestaurantOwner";
    public const string PharmacyOwner = "PharmacyOwner";
    public const string SupplementSeller = "SupplementSeller";
    public const string Moderator = "Moderator";
    public const string SupportAgent = "SupportAgent";

    public static readonly string[] All = new[]
    {
        SuperAdmin, Admin, User, GymOwner, Trainer, Doctor, Nutritionist,
        RestaurantOwner, PharmacyOwner, SupplementSeller, Moderator, SupportAgent
    };
}
