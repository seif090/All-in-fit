$base = "c:\Users\seaif\Desktop\All in fit\src\AllInFit.Domain"

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Created: $path"
}

# ===== Reviews & Ratings =====
Write-File "$base\Entities\Reviews\Review.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Reviews;

public sealed class Review : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public int Rating { get; set; }
    public string? Title { get; set; }
    public string? Comment { get; set; }
    public Guid? GymId { get; set; }
    public Guid? GymBranchId { get; set; }
    public Guid? TrainerId { get; set; }
    public Guid? DoctorId { get; set; }
    public Guid? NutritionistId { get; set; }
    public Guid? ProductId { get; set; }
    public Guid? WorkoutProgramId { get; set; }
    public Guid? MealPlanId { get; set; }
    public bool IsApproved { get; set; }
    public bool IsVerifiedPurchase { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
'@

# ===== Notifications =====
Write-File "$base\Entities\Notifications\Notification.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Notifications;

public sealed class Notification : SoftDeleteEntity
{
    public Guid UserId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Body { get; set; }
    public NotificationType Type { get; set; }
    public string? Data { get; set; }
    public string? ImageUrl { get; set; }
    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsSent { get; set; }
    public DateTime? SentAt { get; set; }
    public string? Channel { get; set; }
}
'@

Write-File "$base\Entities\Notifications\NotificationTemplate.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Notifications;

public sealed class NotificationTemplate : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Subject { get; set; }
    public string? Body { get; set; }
    public string? EmailTemplate { get; set; }
    public string? SmsTemplate { get; set; }
    public string? PushTemplate { get; set; }
    public bool IsActive { get; set; } = true;
}
'@

# ===== Chat =====
Write-File "$base\Entities\Chat\ChatConversation.cs" @'
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
'@

Write-File "$base\Entities\Chat\ChatMessage.cs" @'
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
'@

# ===== Communities =====
Write-File "$base\Entities\Communities\Community.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Community : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? CoverImageUrl { get; set; }
    public bool IsPrivate { get; set; }
    public bool IsActive { get; set; } = true;
    public Guid? CreatedByUserId { get; set; }
    public int MemberCount { get; set; }
    public int PostCount { get; set; }
}
'@

Write-File "$base\Entities\Communities\CommunityMember.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class CommunityMember : BaseEntity
{
    public Guid CommunityId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "Member";
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
    public Community? Community { get; set; }
}
'@

Write-File "$base\Entities\Communities\Post.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Post : SoftDeleteEntity
{
    public Guid CommunityId { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int LikeCount { get; set; }
    public int CommentCount { get; set; }
    public bool IsPinned { get; set; }
    public Community? Community { get; set; }
}
'@

Write-File "$base\Entities\Communities\Comment.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Comment : SoftDeleteEntity
{
    public Guid PostId { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public Guid? ParentCommentId { get; set; }
    public int LikeCount { get; set; }
    public Post? Post { get; set; }
}
'@

Write-File "$base\Entities\Communities\Like.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Communities;

public sealed class Like : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid? PostId { get; set; }
    public Guid? CommentId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public Post? Post { get; set; }
    public Comment? Comment { get; set; }
}
'@

# ===== Gamification =====
Write-File "$base\Entities\Gamification\Challenge.cs" @'
using AllInFit.Domain.Common;
using AllInFit.Domain.Enums;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class Challenge : SoftDeleteEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public ChallengeType Type { get; set; }
    public int TargetValue { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int RewardPoints { get; set; }
    public bool IsActive { get; set; } = true;
    public int ParticipantCount { get; set; }
}
'@

Write-File "$base\Entities\Gamification\ChallengeParticipant.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class ChallengeParticipant : BaseEntity
{
    public Guid ChallengeId { get; set; }
    public Guid UserId { get; set; }
    public int Progress { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int Rank { get; set; }
    public Challenge? Challenge { get; set; }
}
'@

Write-File "$base\Entities\Gamification\LeaderboardEntry.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class LeaderboardEntry : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid? ChallengeId { get; set; }
    public Guid? CommunityId { get; set; }
    public int Score { get; set; }
    public int Rank { get; set; }
    public string? Period { get; set; }
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
}
'@

Write-File "$base\Entities\Gamification\Achievement.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class Achievement : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public int RewardPoints { get; set; }
    public string? Criteria { get; set; }
}
'@

Write-File "$base\Entities\Gamification\UserAchievement.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class UserAchievement : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid AchievementId { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    public Achievement? Achievement { get; set; }
}
'@

Write-File "$base\Entities\Gamification\Badge.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class Badge : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? IconUrl { get; set; }
    public int RewardPoints { get; set; }
    public string? Tier { get; set; }
}
'@

Write-File "$base\Entities\Gamification\UserBadge.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Gamification;

public sealed class UserBadge : BaseEntity
{
    public Guid UserId { get; set; }
    public Guid BadgeId { get; set; }
    public DateTime EarnedAt { get; set; } = DateTime.UtcNow;
    public Badge? Badge { get; set; }
}
'@

# ===== Referral =====
Write-File "$base\Entities\Referrals\Referral.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Referrals;

public sealed class Referral : BaseEntity
{
    public Guid ReferrerUserId { get; set; }
    public Guid ReferredUserId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public bool IsRewarded { get; set; }
    public int RewardPoints { get; set; }
    public DateTime ReferredAt { get; set; } = DateTime.UtcNow;
}
'@

# ===== CRM =====
Write-File "$base\Entities\Crm\CrmCustomer.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Crm;

public sealed class CrmCustomer : SoftDeleteEntity
{
    public Guid? UserId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? Tags { get; set; }
    public string? Notes { get; set; }
    public string? Source { get; set; }
    public DateTime? LastContactAt { get; set; }
    public decimal LifetimeValue { get; set; }
    public string? Segment { get; set; }
}
'@

# ===== CMS =====
Write-File "$base\Entities\Cms\CmsContent.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Cms;

public sealed class CmsContent : SoftDeleteEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Slug { get; set; }
    public string? Content { get; set; }
    public string? Summary { get; set; }
    public string? CoverImageUrl { get; set; }
    public string? Category { get; set; }
    public string[]? Tags { get; set; }
    public bool IsPublished { get; set; }
    public DateTime? PublishedAt { get; set; }
    public string? Author { get; set; }
    public int ViewCount { get; set; }
}
'@

Write-File "$base\Entities\Cms\Setting.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Cms;

public sealed class Setting : BaseEntity
{
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Type { get; set; }
    public bool IsPublic { get; set; }
}
'@

Write-File "$base\Entities\Files\StoredFile.cs" @'
using AllInFit.Domain.Common;

namespace AllInFit.Domain.Entities.Files;

public sealed class StoredFile : SoftDeleteEntity
{
    public string FileName { get; set; } = string.Empty;
    public string? OriginalName { get; set; }
    public string ContentType { get; set; } = string.Empty;
    public long SizeInBytes { get; set; }
    public string? StorageProvider { get; set; }
    public string? FileKey { get; set; }
    public string? PublicUrl { get; set; }
    public string? Folder { get; set; }
    public string? Metadata { get; set; }
    public Guid? UploadedByUserId { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
'@

Write-Host "Domain layer part 4 generated successfully!"
