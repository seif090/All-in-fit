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