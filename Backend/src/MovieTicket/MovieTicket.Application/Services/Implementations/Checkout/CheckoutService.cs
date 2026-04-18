using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Checkout;
using MovieTicket.Application.Services.IServices.ICheckout;
using MovieTicket.Domain.Entities;
using BookingEntity = MovieTicket.Domain.Entities.Booking;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.IResponsitories.ICheckout;

namespace MovieTicket.Application.Services.Implementations.Checkout
{
    public class CheckoutService : ICheckoutService
    {
        private readonly IUserRepository _userRepository;
        private readonly ICheckoutRepository _checkoutRepository;
        private readonly ICheckoutEmailService _checkoutEmailService;
        private readonly ILogger<CheckoutService> _logger;

        public CheckoutService(
            IUserRepository userRepository,
            ICheckoutRepository checkoutRepository,
            ICheckoutEmailService checkoutEmailService,
            ILogger<CheckoutService> logger)
        {
            _userRepository = userRepository;
            _checkoutRepository = checkoutRepository;
            _checkoutEmailService = checkoutEmailService;
            _logger = logger;
        }

        public async Task<CheckoutPreviewResponse> GetCheckoutPreviewAsync(int accountId, CheckoutPreviewRequest request)
        {
            if (request.HoldId <= 0)
                return Fail("HoldId không hợp lệ");

            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
                return Fail("Không tìm thấy hồ sơ người dùng");

            var booking = await _checkoutRepository.GetBookingForCheckoutAsync(request.HoldId);
            if (booking == null || booking.UserId != user.UserId)
                return Fail("Không tìm thấy dữ liệu giữ ghế");

            if (booking.Status == BookingStatus.cancelled)
                return Fail("Giữ ghế đã bị hủy");

            var now = DateTime.UtcNow;
            var expired = booking.BookingSeats.Any(s => s.Status == BookingSeatStatus.held && s.HoldUntil.HasValue && s.HoldUntil.Value <= now);
            if (expired)
                return Fail("Giữ ghế đã hết hạn");

            var seatTotal = booking.BookingSeats.Sum(x => x.TicketPrice ?? 0m);
            var comboTotal = booking.BookingProducts.Sum(x => x.TotalPriceBookingProduct ?? 0m);
            var subTotal = seatTotal + comboTotal;

            var voucherDiscount = 0m;
            string? appliedVoucherCode = null;

            if (!string.IsNullOrWhiteSpace(request.VoucherCode))
            {
                var voucherResult = await ValidateAndCalculateVoucherAsync(
                    voucherCode: request.VoucherCode!,
                    userId: user.UserId,
                    bookingId: booking.BookingId,
                    baseAmount: subTotal);

                if (!voucherResult.Success)
                    return Fail(voucherResult.Message);

                voucherDiscount = voucherResult.DiscountAmount;
                appliedVoucherCode = voucherResult.Code;
            }

            var totalAfterDiscount = Math.Max(0m, subTotal - voucherDiscount);
            var vatRate = 0.05m;
            var vatAmount = Math.Round(totalAfterDiscount * vatRate, 2, MidpointRounding.AwayFromZero);
            var grandTotal = totalAfterDiscount + vatAmount;

            return BuildPreview(
                booking,
                seatTotal,
                comboTotal,
                subTotal,
                appliedVoucherCode,
                voucherDiscount,
                totalAfterDiscount,
                vatRate,
                vatAmount,
                grandTotal
            );
        }

