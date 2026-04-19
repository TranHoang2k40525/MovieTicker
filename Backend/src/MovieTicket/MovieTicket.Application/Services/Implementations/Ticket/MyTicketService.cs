using MovieTicket.Application.DTOs.Ticket;
using MovieTicket.Application.Services.IServices.ITicket;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.IResponsitories.ITicket;
using System.IO;

namespace MovieTicket.Application.Services.Implementations.Ticket
{
    public class MyTicketService : IMyTicketService
    {
        private const decimal DefaultVatRate = 0.05m;
        private static readonly TimeZoneInfo VietnamTimeZone = ResolveVietnamTimeZone();

        private readonly IUserRepository _userRepository;
        private readonly ITicketRepository _ticketRepository;

        public MyTicketService(IUserRepository userRepository, ITicketRepository ticketRepository)
        {
            _userRepository = userRepository;
            _ticketRepository = ticketRepository;
        }

        public async Task<List<MyTicketItemDto>> GetMyTicketsAsync(int accountId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new List<MyTicketItemDto>();
            }

            var bookings = await _ticketRepository.GetConfirmedBookingsByUserAsync(user.UserId);
            var now = DateTime.UtcNow;

            return bookings.Select(booking =>
            {
                var payment = booking.Payments.OrderByDescending(x => x.PaymentDate).FirstOrDefault();
                var showDateTime = BuildShowDateTime(booking.Show?.ShowDate, booking.Show?.ShowTime);
                var isExpired = showDateTime.HasValue && showDateTime.Value <= now;

                return new MyTicketItemDto
                {
                    BookingId = booking.BookingId,
                    TicketCode = BuildTicketCode(booking.BookingId, payment?.PaymentId, payment?.PaymentDate),
                    MovieTitle = booking.Show?.Movie?.MovieTitle ?? string.Empty,
                    MovieImageUrl = BuildMovieImageUrl(booking.Show?.Movie?.ImageUrl),
                    CinemaName = booking.Show?.Hall?.Cinema?.CinemaName ?? string.Empty,
                    ShowDate = booking.Show?.ShowDate,
                    ShowTime = booking.Show?.ShowTime?.ToString("HH:mm") ?? string.Empty,
                    TotalPrice = payment?.Amount ?? 0m,
                    IsExpired = isExpired,
                    StatusLabel = isExpired ? "Đã sử dụng / Hết hạn" : "Sắp chiếu"
                };
            }).ToList();
        }

        public async Task<List<MyTicketHistoryItemDto>> GetMyTicketHistoryAsync(int accountId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new List<MyTicketHistoryItemDto>();
            }

            var bookings = await _ticketRepository.GetTicketHistoryByUserAsync(user.UserId);
            var now = DateTime.UtcNow;

