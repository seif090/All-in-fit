namespace AllInFit.Shared.Constants;

public static class Permissions
{
    // Auth
    public const string AuthLogin = "Auth.Login";
    public const string AuthRegister = "Auth.Register";
    public const string AuthRefreshToken = "Auth.RefreshToken";
    public const string AuthLogout = "Auth.Logout";
    public const string AuthLogoutAll = "Auth.LogoutAll";

    // Users
    public const string UsersRead = "Users.Read";
    public const string UsersCreate = "Users.Create";
    public const string UsersUpdate = "Users.Update";
    public const string UsersDelete = "Users.Delete";
    public const string UsersManageRoles = "Users.ManageRoles";

    // Roles
    public const string RolesRead = "Roles.Read";
    public const string RolesCreate = "Roles.Create";
    public const string RolesUpdate = "Roles.Update";
    public const string RolesDelete = "Roles.Delete";
    public const string RolesManagePermissions = "Roles.ManagePermissions";

    // Gyms
    public const string GymsRead = "Gyms.Read";
    public const string GymsCreate = "Gyms.Create";
    public const string GymsUpdate = "Gyms.Update";
    public const string GymsDelete = "Gyms.Delete";
    public const string GymsManageBranches = "Gyms.ManageBranches";
    public const string GymsManageMemberships = "Gyms.ManageMemberships";
    public const string GymsManageSchedules = "Gyms.ManageSchedules";

    // Trainers
    public const string TrainersRead = "Trainers.Read";
    public const string TrainersCreate = "Trainers.Create";
    public const string TrainersUpdate = "Trainers.Update";
    public const string TrainersDelete = "Trainers.Delete";
    public const string TrainersVerifyCertificates = "Trainers.VerifyCertificates";

    // Doctors
    public const string DoctorsRead = "Doctors.Read";
    public const string DoctorsCreate = "Doctors.Create";
    public const string DoctorsUpdate = "Doctors.Update";
    public const string DoctorsDelete = "Doctors.Delete";

    // Nutritionists
    public const string NutritionistsRead = "Nutritionists.Read";
    public const string NutritionistsCreate = "Nutritionists.Create";
    public const string NutritionistsUpdate = "Nutritionists.Update";
    public const string NutritionistsDelete = "Nutritionists.Delete";

    // Workouts
    public const string WorkoutsRead = "Workouts.Read";
    public const string WorkoutsCreate = "Workouts.Create";
    public const string WorkoutsUpdate = "Workouts.Update";
    public const string WorkoutsDelete = "Workouts.Delete";

    // Nutrition
    public const string NutritionRead = "Nutrition.Read";
    public const string NutritionCreate = "Nutrition.Create";
    public const string NutritionUpdate = "Nutrition.Update";
    public const string NutritionDelete = "Nutrition.Delete";

    // Marketplace
    public const string MarketplaceRead = "Marketplace.Read";
    public const string MarketplaceCreate = "Marketplace.Create";
    public const string MarketplaceUpdate = "Marketplace.Update";
    public const string MarketplaceDelete = "Marketplace.Delete";
    public const string MarketplaceManageOrders = "Marketplace.ManageOrders";
    public const string MarketplaceManageInventory = "Marketplace.ManageInventory";

    // Wallet
    public const string WalletRead = "Wallet.Read";
    public const string WalletDeposit = "Wallet.Deposit";
    public const string WalletWithdraw = "Wallet.Withdraw";
    public const string WalletTransfer = "Wallet.Transfer";
    public const string WalletManageTransactions = "Wallet.ManageTransactions";

    // Appointments
    public const string AppointmentsRead = "Appointments.Read";
    public const string AppointmentsCreate = "Appointments.Create";
    public const string AppointmentsUpdate = "Appointments.Update";
    public const string AppointmentsCancel = "Appointments.Cancel";
    public const string AppointmentsManage = "Appointments.Manage";

    // Reviews
    public const string ReviewsRead = "Reviews.Read";
    public const string ReviewsCreate = "Reviews.Create";
    public const string ReviewsUpdate = "Reviews.Update";
    public const string ReviewsDelete = "Reviews.Delete";
    public const string ReviewsModerate = "Reviews.Moderate";

