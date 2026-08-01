$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Persistence\Configurations"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fixed: $path"
}

# ===== Identity Configurations =====
Write-File "$base\Identity\UserConfiguration.cs" @'
using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("Users");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Email).HasMaxLength(255).IsRequired();
        builder.HasIndex(e => e.Email).IsUnique().HasDatabaseName("IX_Users_Email");
        builder.Property(e => e.PasswordHash).HasMaxLength(500).IsRequired();
        builder.Property(e => e.FirstName).HasMaxLength(100);
        builder.Property(e => e.LastName).HasMaxLength(100);
        builder.Property(e => e.PhoneNumber).HasMaxLength(20);
        builder.HasIndex(e => e.PhoneNumber).HasDatabaseName("IX_Users_PhoneNumber");
        builder.Property(e => e.ProfilePictureUrl).HasMaxLength(500);
        builder.Property(e => e.Bio).HasMaxLength(1000);
        builder.Property(e => e.GoogleId).HasMaxLength(200);
        builder.Property(e => e.OtpCode).HasMaxLength(10);
        builder.Property(e => e.RefreshToken).HasMaxLength(500);
        builder.Property(e => e.AccountType).HasConversion<string>().HasMaxLength(50);
    }
}
'@

Write-File "$base\Identity\PermissionConfiguration.cs" @'
using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class PermissionConfiguration : IEntityTypeConfiguration<Permission>
{
    public void Configure(EntityTypeBuilder<Permission> builder)
    {
        builder.ToTable("Permissions");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(200).IsRequired();
        builder.HasIndex(e => e.Name).IsUnique().HasDatabaseName("IX_Permissions_Name");
        builder.Property(e => e.Description).HasMaxLength(500);
        builder.Property(e => e.Group).HasMaxLength(100);
    }
}
'@

Write-File "$base\Identity\RefreshTokenConfiguration.cs" @'
using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("RefreshTokens");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Token).HasMaxLength(500).IsRequired();
        builder.HasIndex(e => e.Token).IsUnique().HasDatabaseName("IX_RefreshTokens_Token");
        builder.Property(e => e.DeviceId).HasMaxLength(200);
        builder.HasOne(e => e.User).WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
'@

Write-File "$base\Identity\UserDeviceConfiguration.cs" @'
using AllInFit.Domain.Entities.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Identity;

public sealed class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.ToTable("UserDevices");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.DeviceId).HasMaxLength(200).IsRequired();
        builder.Property(e => e.DeviceName).HasMaxLength(200);
        builder.Property(e => e.DeviceType).HasMaxLength(50);
        builder.Property(e => e.FcmToken).HasMaxLength(500);
        builder.HasOne(e => e.User).WithMany().HasForeignKey(e => e.UserId).OnDelete(DeleteBehavior.Cascade);
    }
}
'@

# ===== Gym Configurations =====
Write-File "$base\Gyms\GymConfiguration.cs" @'
using AllInFit.Domain.Entities.Gyms;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Gyms;

public sealed class GymConfiguration : IEntityTypeConfiguration<Gym>
{
    public void Configure(EntityTypeBuilder<Gym> builder)
    {
        builder.ToTable("Gyms");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(200).IsRequired();
        builder.HasIndex(e => e.Name).HasDatabaseName("IX_Gyms_Name");
        builder.Property(e => e.LegalName).HasMaxLength(200).IsRequired();
        builder.Property(e => e.LogoUrl).HasMaxLength(500);
        builder.Property(e => e.Website).HasMaxLength(500);
    }
}
'@

Write-File "$base\Gyms\GymBranchConfiguration.cs" @'
using AllInFit.Domain.Entities.Gyms;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Gyms;

public sealed class GymBranchConfiguration : IEntityTypeConfiguration<GymBranch>
{
    public void Configure(EntityTypeBuilder<GymBranch> builder)
    {
        builder.ToTable("GymBranches");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(200).IsRequired();
        builder.Property(e => e.Address).HasMaxLength(500);
        builder.Property(e => e.City).HasMaxLength(100);
        builder.Property(e => e.State).HasMaxLength(100);
        builder.Property(e => e.Country).HasMaxLength(100);
        builder.Property(e => e.PostalCode).HasMaxLength(20);
        builder.Property(e => e.PhoneNumber).HasMaxLength(20);
        builder.Property(e => e.Email).HasMaxLength(255);
        builder.HasOne(e => e.Gym).WithMany(g => g.Branches).HasForeignKey(e => e.GymId).OnDelete(DeleteBehavior.Cascade);
    }
}
'@

