using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class LikeMovie
    {
        public int UserId { get; set; }

        public int MovieId { get; set; }

        public bool? IsLiked { get; set; }

        public virtual Movie Movie { get; set; } = null!;

        public virtual User User { get; set; } = null!;
    }
}