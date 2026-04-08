using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class RefreshToken
    {
        public int TokenId { get; set; }

        public int? AccountId { get; set; }

        public string? RefreshToken1 { get; set; }

        public DateTime? ExpiresAt { get; set; }

        public DateTime? CreatedAt { get; set; }

        public virtual Account? Account { get; set; }
    }
}