# ===== Marketplace Configurations =====
Write-File "$base\Marketplace\ProductConfiguration.cs" @'
using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable("Products");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Name).HasMaxLength(300).IsRequired();
        builder.HasIndex(e => e.Name).HasDatabaseName("IX_Products_Name");
        builder.Property(e => e.Description).HasMaxLength(2000);
        builder.Property(e => e.Price).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.Currency).HasMaxLength(3).IsRequired().HasDefaultValue("USD");
        builder.Property(e => e.Sku).HasMaxLength(100);
        builder.HasIndex(e => e.Sku).IsUnique().HasDatabaseName("IX_Products_Sku").HasFilter("[Sku] IS NOT NULL AND [Sku] <> ''");
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasOne(e => e.Brand).WithMany().HasForeignKey(e => e.BrandId).OnDelete(DeleteBehavior.SetNull);
    }
}
'@

Write-File "$base\Marketplace\OrderConfiguration.cs" @'
using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable("Orders");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.OrderNumber).HasMaxLength(50).IsRequired();
        builder.HasIndex(e => e.OrderNumber).IsUnique().HasDatabaseName("IX_Orders_OrderNumber");
        builder.Property(e => e.Subtotal).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.DiscountAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.ShippingAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.TaxAmount).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.TotalAmount).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.Currency).HasMaxLength(3).HasDefaultValue("USD");
        builder.Property(e => e.ShippingAddress).HasMaxLength(500);
        builder.Property(e => e.BillingAddress).HasMaxLength(500);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50);
    }
}
'@

Write-File "$base\Marketplace\OrderItemConfiguration.cs" @'
using AllInFit.Domain.Entities.Marketplace;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Marketplace;

public sealed class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("OrderItems");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.ProductName).HasMaxLength(300).IsRequired();
        builder.Property(e => e.UnitPrice).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.LineTotal).HasColumnType("decimal(18,2)").IsRequired();
        builder.HasOne(e => e.Order).WithMany(o => o.Items).HasForeignKey(e => e.OrderId).OnDelete(DeleteBehavior.Cascade);
        builder.HasOne(e => e.Product).WithMany().HasForeignKey(e => e.ProductId).OnDelete(DeleteBehavior.Restrict);
    }
}
'@

# ===== Wallet Configurations =====
Write-File "$base\Wallet\WalletConfiguration.cs" @'
using AllInFit.Domain.Entities.Wallet;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Wallet;

public sealed class WalletConfiguration : IEntityTypeConfiguration<Domain.Entities.Wallet.Wallet>
{
    public void Configure(EntityTypeBuilder<Domain.Entities.Wallet.Wallet> builder)
    {
        builder.ToTable("Wallets");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Balance).HasColumnType("decimal(18,2)").IsRequired().HasDefaultValue(0);
        builder.Property(e => e.RewardPointsBalance).HasColumnType("decimal(18,2)").HasDefaultValue(0);
        builder.Property(e => e.Currency).HasMaxLength(3).IsRequired().HasDefaultValue("USD");
        builder.HasIndex(e => e.UserId).IsUnique().HasDatabaseName("IX_Wallets_UserId");
    }
}
'@

Write-File "$base\Wallet\WalletTransactionConfiguration.cs" @'
using AllInFit.Domain.Entities.Wallet;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Wallet;

public sealed class WalletTransactionConfiguration : IEntityTypeConfiguration<WalletTransaction>
{
    public void Configure(EntityTypeBuilder<WalletTransaction> builder)
    {
        builder.ToTable("WalletTransactions");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Amount).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.BalanceAfter).HasColumnType("decimal(18,2)").IsRequired();
        builder.Property(e => e.Description).HasMaxLength(500);
        builder.Property(e => e.Reference).HasMaxLength(200);
        builder.Property(e => e.Type).HasConversion<string>().HasMaxLength(50);
        builder.HasOne(e => e.Wallet).WithMany(w => w.Transactions).HasForeignKey(e => e.WalletId).OnDelete(DeleteBehavior.Cascade);
    }
}
'@