    // Notifications
    public const string NotificationsRead = "Notifications.Read";
    public const string NotificationsSend = "Notifications.Send";
    public const string NotificationsManage = "Notifications.Manage";

    // Chat
    public const string ChatRead = "Chat.Read";
    public const string ChatSend = "Chat.Send";
    public const string ChatModerate = "Chat.Moderate";

    // Communities
    public const string CommunitiesRead = "Communities.Read";
    public const string CommunitiesCreate = "Communities.Create";
    public const string CommunitiesUpdate = "Communities.Update";
    public const string CommunitiesDelete = "Communities.Delete";
    public const string CommunitiesModerate = "Communities.Moderate";

    // Challenges
    public const string ChallengesRead = "Challenges.Read";
    public const string ChallengesCreate = "Challenges.Create";
    public const string ChallengesUpdate = "Challenges.Update";
    public const string ChallengesDelete = "Challenges.Delete";

    // Rewards
    public const string RewardsRead = "Rewards.Read";
    public const string RewardsManage = "Rewards.Manage";

    // Analytics
    public const string AnalyticsRead = "Analytics.Read";
    public const string AnalyticsExport = "Analytics.Export";

    // CMS
    public const string CmsRead = "CMS.Read";
    public const string CmsCreate = "CMS.Create";
    public const string CmsUpdate = "CMS.Update";
    public const string CmsDelete = "CMS.Delete";
    public const string CmsPublish = "CMS.Publish";

    // Settings
    public const string SettingsRead = "Settings.Read";
    public const string SettingsUpdate = "Settings.Update";

    // File Manager
    public const string FilesRead = "Files.Read";
    public const string FilesUpload = "Files.Upload";
    public const string FilesDelete = "Files.Delete";

    // Admin
    public const string AdminDashboard = "Admin.Dashboard";
    public const string AdminAuditLogs = "Admin.AuditLogs";
    public const string AdminSystemHealth = "Admin.SystemHealth";

    public static readonly string[] All = new[]
    {
        AuthLogin, AuthRegister, AuthRefreshToken, AuthLogout, AuthLogoutAll,
        UsersRead, UsersCreate, UsersUpdate, UsersDelete, UsersManageRoles,
        RolesRead, RolesCreate, RolesUpdate, RolesDelete, RolesManagePermissions,
        GymsRead, GymsCreate, GymsUpdate, GymsDelete, GymsManageBranches, GymsManageMemberships, GymsManageSchedules,
        TrainersRead, TrainersCreate, TrainersUpdate, TrainersDelete, TrainersVerifyCertificates,
        DoctorsRead, DoctorsCreate, DoctorsUpdate, DoctorsDelete,
        NutritionistsRead, NutritionistsCreate, NutritionistsUpdate, NutritionistsDelete,
        WorkoutsRead, WorkoutsCreate, WorkoutsUpdate, WorkoutsDelete,
        NutritionRead, NutritionCreate, NutritionUpdate, NutritionDelete,
        MarketplaceRead, MarketplaceCreate, MarketplaceUpdate, MarketplaceDelete, MarketplaceManageOrders, MarketplaceManageInventory,
        WalletRead, WalletDeposit, WalletWithdraw, WalletTransfer, WalletManageTransactions,
        AppointmentsRead, AppointmentsCreate, AppointmentsUpdate, AppointmentsCancel, AppointmentsManage,
        ReviewsRead, ReviewsCreate, ReviewsUpdate, ReviewsDelete, ReviewsModerate,
        NotificationsRead, NotificationsSend, NotificationsManage,
        ChatRead, ChatSend, ChatModerate,
        CommunitiesRead, CommunitiesCreate, CommunitiesUpdate, CommunitiesDelete, CommunitiesModerate,
        ChallengesRead, ChallengesCreate, ChallengesUpdate, ChallengesDelete,
        RewardsRead, RewardsManage,
        AnalyticsRead, AnalyticsExport,
        CmsRead, CmsCreate, CmsUpdate, CmsDelete, CmsPublish,
        SettingsRead, SettingsUpdate,
        FilesRead, FilesUpload, FilesDelete,
        AdminDashboard, AdminAuditLogs, AdminSystemHealth
    };
}
