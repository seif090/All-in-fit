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