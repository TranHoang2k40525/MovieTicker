
namespace MovieTicket.Domain.Entities
{

    public partial class BookingProduct
    {
        public int BookingProductId { get; set; }

        public int? BookingId { get; set; }

        public int? ProductId { get; set; }

        public int? Quantity { get; set; }

        public decimal? TotalPriceBookingProduct { get; set; }

        public virtual Booking? Booking { get; set; }

        public virtual Product? Product { get; set; }
    }
}