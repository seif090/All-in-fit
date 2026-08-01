using AllInFit.Application.Ports;
using AllInFit.Domain.Entities.Appointments;
using AllInFit.Domain.Entities.Notifications;
using AllInFit.Domain.Enums;
using AllInFit.Domain.Specifications;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;

namespace AllInFit.Infrastructure.Jobs;

/// <summary>
/// Sends in-app + push reminders for upcoming appointments within the
/// configured window (default: next 24 hours).
/// </summary>
public sealed class AppointmentReminderJob
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPushNotificationService _push;
    private readonly ILogger<AppointmentReminderJob> _logger;

    public AppointmentReminderJob(
        IUnitOfWork unitOfWork,
        IPushNotificationService push,
        ILogger<AppointmentReminderJob> logger)
    {
        _unitOfWork = unitOfWork;
        _push = push;
        _logger = logger;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var appointmentRepo = _unitOfWork.Repository<Appointment>();
        var notificationRepo = _unitOfWork.Repository<Notification>();

        var upcoming = await appointmentRepo.GetListBySpecificationAsync(
            new UpcomingAppointmentSpecification(now.AddHours(1), now.AddHours(24)), cancellationToken);

        foreach (var appointment in upcoming)
        {
            var notification = new Notification
            {
                UserId = appointment.UserId,
                Title = "Upcoming Appointment",
                Body = $"You have an appointment at {appointment.ScheduledStart:yyyy-MM-dd HH:mm}.",
                Type = NotificationType.Reminder,
                IsRead = false,
                IsSent = false,
                Channel = "inapp"
            };

            await notificationRepo.AddAsync(notification, cancellationToken);

            await _push.SendToDeviceAsync(
                appointment.UserId.ToString(),
                new PushNotificationPayload("Upcoming Appointment", notification.Body!));
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("AppointmentReminderJob dispatched {Count} reminder(s)", upcoming.Count);
    }
}

internal sealed class UpcomingAppointmentSpecification : BaseSpecification<Appointment>
{
    public UpcomingAppointmentSpecification(DateTime windowStart, DateTime windowEnd)
        : base(a => a.Status == AppointmentStatus.Confirmed
                    && a.ScheduledStart >= windowStart
                    && a.ScheduledStart <= windowEnd)
    {
    }
}