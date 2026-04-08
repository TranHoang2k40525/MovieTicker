using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class Otp
    {
        public int OtpId { get; set; }

        public int AccountId { get; set; }

        public string OtpHash { get; set; } = null!;

        public string? Purpose { get; set; }

        public DateTime ExpiresAt { get; set; }

        public bool? Used { get; set; }

        public DateTime? CreatedAt { get; set; }

        public virtual Account Account { get; set; } = null!;
    }
}