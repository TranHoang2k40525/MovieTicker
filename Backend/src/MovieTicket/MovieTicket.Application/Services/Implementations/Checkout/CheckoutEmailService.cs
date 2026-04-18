using MovieTicket.Application.DTOs.Checkout;
using MovieTicket.Application.Services.IServices.ICheckout;
using MovieTicket.Infrastructure.Services.IServices;

namespace MovieTicket.Application.Services.Implementations.Checkout
{
    public class CheckoutEmailService : ICheckoutEmailService
    {
        private readonly IEmailService _emailService;

        public CheckoutEmailService(IEmailService emailService)
        {
            _emailService = emailService;
        }

        public async Task SendBookingSuccessEmailAsync(string toEmail, CheckoutPreviewResponse preview, DateTime paidAtUtc)
        {
            if (string.IsNullOrWhiteSpace(toEmail))
            {
                return;
            }

            var subject = "Bạn đã đặt vé thành công - MovieTicket";
            var body = BuildSuccessEmailHtml(preview, paidAtUtc);
            await _emailService.SendEmailAsync(toEmail, subject, body);
        }

        private static string BuildSuccessEmailHtml(CheckoutPreviewResponse preview, DateTime paidAtUtc)
        {
            return $@"
<h3>Bạn đã đặt vé thành công tại {preview.CinemaName}</h3>
<p>Thời gian đặt vé: {paidAtUtc:dd-MM-yyyy HH:mm}</p>
<p>Thông tin vé:</p>
<ul>
  <li>Phim: {preview.MovieTitle}</li>
  <li>Độ tuổi: {preview.MovieAge}</li>
  <li>Ngày chiếu: {preview.ShowDateLabel}</li>
  <li>Khung giờ: {preview.ShowTimeRangeLabel}</li>
  <li>Phòng: {preview.HallName}</li>
  <li>Ghế: {string.Join(", ", preview.SeatNumbers)}</li>
  <li>Tổng thanh toán: {preview.GrandTotal:N0} đ</li>
</ul>
<p>Cảm ơn bạn đã tin tưởng và lựa chọn rạp chúng tôi.</p>
<p>Chúc quý khách thưởng thức bộ phim trọn vẹn và vui vẻ!</p>";
        }
    }
}