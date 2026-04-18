// Backend/src/MovieTicket/MovieTicket.Application/DTOs/Booking/StartSeatHoldDto.cs
namespace MovieTicket.Application.DTOs.Booking
{
    public class StartSeatHoldRequest
    {
        public int ShowId { get; set; }
        public List<int> SeatIds { get; set; } = new();
    }

    public class StartSeatHoldResponse
    {
        public bool Success { get; set; }
        public int HoldId { get; set; }
        public DateTime ExpiresAtUtc { get; set; }
        public List<int> SeatIds { get; set; } = new();
        public string Message { get; set; } = string.Empty;
    }

    public class ConfirmBookingProductDto
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; } = 1;
    }

    public class ConfirmSeatBookingRequest
    {
        public int HoldId { get; set; }
        public List<ConfirmBookingProductDto> Products { get; set; } = new();
    }

    public class ConfirmSeatBookingResponse
    {
        public bool Success { get; set; }
        public int BookingId { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}