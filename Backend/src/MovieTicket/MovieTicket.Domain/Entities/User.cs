using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class User
    {
        public int UserId { get; set; }

        public int AccountId { get; set; }

        public string? FullName { get; set; }

        public string? Email { get; set; }

        public string? Phone { get; set; }

        public string? Gender { get; set; }

        public DateOnly? DateOfBirth { get; set; }

        public string? Address { get; set; }

        public string? AvatarUrl { get; set; }

        public virtual Account Account { get; set; } = null!;

        public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

        public virtual ICollection<LikeMovie> LikeMovies { get; set; } = new List<LikeMovie>();

        public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

        public virtual ICollection<VoucherUsage> VoucherUsages { get; set; } = new List<VoucherUsage>();
    }
}