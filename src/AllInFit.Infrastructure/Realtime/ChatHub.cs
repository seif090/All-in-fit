using AllInFit.Domain.Entities.Chat;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace AllInFit.Infrastructure.Realtime;

/// <summary>
/// Real-time chat hub. Each conversation is a SignalR group keyed by "conv:{id}".
/// </summary>
[Authorize]
public sealed class ChatHub : Hub
{
    public const string HubPath = "/hubs/chat";
    private const string ConversationGroupPrefix = "conv:";

    public async Task JoinConversation(Guid conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"{ConversationGroupPrefix}{conversationId}");
    }

    public async Task LeaveConversation(Guid conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"{ConversationGroupPrefix}{conversationId}");
    }

    /// <summary>
    /// Broadcasts a message to everyone in the conversation group.
    /// </summary>
    public async Task SendMessage(Guid conversationId, string content, string? attachmentUrl = null)
    {
        var senderId = Context.UserIdentifier;
        if (string.IsNullOrWhiteSpace(senderId))
        {
            throw new HubException("Unauthenticated sender.");
        }

        var message = new
        {
            conversationId,
            senderId,
            content,
            attachmentUrl,
            sentAt = DateTime.UtcNow
        };

        await Clients.Group($"{ConversationGroupPrefix}{conversationId}")
            .SendAsync("receiveMessage", message);
    }
}

public static class ChatMessageMapper
{
    public static object ToTransport(ChatMessage message) => new
    {
        message.Id,
        message.ConversationId,
        message.SenderId,
        message.Content,
        message.AttachmentUrl,
        message.IsRead,
        message.ReadAt,
        message.IsEdited,
        message.EditedAt,
        message.ReplyToMessageId,
        message.CreatedAt
    };
}