        public async Task<MockMomoPaymentResponse> MockMomoSuccessAsync(int accountId, MockMomoPaymentRequest request)
        {
            if (request.HoldId <= 0)
                return new MockMomoPaymentResponse { Success = false, Message = "HoldId không hợp lệ" };

            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
                return new MockMomoPaymentResponse { Success = false, Message = "Không tìm thấy hồ sơ người dùng" };

            var booking = await _checkoutRepository.GetBookingForCheckoutAsync(request.HoldId);
            if (booking == null || booking.UserId != user.UserId)
                return new MockMomoPaymentResponse { Success = false, Message = "Không tìm thấy booking" };

            if (booking.Status == BookingStatus.cancelled)
                return new MockMomoPaymentResponse { Success = false, Message = "Booking đã hủy" };

            var existingPayment = booking.Payments
                .OrderByDescending(p => p.PaymentDate)
                .FirstOrDefault();

            if (booking.Status == BookingStatus.confirmed && existingPayment != null)
            {
                var existingPaidAt = existingPayment.PaymentDate ?? DateTime.UtcNow;
                return new MockMomoPaymentResponse
                {
                    Success = true,
                    Message = "Booking đã được thanh toán trước đó",
                    BookingId = booking.BookingId,
                    PaymentId = existingPayment.PaymentId,
                    TicketCode = $"MT-{booking.BookingId}-{existingPaidAt:yyyyMMddHHmmss}",
                    PaidAmount = existingPayment.Amount ?? 0m,
                    PaidAtUtc = existingPaidAt
                };
            }

            var preview = await GetCheckoutPreviewAsync(accountId, new CheckoutPreviewRequest
            {
                HoldId = request.HoldId,
                VoucherCode = request.VoucherCode
            });

            if (!preview.Success)
                return new MockMomoPaymentResponse { Success = false, Message = preview.Message ?? "Không thể xử lý thanh toán" };

            // Chốt ghế + booking thành công sau khi "momo mock success"
            booking.Status = BookingStatus.confirmed;
            foreach (var seat in booking.BookingSeats)
            {
                seat.Status = BookingSeatStatus.booked;
                seat.HoldUntil = null;
            }

            var payment = new Payment
            {
                BookingId = booking.BookingId,
                Amount = preview.GrandTotal,
                PaymentDate = DateTime.UtcNow,
                PaymentMethod = string.IsNullOrWhiteSpace(request.PaymentMethod) ? "momo_mock" : request.PaymentMethod
            };
            await _checkoutRepository.AddPaymentAsync(payment);

            if (!string.IsNullOrWhiteSpace(request.VoucherCode))
            {
                var voucher = await _checkoutRepository.GetVoucherByCodeAsync(request.VoucherCode);
                if (voucher != null)
                {
                    await _checkoutRepository.AddVoucherUsageAsync(new VoucherUsage
                    {
                        BookingId = booking.BookingId,
                        UserId = user.UserId,
                        VoucherId = voucher.VoucherId,
                        UsedAt = DateTime.UtcNow
                    });

                    voucher.UsageCount = voucher.UsageCount.GetValueOrDefault() + 1;
                }
            }

            var message = BuildSuccessMessage(booking, preview);
            await _checkoutRepository.AddNotificationAsync(new Notification
            {
                UserId = user.UserId,
                Message = message,
                DateSent = DateTime.UtcNow,
                IsRead = false
            });

            await _checkoutRepository.SaveChangesAsync();

            // Gửi email sau cùng
            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                await _checkoutEmailService.SendBookingSuccessEmailAsync(
                    user.Email!,
                    preview,
                    payment.PaymentDate ?? DateTime.UtcNow);
            }

            var finalizedPaidAt = payment.PaymentDate ?? DateTime.UtcNow;
            var ticketCode = $"MT-{booking.BookingId}-{finalizedPaidAt:yyyyMMddHHmmss}";

            return new MockMomoPaymentResponse
            {
                Success = true,
                Message = "Giả lập thanh toán MoMo thành công",
                BookingId = booking.BookingId,
                PaymentId = payment.PaymentId,
                TicketCode = ticketCode,
                PaidAmount = preview.GrandTotal,
                PaidAtUtc = finalizedPaidAt
            };
        }

        public async Task<List<VoucherViewDto>> GetAvailableVouchersAsync(int accountId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new List<VoucherViewDto>();
            }

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var vouchers = await _checkoutRepository.GetAvailableVouchersAsync(today);

            var result = new List<VoucherViewDto>(vouchers.Count);
            foreach (var voucher in vouchers)
            {
                var blockedByRestriction = false;
                if (voucher.IsRestricted == true)
                {
                    blockedByRestriction = await _checkoutRepository.HasUserUsedVoucherAsync(
                        user.UserId,
                        voucher.VoucherId,
                        bookingId: 0);
                }

                if (blockedByRestriction)
                {
                    continue;
                }

                result.Add(new VoucherViewDto
                {
                    Code = voucher.Code ?? string.Empty,
                    Title = voucher.Title ?? string.Empty,
                    Description = voucher.Description ?? string.Empty,
                    DiscountValue = voucher.DiscountValue ?? 0m,
                    StartDate = voucher.StartDate,
                    EndDate = voucher.EndDate,
                    ImageVoucher = voucher.ImageVoucher,
                    IsActive = voucher.IsActive ?? false,
                    UsageLimit = voucher.UsageLimit,
                    UsageCount = voucher.UsageCount,
                    IsRestricted = voucher.IsRestricted ?? false
                });
            }

