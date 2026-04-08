using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class Show
    {
        public int ShowId { get; set; }

        public int? MovieId { get; set; }

        public int? HallId { get; set; }

        public TimeOnly? ShowTime { get; set; }

        public DateOnly? ShowDate { get; set; }

        public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

        public virtual CinemaHall? Hall { get; set; }

        public virtual Movie? Movie { get; set; }
    }
}