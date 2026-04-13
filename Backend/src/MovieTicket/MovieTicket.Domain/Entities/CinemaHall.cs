using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class CinemaHall
    {
        public int HallId { get; set; }

        public int? CinemaId { get; set; }

        public string? HallName { get; set; }

        public int? TotalSeats { get; set; }

        public virtual Cinema? Cinema { get; set; }

        public virtual ICollection<CinemaHallSeat> CinemaHallSeats { get; set; } = new List<CinemaHallSeat>();

        public virtual ICollection<RoomLayout> RoomLayouts { get; set; } = new List<RoomLayout>();

        public virtual ICollection<Show> Shows { get; set; } = new List<Show>();
    }
}