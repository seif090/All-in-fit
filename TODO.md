# All In Fit — Backend Build Tracker

> Enterprise Health & Fitness SaaS Platform — .NET 9 / Clean Architecture / CQRS / DDD

## Status Legend
- [ ] Not started
- [x] Complete
- [~] In progress

---

## Phase 0 — Scaffolding ✓
- [x] Create TODO.md tracker
- [x] Create solution & project structure (src + tests)
- [x] Wire project references (Clean Architecture dependency rule)
- [x] Install NuGet packages per layer
- [x] Verify `dotnet build` passes

## Phase 1 — Shared Kernel ✓
- [x] Result pattern (Result, Result<T>, Errors)
- [x] Constants (roles, permissions, claim types, cache keys, policies)
- [x] Extensions (string, enum, collection, claims)
- [x] Event bus contracts (IIntegrationEvent, IEventBus)
- [x] Notification contracts (IEmailSender, ISmsSender, IPushNotificationService)
- [x] File storage contracts (IFileStorage)
- [x] Payment contracts (IPaymentGateway, PaymentRequest/Result)
- [x] Map contracts (IMapService)
- [x] Shared DTOs (PagedResult, PaginationRequest)

## Phase 2 — Domain Layer ✓
- [x] Base classes (BaseEntity, AuditableEntity, SoftDelete, ValueObject, DomainEvent)
- [x] Identity & Auth aggregates (User, RefreshToken, Session, UserDevice, Role, Permission)
- [x] Gym aggregates (Gym, GymBranch, GymOwner, GymMembership, GymSchedule)
- [x] Fitness Professional aggregates (Trainer, TrainerCertificate, TrainerAvailability, Doctor, DoctorSpecialty, Nutritionist)
- [x] Workout aggregates (WorkoutProgram, WorkoutCategory, Exercise, ExerciseLibrary)
- [x] Nutrition aggregates (MealPlan, Recipe)
- [x] Marketplace aggregates (Product, Brand, Cart, Wishlist, Order, OrderItem, Payment, Coupon)
- [x] Wallet aggregates (Wallet, WalletTransaction)
- [x] Appointments aggregate (Appointment)
- [x] Reviews aggregate (Review, Rating)
- [x] Notification aggregate (Notification, NotificationTemplate)
- [x] Chat aggregates (Chat, ChatMessage)
- [x] Community aggregates (Community, Post, Comment, Like)
- [x] Gamification aggregates (Challenge, LeaderboardEntry, Achievement, Badge, RewardPoint, Referral)
- [x] CRM aggregate (CrmCustomer)
- [x] CMS aggregate (CmsContent, Setting)
- [x] File aggregate (StoredFile)
- [x] Domain specifications

## Phase 3 — Persistence Layer ✓
- [x] DbContext (all DbSets, query filters for soft delete)
- [x] Entity configurations (Fluent API — keys, indexes, FKs, constraints, concurrency)
- [x] Repository pattern (IGenericRepository, Specification)
- [x] UnitOfWork
- [x] EF interceptors (audit, soft delete)
- [x] Migrations (applied to local SQL Server `AllInFit` — 58 tables)
- [x] Seed data (roles, permissions, admin, reference data)
- [x] Database schema scripts (views, SPs, functions, triggers)

## Phase 4 — Application Layer ✓
- [x] DTOs (Login, Register, Token, Pagination)
- [x] Validators (FluentValidation via pipeline)
- [x] CQRS Commands + Handlers (Auth, Gym, User)
- [x] CQRS Queries + Handlers (Gym, User)
- [x] MediatR pipelines (ValidationBehavior, LoggingBehavior, TransactionBehavior)
- [x] Ports interfaces (IUnitOfWork, IGenericRepository)
- [x] Application DI registration
- [ ] Auth services (JWT, refresh rotation, OTP, Google, sessions) — in Infrastructure
- [ ] Application settings (Options pattern) — in Infrastructure

## Phase 5 — Infrastructure Layer  [COMPLETE — API verified: build 0/0, /health 200 with DB check]
- [x] Serilog setup (files, console, seq)
- [x] Redis cache service + distributed cache
- [x] RabbitMQ event bus + InMemoryEventBus fallback
- [x] Hangfire jobs (ExpiredMembershipJob, AppointmentReminderJob, WalletDailyDigestJob)
- [x] SignalR hub (NotificationsHub, ChatHub)
- [x] JWT provider (RS256)
- [x] Email/SMS/Push notification senders (MailKit, Twilio, Firebase)
- [x] File storage adapters (Local, Cloudinary, S3, Azure Blob)
- [x] Payment adapters (Stripe, Paymob, Fawry, Wallet)
- [x] Map adapters (Nominatim, OSRM, Overpass)
- [x] Rate limiting
- [x] Health checks

## Phase 6 — Presentation Layer (API)
- [x] Program.cs composition root (Serilog, layer DI, health, rate limiter, SignalR hubs, Hangfire dashboard, Swagger)
- [ ] Controllers (all modules, API versioning)
- [x] Middleware (request logging via Serilog, exception handled, rate limiter, SignalR, HTTPS redirection)
- [ ] Filters (validation, authorization, caching)
- [x] Swagger/OpenAPI (SwaggerGen + UI)
- [ ] API endpoints documentation + Postman collection

## Phase 7 — Testing
- [ ] Unit tests (domain, application, result pattern, validators)
- [ ] Integration tests (persistence, repositories, auth)
- [ ] API tests (WebApplicationFactory)
- [ ] Performance/security tests

## Phase 8 — DevOps & Docs
- [ ] Dockerfile + docker-compose (SQL Server, Redis, RabbitMQ, API, NGINX)
- [ ] GitHub Actions CI/CD
- [ ] README + deployment guide
- [ ] Architecture diagram, ERD, data dictionary, sequence diagrams
- [ ] Final `dotnet build` + `dotnet test` verification

