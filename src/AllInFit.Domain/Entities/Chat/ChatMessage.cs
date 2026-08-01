using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Chat;

public sealed class ChatMessage : SoftDeleteEntity
{
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? AttachmentUrl { get; set; }
    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsEdited { get; set; }
    public DateTime? EditedAt { get; set; }
    public Guid? ReplyToMessageId { get; set; }
    public ChatConversation? Conversation { get; set; }
}