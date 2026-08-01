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