            return bookings.Select(booking =>
            {
                var payment = booking.Payments.OrderByDescending(x => x.PaymentDate).FirstOrDefault();
                var showDateTime = BuildShowDateTime(booking.Show?.ShowDate, booking.Show?.ShowTime);
                var isExpired = showDateTime.HasValue && showDateTime.Value <= now;

                return new MyTicketHistoryItemDto
                {
                    BookingId = booking.BookingId,
                    TicketCode = BuildTicketCode(booking.BookingId, payment?.PaymentId, payment?.PaymentDate),
                    SerialNumber = BuildSerialNumber(booking.BookingId, payment?.PaymentId, payment?.PaymentDate),
                    MovieTitle = booking.Show?.Movie?.MovieTitle ?? string.Empty,
                    CinemaName = booking.Show?.Hall?.Cinema?.CinemaName ?? string.Empty,
                    ShowDate = booking.Show?.ShowDate,
                    ShowTime = booking.Show?.ShowTime?.ToString("HH:mm") ?? string.Empty,
                    PaymentDate = payment?.PaymentDate,
                    PaymentMethod = payment?.PaymentMethod ?? string.Empty,
                    Amount = payment?.Amount ?? 0m,
                    IsExpired = isExpired,
                    StatusLabel = isExpired ? "Đã sử dụng / Hết hạn" : "Đã thanh toán"
                };
            }).ToList();
        }

        public async Task<MyTicketDetailDto?> GetMyTicketDetailAsync(int accountId, int bookingId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return null;
            }

            var booking = await _ticketRepository.GetConfirmedBookingDetailAsync(bookingId, user.UserId);
            if (booking == null)
            {
                return null;
            }

            var payment = booking.Payments.OrderByDescending(x => x.PaymentDate).FirstOrDefault();
            var seatTotal = booking.BookingSeats.Sum(x => x.TicketPrice ?? 0m);
            var comboTotal = booking.BookingProducts.Sum(x => x.TotalPriceBookingProduct ?? 0m);
            var voucherDiscount = await _ticketRepository.GetVoucherDiscountByBookingAsync(booking.BookingId);
            var subTotal = Math.Max(0m, seatTotal + comboTotal - voucherDiscount);
            var vatAmount = Math.Round(subTotal * DefaultVatRate, 2, MidpointRounding.AwayFromZero);
            var computedGrandTotal = subTotal + vatAmount;
            var grandTotal = payment?.Amount ?? computedGrandTotal;

            var showDateTime = BuildShowDateTime(booking.Show?.ShowDate, booking.Show?.ShowTime);
            var isExpired = showDateTime.HasValue && showDateTime.Value <= DateTime.UtcNow;

            var ticketCode = BuildTicketCode(booking.BookingId, payment?.PaymentId, payment?.PaymentDate);
            var serialNumber = BuildSerialNumber(booking.BookingId, payment?.PaymentId, payment?.PaymentDate);
            var barcodeValue = BuildBarcodeValue(serialNumber);

            return new MyTicketDetailDto
            {
                BookingId = booking.BookingId,
                TicketCode = ticketCode,
                MovieTitle = booking.Show?.Movie?.MovieTitle ?? string.Empty,
                MovieImageUrl = BuildMovieImageUrl(booking.Show?.Movie?.ImageUrl),
                MovieAge = booking.Show?.Movie?.MovieAge ?? string.Empty,
                CinemaName = booking.Show?.Hall?.Cinema?.CinemaName ?? string.Empty,
                CinemaAddress = booking.Show?.Hall?.Cinema?.CityAddress ?? string.Empty,
                HallName = booking.Show?.Hall?.HallName ?? string.Empty,
                ShowDate = booking.Show?.ShowDate,
                ShowTime = booking.Show?.ShowTime?.ToString("HH:mm") ?? string.Empty,
                IsExpired = isExpired,
                StatusLabel = isExpired ? "Đã sử dụng / Hết hạn" : "Sắp chiếu",
                Seats = booking.BookingSeats
                    .OrderBy(x => x.Seat?.SeatNumber)
                    .Select(x => new TicketSeatDto
                    {
                        SeatNumber = x.Seat?.SeatNumber ?? string.Empty,
                        SeatClass = MapSeatClass(x.Seat?.SeatType),
                        TicketPrice = x.TicketPrice ?? 0m
                    }).ToList(),
                SeatTotal = seatTotal,
                ComboTotal = comboTotal,
                VoucherDiscount = voucherDiscount,
                VatRate = DefaultVatRate,
                VatAmount = vatAmount,
                GrandTotal = grandTotal,
                BarcodeValue = barcodeValue,
                SerialNumber = serialNumber
            };
        }

        public async Task<List<UserNotificationItemDto>> GetMyNotificationsAsync(int accountId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new List<UserNotificationItemDto>();
            }

            var bookings = await _ticketRepository.GetTicketHistoryByUserAsync(user.UserId);
            var now = DateTime.UtcNow;
            var upcomingThreshold = now.AddHours(24);
            var notifications = new List<UserNotificationItemDto>();

            foreach (var booking in bookings)
            {
                var payment = booking.Payments.OrderByDescending(x => x.PaymentDate).FirstOrDefault();
                var showDateTime = BuildShowDateTime(booking.Show?.ShowDate, booking.Show?.ShowTime);
                var movieTitle = booking.Show?.Movie?.MovieTitle ?? "Phim";
                var cinemaName = booking.Show?.Hall?.Cinema?.CinemaName ?? "Rạp";
                var showDateLabel = booking.Show?.ShowDate?.ToString("yyyy-MM-dd") ?? "N/A";
                var showTimeLabel = booking.Show?.ShowTime?.ToString("HH:mm") ?? "N/A";
                var paidAt = payment?.PaymentDate?.ToUniversalTime() ?? now;
                var ticketCode = BuildTicketCode(booking.BookingId, payment?.PaymentId, payment?.PaymentDate);

                notifications.Add(new UserNotificationItemDto
                {
                    NotificationId = $"booking-success-{booking.BookingId}-{payment?.PaymentId ?? 0}",
                    BookingId = booking.BookingId,
                    Channel = "inbox",
                    Type = "booking_success",
                    Title = "Đặt vé thành công",
                    Message = $"Bạn đã đặt thành công vé {ticketCode} cho phim {movieTitle} tại {cinemaName}.",
                    CreatedAt = paidAt,
                    IsRead = false
                });

                if (showDateTime.HasValue && showDateTime.Value > now && showDateTime.Value <= upcomingThreshold)
                {
                    notifications.Add(new UserNotificationItemDto
                    {
                        NotificationId = $"showtime-reminder-{booking.BookingId}-{payment?.PaymentId ?? 0}",
                        BookingId = booking.BookingId,
                        Channel = "notification",
                        Type = "showtime_reminder",
                        Title = "Suất chiếu sắp diễn ra",
                        Message = $"{movieTitle} sẽ chiếu lúc {showTimeLabel} ngày {showDateLabel}. Vui lòng đến sớm 15 phút.",
                        CreatedAt = showDateTime.Value.AddHours(-2),
                        IsRead = false
                    });
                }

                if (showDateTime.HasValue && showDateTime.Value <= now)
                {
                    notifications.Add(new UserNotificationItemDto
                    {
                        NotificationId = $"ticket-used-{booking.BookingId}-{payment?.PaymentId ?? 0}",
                        BookingId = booking.BookingId,
                        Channel = "notification",
                        Type = "ticket_used",
                        Title = "Thông tin vé đã cập nhật",
                        Message = $"Vé {ticketCode} của phim {movieTitle} đã được chuyển trạng thái đã sử dụng/hết hạn.",
                        CreatedAt = showDateTime.Value.AddHours(1),
                        IsRead = false
                    });
                }
            }

            return notifications
                .OrderByDescending(x => x.CreatedAt)
                .ToList();
        }

        private static DateTime? BuildShowDateTime(DateOnly? showDate, TimeOnly? showTime)
        {
            if (!showDate.HasValue || !showTime.HasValue)
            {
                return null;
            }

            var localVietnamTime = showDate.Value.ToDateTime(showTime.Value, DateTimeKind.Unspecified);
            return TimeZoneInfo.ConvertTimeToUtc(localVietnamTime, VietnamTimeZone);
        }

        private static string BuildTicketCode(int bookingId, int? paymentId, DateTime? paidAt)
        {
            var stamp = BuildStableTimestamp(paidAt);
            var paymentPart = paymentId.GetValueOrDefault(0).ToString("D4");
            return $"MT-{bookingId:D6}-{paymentPart}-{stamp}";
        }

        private static string BuildSerialNumber(int bookingId, int? paymentId, DateTime? paidAt)
        {
            var stamp = BuildStableTimestamp(paidAt);
            return $"SERI-{stamp}-{bookingId:D6}-{paymentId.GetValueOrDefault(0):D4}";
        }

        private static string BuildBarcodeValue(string serialNumber)
        {
            return serialNumber;
        }

        private static string BuildStableTimestamp(DateTime? input)
        {
            return input?.ToUniversalTime().ToString("yyyyMMddHHmmss") ?? "00000000000000";
        }

        private static string BuildMovieImageUrl(string? imageUrl)
        {
            if (string.IsNullOrWhiteSpace(imageUrl)) return string.Empty;
            if (imageUrl.StartsWith("http", StringComparison.OrdinalIgnoreCase)) return imageUrl;

            var fileName = Path.GetFileName(imageUrl);
            return $"/assets/Images/MOVIE/{fileName}";
        }

        private static string MapSeatClass(SeatType? seatType)
        {
            return seatType switch
            {
                SeatType.VIP => "VIP",
                SeatType.Couple => "Sweet Box",
                _ => "Thường"
            };
        }

        private static TimeZoneInfo ResolveVietnamTimeZone()
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time");
            }
            catch (TimeZoneNotFoundException)
            {
                return TimeZoneInfo.FindSystemTimeZoneById("Asia/Ho_Chi_Minh");
            }
        }
    }
}
