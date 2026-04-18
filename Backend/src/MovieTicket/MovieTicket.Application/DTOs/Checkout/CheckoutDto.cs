using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Application.DTOs.Checkout
{
    public class CheckoutPreviewRequest
    {
        public int HoldId { get; set; }
        public string? VoucherCode { get; set; } 

    }
    public class CheckoutPreviewResponse
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public int BookingId { get; set; }
        public string MovieTitle { get; set; } = string.Empty;
        public string MovieAge { get; set; } = string.Empty;
        public string ShowDateLabel { get; set; } = string.Empty;      // Ví dụ: Chủ nhật, 05-04-26
        public string ShowTimeRangeLabel { get; set; } = string.Empty; // Ví dụ: 05-04-26 20:15~22:30
        public string CinemaName { get; set; } = string.Empty;
        public string HallName { get; set; } = string.Empty;
        public List<string> SeatNumbers { get; set; } = new();

        public int SeatCount { get; set; }
        public decimal SeatTotal { get; set; }
        public decimal ComboTotal { get; set; }
        public decimal SubTotalBeforeDiscount { get; set; }

        public string? AppliedVoucherCode { get; set; }
        public decimal VoucherDiscount { get; set; }
        public decimal TotalAfterDiscount { get; set; }

        public decimal VatRate { get; set; } = 0.05m;
        public decimal VatAmount { get; set; }
        public decimal GrandTotal { get; set; } // total final để thanh toán
    }
    public class MockMomoPaymentRequest
    {
        public int HoldId { get; set; }
        public string? VoucherCode { get; set; }
        public string PaymentMethod { get; set; } = "momo_mock";
    }
    public class MockMomoPaymentResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int BookingId { get; set; }
        public int PaymentId { get; set; }
        public string TicketCode { get; set; } = string.Empty;
        public decimal PaidAmount { get; set; }
        public DateTime PaidAtUtc { get; set; }
    }
    public class VoucherViewDto
    {
        public string Code { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal DiscountValue { get; set; }
        public DateOnly? StartDate { get; set; }
        public DateOnly? EndDate { get; set; }
        public string? ImageVoucher { get; set; }
        public bool IsActive { get; set; }
        public int? UsageLimit { get; set; }
        public int? UsageCount { get; set; }
        public bool IsRestricted { get; set; }
    }
}