            return result;
        }

        public async Task<VoucherViewDto?> GetVoucherDetailByCodeAsync(string code)
        {
            var voucher = await _checkoutRepository.GetVoucherByCodeAsync(code);
            if (voucher == null) return null;

            return new VoucherViewDto
            {
                Code = voucher.Code ?? string.Empty,
                Title = voucher.Title ?? string.Empty,
                Description = voucher.Description ?? string.Empty,
                DiscountValue = voucher.DiscountValue ?? 0m,
                StartDate = voucher.StartDate,
                EndDate = voucher.EndDate,
                ImageVoucher = voucher.ImageVoucher,
                IsActive = voucher.IsActive ?? false,
                UsageLimit = voucher.UsageLimit,
                UsageCount = voucher.UsageCount,
                IsRestricted = voucher.IsRestricted ?? false
            };
        }

        private async Task<(bool Success, string Message, decimal DiscountAmount, string Code)> ValidateAndCalculateVoucherAsync(
            string voucherCode,
            int userId,
            int bookingId,
            decimal baseAmount)
        {
            var voucher = await _checkoutRepository.GetVoucherByCodeAsync(voucherCode);
            if (voucher == null)
                return (false, "Không tìm thấy voucher", 0m, string.Empty);

            if (voucher.IsActive != true)
                return (false, "Voucher không còn hiệu lực", 0m, string.Empty);

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            if (voucher.StartDate.HasValue && today < voucher.StartDate.Value)
                return (false, "Voucher chưa đến thời gian áp dụng", 0m, string.Empty);

            if (voucher.EndDate.HasValue && today > voucher.EndDate.Value)
                return (false, "Voucher đã hết hạn", 0m, string.Empty);

            if (voucher.UsageLimit.HasValue && voucher.UsageCount.GetValueOrDefault() >= voucher.UsageLimit.Value)
                return (false, "Voucher đã hết lượt sử dụng", 0m, string.Empty);

            if (voucher.IsRestricted == true)
            {
                var used = await _checkoutRepository.HasUserUsedVoucherAsync(userId, voucher.VoucherId, bookingId);
                if (used)
                    return (false, "Bạn đã sử dụng voucher này", 0m, string.Empty);
            }

            var discountValue = voucher.DiscountValue ?? 0m;
            decimal discountAmount;

            // Không có cột voucher type trong entity hiện tại, tạm nhận diện theo mô tả:
            // nếu Description chứa '%' => voucher theo phần trăm, ngược lại là số tiền cố định.
            var isPercent = (voucher.Description ?? string.Empty).Contains("%", StringComparison.OrdinalIgnoreCase);

            if (isPercent)
            {
                discountAmount = Math.Round(baseAmount * (discountValue / 100m), 2, MidpointRounding.AwayFromZero);
            }
            else
            {
                discountAmount = discountValue;
            }

            discountAmount = Math.Min(discountAmount, baseAmount);
            return (true, "OK", discountAmount, voucher.Code ?? string.Empty);
        }

        private static CheckoutPreviewResponse Fail(string message) =>
            new CheckoutPreviewResponse { Success = false, Message = message };

        private static CheckoutPreviewResponse BuildPreview(
            BookingEntity booking,
            decimal seatTotal,
            decimal comboTotal,
            decimal subTotal,
            string? voucherCode,
            decimal discount,
            decimal afterDiscount,
            decimal vatRate,
            decimal vatAmount,
            decimal grandTotal)
        {
            var show = booking.Show;
            var movie = show?.Movie;
            var hall = show?.Hall;
            var cinema = hall?.Cinema;

            var date = show?.ShowDate;
            var time = show?.ShowTime;
            var runtime = movie?.MovieRuntime ?? 0;
            var endTime = (time ?? new TimeOnly(0, 0)).AddMinutes(runtime);

            var dateLabel = date.HasValue
                ? $"{GetVietnameseDayName(date.Value.DayOfWeek)}, {date.Value:dd-MM-yy}"
                : string.Empty;

            var timeRangeLabel = (date.HasValue && time.HasValue)
                ? $"{date.Value:dd-MM-yy} {time.Value:HH:mm}~{endTime:HH:mm}"
                : string.Empty;

            return new CheckoutPreviewResponse
            {
                Success = true,
                Message = "Lấy thông tin vé thành công",
                BookingId = booking.BookingId,
                MovieTitle = movie?.MovieTitle ?? string.Empty,
                MovieAge = movie?.MovieAge ?? string.Empty,
                ShowDateLabel = dateLabel,
                ShowTimeRangeLabel = timeRangeLabel,
                CinemaName = cinema?.CinemaName ?? string.Empty,
                HallName = hall?.HallName ?? string.Empty,
                SeatNumbers = booking.BookingSeats
                    .OrderBy(x => x.Seat?.SeatNumber)
                    .Select(x => x.Seat?.SeatNumber ?? string.Empty)
                    .Where(x => !string.IsNullOrWhiteSpace(x))
                    .ToList(),
                SeatCount = booking.BookingSeats.Count,
                SeatTotal = seatTotal,
                ComboTotal = comboTotal,
                SubTotalBeforeDiscount = subTotal,
                AppliedVoucherCode = voucherCode,
                VoucherDiscount = discount,
                TotalAfterDiscount = afterDiscount,
                VatRate = vatRate,
                VatAmount = vatAmount,
                GrandTotal = grandTotal
            };
        }

        private static string GetVietnameseDayName(DayOfWeek dayOfWeek) =>
            dayOfWeek switch
            {
                DayOfWeek.Monday => "Thứ hai",
                DayOfWeek.Tuesday => "Thứ ba",
                DayOfWeek.Wednesday => "Thứ tư",
                DayOfWeek.Thursday => "Thứ năm",
                DayOfWeek.Friday => "Thứ sáu",
                DayOfWeek.Saturday => "Thứ bảy",
                _ => "Chủ nhật"
            };

        private static string BuildSuccessMessage(BookingEntity booking, CheckoutPreviewResponse preview)
        {
            var now = DateTime.UtcNow;
            return
                $"Bạn đã đặt vé thành công tại {preview.CinemaName}. " +
                $"Thời gian đặt vé: {now:dd-MM-yyyy HH:mm}. " +
                $"Phim: {preview.MovieTitle}, suất: {preview.ShowTimeRangeLabel}, ghế: {string.Join(", ", preview.SeatNumbers)}.";
        }

    }
}