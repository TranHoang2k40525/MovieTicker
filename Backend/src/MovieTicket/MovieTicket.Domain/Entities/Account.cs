
namespace MovieTicket.Domain.Entities
{
    public partial class Account
    {
        public int AccountId { get; set; }

        public string? Email { get; set; }

        public string? Phone { get; set; }

        public string PasswordHash { get; set; } = null!;

        public Status? Status { get; set; }

        public DateTime? CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }

        public int? CinemaId { get; set; }

        public virtual Cinema? Cinema { get; set; }

        public virtual ICollection<AccountRole> AccountRoles { get; set; } = new List<AccountRole>();

        public virtual ICollection<LoginHistory> LoginHistories { get; set; } = new List<LoginHistory>();

        public virtual ICollection<Otp> Otps { get; set; } = new List<Otp>();

        public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

        public virtual ICollection<User> Users { get; set; } = new List<User>();
    }
    public enum Status
    {
        active,
        blocked,
        pending_verification
    }

}

