

namespace MovieTicket.Domain.Entities
{
    public partial class Booking
    {
        public int BookingId { get; set; }

        public int? UserId { get; set; }

        public int? ShowId { get; set; }

        public int? TotalSeats { get; set; }

        public BookingStatus Status { get; set; }

        public virtual ICollection<BookingProduct> BookingProducts { get; set; } = new List<BookingProduct>();

        public virtual ICollection<BookingSeat> BookingSeats { get; set; } = new List<BookingSeat>();

        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

        public virtual Show? Show { get; set; }

        public virtual User? User { get; set; }
    }
    public enum BookingStatus
    {
        pending,
        confirmed,
        cancelled
    }

}

