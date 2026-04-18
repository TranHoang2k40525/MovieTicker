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

    public class ConfirmSeatBookingRequest
    {
        public int HoldId { get; set; }
        public List<int> ProductIds { get; set; } = new();
    }

    public class ConfirmSeatBookingResponse
    {
        public bool Success { get; set; }
        public int BookingId { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}