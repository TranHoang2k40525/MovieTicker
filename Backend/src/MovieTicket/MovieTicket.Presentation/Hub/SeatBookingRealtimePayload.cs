namespace MovieTicket.Presentation.Hub
{
    public class SeatBookingRealtimePayload
    {
        public int ShowId { get; set; }
        public int HoldId { get; set; }
        public string State { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public DateTime? ExpiresAtUtc { get; set; }
        public List<int> SeatIds { get; set; } = new();
        public DateTime OccurredAtUtc { get; set; }
    }
}
