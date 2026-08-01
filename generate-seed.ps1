$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Persistence\Seed"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

Write-File "$base\SeedData.cs" @'
using AllInFit.Domain.Entities.Identity;
using AllInFit.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace AllInFit.Persistence.Seed;

public static class SeedData
{
    public static async Task SeedAsync(ApplicationDbContext context)
    {
        // Ensure database is created
        await context.Database.EnsureCreatedAsync();

        // Seed Roles
        if (!await context.Roles.AnyAsync())
        {
            var roles = new List<Role>
            {
                new("SuperAdmin", "Full system access", "System"),
                new("Admin", "Administrative access", "System"),
                new("User", "Standard platform user", "System"),
                new("GymOwner", "Gym management access", "Gym"),
                new("Trainer", "Training professional", "Professional"),
                new("Doctor", "Medical professional", "Professional"),
                new("Nutritionist", "Nutrition professional", "Professional"),
                new("RestaurantOwner", "Restaurant management", "Business"),
                new("PharmacyOwner", "Pharmacy management", "Business"),
                new("SupplementSeller", "Supplement marketplace seller", "Business")
            };
            await context.Roles.AddRangeAsync(roles);
            await context.SaveChangesAsync();
        }

        // Seed Permissions
        if (!await context.Permissions.AnyAsync())
        {
            var permissions = new List<Permission>
            {
                // Auth
                new("Auth.Login", "Can login", "Auth"),
                new("Auth.Register", "Can register", "Auth"),
                new("Auth.RefreshToken", "Can refresh token", "Auth"),
                new("Auth.Logout", "Can logout", "Auth"),
                new("Auth.ManageSessions", "Can manage sessions", "Auth"),

                // Users
                new("Users.Read", "Can view users", "Users"),
                new("Users.Create", "Can create users", "Users"),
                new("Users.Update", "Can update users", "Users"),
                new("Users.Delete", "Can delete users", "Users"),
                new("Users.ManageRoles", "Can manage user roles", "Users"),

                // Gyms
                new("Gyms.Read", "Can view gyms", "Gyms"),
                new("Gyms.Create", "Can create gyms", "Gyms"),
                new("Gyms.Update", "Can update gyms", "Gyms"),
                new("Gyms.Delete", "Can delete gyms", "Gyms"),
                new("Gyms.ManageBranches", "Can manage branches", "Gyms"),
                new("Gyms.ManageMemberships", "Can manage memberships", "Gyms"),
                new("Gyms.ManageSchedules", "Can manage schedules", "Gyms"),

                // Trainers
                new("Trainers.Read", "Can view trainers", "Trainers"),
                new("Trainers.Create", "Can create trainers", "Trainers"),
                new("Trainers.Update", "Can update trainers", "Trainers"),
                new("Trainers.Delete", "Can delete trainers", "Trainers"),
                new("Trainers.ManageCertificates", "Can manage certificates", "Trainers"),
                new("Trainers.ManageAvailability", "Can manage availability", "Trainers"),

                // Doctors
                new("Doctors.Read", "Can view doctors", "Doctors"),
                new("Doctors.Create", "Can create doctors", "Doctors"),
                new("Doctors.Update", "Can update doctors", "Doctors"),
                new("Doctors.Delete", "Can delete doctors", "Doctors"),
                new("Doctors.ManageSpecialties", "Can manage specialties", "Doctors"),

                // Nutritionists
                new("Nutritionists.Read", "Can view nutritionists", "Nutritionists"),
                new("Nutritionists.Create", "Can create nutritionists", "Nutritionists"),
                new("Nutritionists.Update", "Can update nutritionists", "Nutritionists"),
                new("Nutritionists.Delete", "Can delete nutritionists", "Nutritionists"),

                // Workouts
                new("Workouts.Read", "Can view workout programs", "Workouts"),
                new("Workouts.Create", "Can create workout programs", "Workouts"),
                new("Workouts.Update", "Can update workout programs", "Workouts"),
                new("Workouts.Delete", "Can delete workout programs", "Workouts"),
                new("Workouts.ManageExercises", "Can manage exercises", "Workouts"),

                // Nutrition
                new("Nutrition.Read", "Can view meal plans", "Nutrition"),
                new("Nutrition.Create", "Can create meal plans", "Nutrition"),
                new("Nutrition.Update", "Can update meal plans", "Nutrition"),
                new("Nutrition.Delete", "Can delete meal plans", "Nutrition"),
                new("Nutrition.ManageRecipes", "Can manage recipes", "Nutrition"),

                // Marketplace
                new("Marketplace.Read", "Can view products", "Marketplace"),
                new("Marketplace.Create", "Can create products", "Marketplace"),
                new("Marketplace.Update", "Can update products", "Marketplace"),
                new("Marketplace.Delete", "Can delete products", "Marketplace"),
                new("Marketplace.ManageOrders", "Can manage orders", "Marketplace"),
                new("Marketplace.ManageCoupons", "Can manage coupons", "Marketplace"),
                new("Marketplace.ManageCart", "Can manage cart", "Marketplace"),

                // Appointments
                new("Appointments.Read", "Can view appointments", "Appointments"),
                new("Appointments.Create", "Can create appointments", "Appointments"),
                new("Appointments.Update", "Can update appointments", "Appointments"),
                new("Appointments.Cancel", "Can cancel appointments", "Appointments"),

                // Reviews
                new("Reviews.Read", "Can view reviews", "Reviews"),
                new("Reviews.Create", "Can create reviews", "Reviews"),
                new("Reviews.Update", "Can update reviews", "Reviews"),
                new("Reviews.Delete", "Can delete reviews", "Reviews"),
                new("Reviews.Approve", "Can approve reviews", "Reviews"),

                // Notifications
                new("Notifications.Read", "Can view notifications", "Notifications"),
                new("Notifications.Manage", "Can manage notifications", "Notifications"),
                new("Notifications.Send", "Can send notifications", "Notifications"),

                // Chat
                new("Chat.Read", "Can view chats", "Chat"),
                new("Chat.Send", "Can send messages", "Chat"),
                new("Chat.Manage", "Can manage chats", "Chat"),

                // Communities
                new("Communities.Read", "Can view communities", "Communities"),
                new("Communities.Create", "Can create communities", "Communities"),
                new("Communities.Update", "Can update communities", "Communities"),
                new("Communities.Delete", "Can delete communities", "Communities"),
                new("Communities.ManagePosts", "Can manage posts", "Communities"),
                new("Communities.ManageMembers", "Can manage members", "Communities"),

                // Gamification
                new("Challenges.Read", "Can view challenges", "Gamification"),
                new("Challenges.Create", "Can create challenges", "Gamification"),
                new("Challenges.Update", "Can update challenges", "Gamification"),
                new("Challenges.Delete", "Can delete challenges", "Gamification"),
                new("Leaderboard.Read", "Can view leaderboard", "Gamification"),
                new("Achievements.Read", "Can view achievements", "Gamification"),
                new("Badges.Read", "Can view badges", "Gamification"),

                // Wallet
                new("Wallet.Read", "Can view wallet", "Wallet"),
                new("Wallet.Deposit", "Can deposit funds", "Wallet"),
                new("Wallet.Withdraw", "Can withdraw funds", "Wallet"),
                new("Wallet.Transfer", "Can transfer funds", "Wallet"),

                // Referrals
                new("Referrals.Read", "Can view referrals", "Referrals"),
                new("Referrals.Create", "Can create referrals", "Referrals"),

                // CRM
                new("Crm.Read", "Can view CRM data", "CRM"),
                new("Crm.Update", "Can update CRM data", "CRM"),

                // CMS
                new("Cms.Read", "Can view CMS content", "CMS"),
                new("Cms.Create", "Can create CMS content", "CMS"),
                new("Cms.Update", "Can update CMS content", "CMS"),
                new("Cms.Delete", "Can delete CMS content", "CMS"),
                new("Cms.ManageSettings", "Can manage settings", "CMS"),

                // Analytics
                new("Analytics.Read", "Can view analytics", "Analytics"),
                new("Analytics.Export", "Can export analytics", "Analytics"),

                // Files
                new("Files.Read", "Can view files", "Files"),
                new("Files.Upload", "Can upload files", "Files"),
                new("Files.Delete", "Can delete files", "Files"),

                // Admin
                new("Admin.Dashboard", "Can view admin dashboard", "Admin"),
                new("Admin.ManageRoles", "Can manage roles", "Admin"),
                new("Admin.ManagePermissions", "Can manage permissions", "Admin"),
                new("Admin.AuditLogs", "Can view audit logs", "Admin"),
                new("Admin.SystemConfig", "Can configure system", "Admin"),
            };
            await context.Permissions.AddRangeAsync(permissions);
            await context.SaveChangesAsync();
        }

        // Seed SuperAdmin role with all permissions
        var superAdminRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "SuperAdmin");
        if (superAdminRole != null && !await context.RolePermissions.AnyAsync())
        {
            var allPermissions = await context.Permissions.ToListAsync();
            var rolePermissions = allPermissions.Select(p => new RolePermission
            {
                RoleId = superAdminRole.Id,
                PermissionId = p.Id
            }).ToList();
            await context.RolePermissions.AddRangeAsync(rolePermissions);
            await context.SaveChangesAsync();
        }

        // Seed default admin user
        if (!await context.Users.AnyAsync())
        {
var adminUser = new User(
                "admin@allinfit.com",
                "Super",
                "Admin",
                "$2a$11$K4YfGqJ1e4YHIpQqN5o5Y.5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q5Q" // placeholder - hash in migration
            );
            adminUser.VerifyEmail();
            await context.Users.AddAsync(adminUser);
            await context.SaveChangesAsync();

            // Assign SuperAdmin role to admin
            if (superAdminRole != null)
            {
                context.UserRoles.Add(new UserRole { UserId = adminUser.Id, RoleId = superAdminRole.Id });
                await context.SaveChangesAsync();
            }
        }
    }
}
'@

Write-Host "Seed data generated!"
