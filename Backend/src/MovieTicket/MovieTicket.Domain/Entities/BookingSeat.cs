

namespace MovieTicket.Domain.Entities
{

    public partial class BookingSeat
    {
        public int BookingSeatId { get; set; }

        public int? BookingId { get; set; }

        public int? SeatId { get; set; }

        public BookingSeatStatus Status { get; set; }

        public decimal? TicketPrice { get; set; }

        public DateTime? HoldUntil { get; set; }

        public int? ShowId { get; set; }

        public virtual Booking? Booking { get; set; }

        public virtual CinemaHallSeat? Seat { get; set; }
    }
    public enum BookingSeatStatus
    {
        available,
        held,
        booked
    }
}