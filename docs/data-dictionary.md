# Data Dictionary

| Entity | Purpose | Key Fields |
|---|---|---|
| `User` | Platform account and identity root | `Id`, `Email`, `PasswordHash`, `IsActive`, `IsEmailVerified` |
| `Role` | RBAC role container | `Id`, `Name`, `Description`, `IsSystem` |
| `Permission` | Fine-grained capability flag | `Id`, `Name`, `Category`, `Description` |
| `RefreshToken` | Rotating token session record | `Id`, `UserId`, `Token`, `ExpiresAt`, `IsRevoked`, `IsUsed` |
| `Gym` | Gym owner and brand entity | `Id`, `Name`, `LegalName`, `OwnerUserId`, `Rating`, `IsActive` |
| `GymBranch` | Physical gym location | `Id`, `GymId`, `Name`, `Latitude`, `Longitude` |
| `Wallet` | User balance container | `Id`, `UserId`, `Balance`, `Currency` |
| `WalletTransaction` | Money movement history | `Id`, `WalletId`, `Amount`, `Type`, `ReferenceId` |
| `Appointment` | Booking record | `Id`, `UserId`, `ProviderId`, `StartAt`, `EndAt`, `Status` |
| `Notification` | In-app notification record | `Id`, `UserId`, `Title`, `Body`, `IsRead` |

## Conventions

- Primary keys use GUIDs.
- All auditable entities use UTC timestamps.
- Soft-delete entities retain history instead of hard delete when possible.