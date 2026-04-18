using MovieTicket.Application.DTOs.Checkout;

namespace MovieTicket.Application.Services.IServices.ICheckout
{
    public interface ICheckoutEmailService
    {
        Task SendBookingSuccessEmailAsync(string toEmail, CheckoutPreviewResponse preview, DateTime paidAtUtc);
    }
}