# ===== Appointment Configurations =====
Write-File "$base\Appointments\AppointmentConfiguration.cs" @'
using AllInFit.Domain.Entities.Appointments;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Appointments;

public sealed class AppointmentConfiguration : IEntityTypeConfiguration<Appointment>
{
    public void Configure(EntityTypeBuilder<Appointment> builder)
    {
        builder.ToTable("Appointments");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Status).HasConversion<string>().HasMaxLength(50).IsRequired();
        builder.Property(e => e.Notes).HasMaxLength(1000);
        builder.Property(e => e.MeetingUrl).HasMaxLength(500);
        builder.Property(e => e.Fee).HasColumnType("decimal(18,2)");
        builder.Property(e => e.Currency).HasMaxLength(3).HasDefaultValue("USD");
        builder.Property(e => e.CancellationReason).HasMaxLength(500);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Appointments_UserId");
        builder.HasIndex(e => e.TrainerId).HasDatabaseName("IX_Appointments_TrainerId");
    }
}
'@

# ===== Review Configuration =====
Write-File "$base\Reviews\ReviewConfiguration.cs" @'
using AllInFit.Domain.Entities.Reviews;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Reviews;

public sealed class ReviewConfiguration : IEntityTypeConfiguration<Review>
{
    public void Configure(EntityTypeBuilder<Review> builder)
    {
        builder.ToTable("Reviews");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Rating).IsRequired();
        builder.Property(e => e.Title).HasMaxLength(200);
        builder.Property(e => e.Comment).HasMaxLength(2000);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Reviews_UserId");
        builder.HasIndex(e => e.GymId).HasDatabaseName("IX_Reviews_GymId");
        builder.HasIndex(e => e.ProductId).HasDatabaseName("IX_Reviews_ProductId");
    }
}
'@

# ===== Notification Configuration =====
Write-File "$base\Notifications\NotificationConfiguration.cs" @'
using AllInFit.Domain.Entities.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Notifications;

public sealed class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("Notifications");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Title).HasMaxLength(200).IsRequired();
        builder.Property(e => e.Body).HasMaxLength(2000);
        builder.Property(e => e.Type).HasConversion<string>().HasMaxLength(50);
        builder.Property(e => e.Channel).HasMaxLength(50);
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Notifications_UserId");
        builder.HasIndex(e => new { e.UserId, e.IsRead }).HasDatabaseName("IX_Notifications_User_Read");
    }
}
'@

# ===== Chat Configuration =====
Write-File "$base\Chat\ChatMessageConfiguration.cs" @'
using AllInFit.Domain.Entities.Chat;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Chat;

public sealed class ChatMessageConfiguration : IEntityTypeConfiguration<ChatMessage>
{
    public void Configure(EntityTypeBuilder<ChatMessage> builder)
    {
        builder.ToTable("ChatMessages");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Content).HasMaxLength(4000).IsRequired();
        builder.Property(e => e.AttachmentUrl).HasMaxLength(500);
        builder.HasOne(e => e.Conversation).WithMany().HasForeignKey(e => e.ConversationId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(e => e.ConversationId).HasDatabaseName("IX_ChatMessages_ConversationId");
        builder.HasIndex(e => e.SenderId).HasDatabaseName("IX_ChatMessages_SenderId");
    }
}
'@

# ===== Community Configuration =====
Write-File "$base\Communities\PostConfiguration.cs" @'
using AllInFit.Domain.Entities.Communities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AllInFit.Persistence.Configurations.Communities;

public sealed class PostConfiguration : IEntityTypeConfiguration<Post>
{
    public void Configure(EntityTypeBuilder<Post> builder)
    {
        builder.ToTable("Posts");
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Content).HasMaxLength(5000).IsRequired();
        builder.Property(e => e.ImageUrl).HasMaxLength(500);
        builder.HasOne(e => e.Community).WithMany().HasForeignKey(e => e.CommunityId).OnDelete(DeleteBehavior.Cascade);
        builder.HasIndex(e => e.CommunityId).HasDatabaseName("IX_Posts_CommunityId");
        builder.HasIndex(e => e.UserId).HasDatabaseName("IX_Posts_UserId");
    }
}
'@

Write-Host "All configurations fixed to match entity properties!"
