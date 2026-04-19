namespace MovieTicket.Application.DTOs.Ticket
{
    public class MyTicketItemDto
    {
        public int BookingId { get; set; }
        public string TicketCode { get; set; } = string.Empty;
        public string MovieTitle { get; set; } = string.Empty;
        public string MovieImageUrl { get; set; } = string.Empty;
        public string CinemaName { get; set; } = string.Empty;
        public DateOnly? ShowDate { get; set; }
        public string ShowTime { get; set; } = string.Empty;
        public decimal TotalPrice { get; set; }
        public bool IsExpired { get; set; }
        public string StatusLabel { get; set; } = string.Empty;
    }

    public class MyTicketDetailDto
    {
        public int BookingId { get; set; }
        public string TicketCode { get; set; } = string.Empty;
        public string MovieTitle { get; set; } = string.Empty;
        public string MovieImageUrl { get; set; } = string.Empty;
        public string MovieAge { get; set; } = string.Empty;
        public string CinemaName { get; set; } = string.Empty;
        public string CinemaAddress { get; set; } = string.Empty;
        public string HallName { get; set; } = string.Empty;
        public DateOnly? ShowDate { get; set; }
        public string ShowTime { get; set; } = string.Empty;
        public bool IsExpired { get; set; }
        public string StatusLabel { get; set; } = string.Empty;

        public List<TicketSeatDto> Seats { get; set; } = new();
        public decimal SeatTotal { get; set; }
        public decimal ComboTotal { get; set; }
        public decimal VoucherDiscount { get; set; }
        public decimal VatRate { get; set; }
        public decimal VatAmount { get; set; }
        public decimal GrandTotal { get; set; }

        public string BarcodeValue { get; set; } = string.Empty;
        public string SerialNumber { get; set; } = string.Empty;
    }

    public class MyTicketHistoryItemDto
    {
        public int BookingId { get; set; }
        public string TicketCode { get; set; } = string.Empty;
        public string SerialNumber { get; set; } = string.Empty;
        public string MovieTitle { get; set; } = string.Empty;
        public string CinemaName { get; set; } = string.Empty;
        public DateOnly? ShowDate { get; set; }
        public string ShowTime { get; set; } = string.Empty;
        public DateTime? PaymentDate { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public bool IsExpired { get; set; }
        public string StatusLabel { get; set; } = string.Empty;
    }

    public class UserNotificationItemDto
    {
        public string NotificationId { get; set; } = string.Empty;
        public int? BookingId { get; set; }
        public string Channel { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public bool IsRead { get; set; }
    }

    public class TicketSeatDto
    {
        public string SeatNumber { get; set; } = string.Empty;
        public string SeatClass { get; set; } = string.Empty;
        public decimal TicketPrice { get; set; }
    }
}
