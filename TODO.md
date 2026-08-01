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

## Phase 2 — Domain Layer
- [ ] Base classes (BaseEntity, AuditableEntity, SoftDelete, ValueObject, DomainEvent)
- [ ] Identity & Auth aggregates (User, RefreshToken, Session, UserDevice, Role, Permission)
- [ ] Gym aggregates (Gym, GymBranch, GymOwner, GymMembership, GymSchedule)
- [ ] Fitness Professional aggregates (Trainer, TrainerCertificate, TrainerAvailability, Doctor, DoctorSpecialty, Nutritionist)
- [ ] Workout aggregates (WorkoutProgram, WorkoutCategory, Exercise, ExerciseLibrary)
- [ ] Nutrition aggregates (MealPlan, Recipe)
- [ ] Marketplace aggregates (Product, Brand, Cart, Wishlist, Order, OrderItem, Payment, Coupon)
- [ ] Wallet aggregates (Wallet, WalletTransaction)
- [ ] Appointments aggregate (Appointment)
- [ ] Reviews aggregate (Review, Rating)
- [ ] Notification aggregate (Notification, NotificationTemplate)
- [ ] Chat aggregates (Chat, ChatMessage)
- [ ] Community aggregates (Community, Post, Comment, Like)
- [ ] Gamification aggregates (Challenge, LeaderboardEntry, Achievement, Badge, RewardPoint, Referral)
- [ ] CRM aggregate (CrmCustomer)
- [ ] CMS aggregate (CmsContent, Setting)
- [ ] File aggregate (StoredFile)
- [ ] Domain specifications

## Phase 3 — Persistence Layer
- [ ] DbContext (all DbSets, query filters for soft delete)
- [ ] Entity configurations (Fluent API — keys, indexes, FKs, constraints, concurrency)
- [ ] Repository pattern (IGenericRepository, Specification)
- [ ] UnitOfWork
- [ ] EF interceptors (audit, soft delete)
- [ ] Migrations
- [ ] Seed data (roles, permissions, admin, reference data)
- [ ] Database schema scripts (views, SPs, functions, triggers)

## Phase 4 — Application Layer
- [ ] DTOs + mapping profiles (Mapster/AutoMapper)
- [ ] Validators (FluentValidation) for all commands
- [ ] CQRS Commands + Handlers (all modules)
- [ ] CQRS Queries + Handlers (all modules)
- [ ] MediatR pipelines (validation, logging, transaction, caching, performance)
- [ ] Auth services (JWT, refresh rotation, OTP, Google, sessions)
- [ ] Application settings (Options pattern)

## Phase 5 — Infrastructure Layer
- [ ] Serilog setup (files, console, seq)
- [ ] Redis cache service + distributed cache
- [ ] RabbitMQ event bus
- [ ] Hangfire jobs (scheduler, recurring)
- [ ] SignalR hub (notifications, chat)
- [ ] JWT provider (RS256)
- [ ] Email/SMS/Push notification senders
- [ ] File storage adapters (local, cloudinary, s3, azure)
- [ ] Payment adapters (stripe, paymob, fawry, wallet)
- [ ] Map adapters (nominatim, osrm, overpass)
- [ ] Rate limiting
- [ ] Health checks

## Phase 6 — Presentation Layer (API)
- [ ] Program.cs composition root
- [ ] Controllers (all modules, API versioning)
- [ ] Middleware (exception handling, request logging, CORS, compression)
- [ ] Filters (validation, authorization, caching)
- [ ] Swagger/OpenAPI + Postman collection
- [ ] API endpoints documentation

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

