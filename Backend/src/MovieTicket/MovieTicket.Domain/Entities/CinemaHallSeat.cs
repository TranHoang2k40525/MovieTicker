

namespace MovieTicket.Domain.Entities
{

    public partial class CinemaHallSeat
    {
        public int SeatId { get; set; }

        public int? HallId { get; set; }

        public string? SeatNumber { get; set; }

        public SeatType? SeatType { get; set; }

        public decimal? SeatPrice { get; set; }

        public int? PairId { get; set; }

        public SeatStatus? Status { get; set; }

        public string? RowSeat { get; set; }

        public int? ColSeat { get; set; }

        public virtual ICollection<BookingSeat> BookingSeats { get; set; } = new List<BookingSeat>();

        public virtual CinemaHall? Hall { get; set; }
    }
    public enum SeatType { Normal = 1, VIP =2, Couple = 3 }
   public enum SeatStatus
    {
        available,
        held,
        booked
    }
}