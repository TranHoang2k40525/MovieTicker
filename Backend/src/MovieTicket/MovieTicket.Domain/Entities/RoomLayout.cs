using System;

namespace MovieTicket.Domain.Entities
{
    public class RoomLayout
    {
        public int LayoutId { get; set; }
        public int HallId { get; set; }
        public string RowSeat { get; set; } = null!;
        public int ColSeat { get; set; }
        public string CellType { get; set; } = null!;

        public virtual CinemaHall Hall { get; set; } = null!;
    }
}
