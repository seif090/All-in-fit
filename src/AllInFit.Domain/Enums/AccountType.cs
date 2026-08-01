namespace AllInFit.Domain.Enums;

public enum AccountType { User = 0, GymOwner = 1, Trainer = 2, Doctor = 3, Nutritionist = 4, RestaurantOwner = 5, PharmacyOwner = 6, SupplementSeller = 7, Admin = 8, SuperAdmin = 9 }
public enum Gender { Male = 0, Female = 1, Other = 2 }
public enum MembershipStatus { Active = 0, Expired = 1, Cancelled = 2, Pending = 3 }
public enum AppointmentStatus { Pending = 0, Confirmed = 1, Completed = 2, Cancelled = 3, Rescheduled = 4, NoShow = 5 }
public enum OrderStatus { Pending = 0, Confirmed = 1, Processing = 2, Shipped = 3, Delivered = 4, Cancelled = 5, Refunded = 6, Returned = 7 }
public enum PaymentStatus { Pending = 0, Succeeded = 1, Failed = 2, Refunded = 3, PartiallyRefunded = 4 }
public enum WalletTransactionType { Deposit = 0, Withdrawal = 1, Payment = 2, Refund = 3, Reward = 4, Referral = 5, Transfer = 6 }
public enum NotificationType { System = 0, Appointment = 1, Message = 2, Payment = 3, Promotion = 4, Reminder = 5, Challenge = 6, Reward = 7, Achievement = 8 }
public enum ChallengeType { Steps = 0, Workout = 1, Nutrition = 2, Weight = 3, Streak = 4, Custom = 5 }
public enum DifficultyLevel { Beginner = 0, Intermediate = 1, Advanced = 2, Elite = 3 }
public enum MealType { Breakfast = 0, Lunch = 1, Dinner = 2, Snack = 3, PreWorkout = 4, PostWorkout = 5 }