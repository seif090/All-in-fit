using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Chat;

public sealed class ChatConversation : SoftDeleteEntity
{
    public Guid UserOneId { get; set; }
    public Guid UserTwoId { get; set; }
    public DateTime? LastMessageAt { get; set; }
    public string? LastMessagePreview { get; set; }
    public bool IsArchived { get; set; }
}