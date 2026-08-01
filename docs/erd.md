# ERD

```mermaid
erDiagram
    User ||--o{ RefreshToken : has
    User ||--o{ UserRole : assigned
    Role ||--o{ UserRole : contains
    Role ||--o{ RolePermission : grants
    Permission ||--o{ RolePermission : referenced_by
    User ||--o{ Gym : owns
    Gym ||--o{ GymBranch : has
    Gym ||--o{ GymMembership : sells
    Gym ||--o{ GymSchedule : schedules
    User ||--o{ Wallet : owns
    Wallet ||--o{ WalletTransaction : records
    User ||--o{ Appointment : books
    User ||--o{ Notification : receives
    User ||--o{ ChatConversation : participates
    ChatConversation ||--o{ ChatMessage : contains
```

## Notes

- Soft-delete entities are filtered by query filters in EF Core.
- Auditable entities carry creation and update metadata.
- Optimistic concurrency is enforced where configured in entity mappings.