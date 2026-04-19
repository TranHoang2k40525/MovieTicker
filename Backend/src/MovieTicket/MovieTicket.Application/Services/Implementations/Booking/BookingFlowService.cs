using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Booking;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Domain.Entities;
using BookingEntity = MovieTicket.Domain.Entities.Booking;
using BookingSeatEntity = MovieTicket.Domain.Entities.BookingSeat;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.IResponsitories.IBooking;
using MovieTicket.Domain.IResponsitories.IProduct;

namespace MovieTicket.Application.Services.Implementations.Booking
{
    public class BookingFlowService : IBookingFlowService
    {
        private const int SeatHoldMinutes = 2;
        private const int PaymentGraceMinutes = 1;

        private readonly IBookingRepository _bookingRepository;
        private readonly ISeatMapRepository _seatMapRepository;
        private readonly IUserRepository _userRepository;
        private readonly IProductRepository _productRepository;
        private readonly ISeatRealtimePublisher _seatRealtimePublisher;
        private readonly ILogger<BookingFlowService> _logger;

        public BookingFlowService(
            IBookingRepository bookingRepository,
            ISeatMapRepository seatMapRepository,
            IUserRepository userRepository,
            IProductRepository productRepository,
            ISeatRealtimePublisher seatRealtimePublisher,
            ILogger<BookingFlowService> logger)
        {
            _bookingRepository = bookingRepository;
            _seatMapRepository = seatMapRepository;
            _userRepository = userRepository;
            _productRepository = productRepository;
            _seatRealtimePublisher = seatRealtimePublisher;
            _logger = logger;
        }

        public async Task<StartSeatHoldResponse> StartSeatHoldAsync(int accountId, StartSeatHoldRequest request)
        {
            var seatIds = request.SeatIds ?? new List<int>();
            if (request.ShowId <= 0 || seatIds.Count == 0)
            {
                return new StartSeatHoldResponse
                {
                    Success = false,
                    Message = "Thiếu suất chiếu hoặc ghế cần giữ"
                };
            }

            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new StartSeatHoldResponse
                {
                    Success = false,
                    Message = "Không tìm thấy hồ sơ người dùng"
                };
            }

            var show = await _seatMapRepository.GetShowContextAsync(request.ShowId);
            if (show?.HallId == null)
            {
                return new StartSeatHoldResponse
                {
                    Success = false,
                    Message = "Không tìm thấy suất chiếu"
                };
            }

            var seats = await _seatMapRepository.GetSeatsByHallAsync(show.HallId.Value);
            var seatsById = seats.ToDictionary(x => x.SeatId);
            var bookingSeats = await _seatMapRepository.GetBookingSeatsByShowAsync(request.ShowId);
            var now = DateTime.UtcNow;
            var normalizedSeatIds = NormalizeSeatSelection(seatIds, seatsById);

            var blockedSeatIds = normalizedSeatIds
                .Where(seatId => IsSeatBlocked(seatId, bookingSeats, now))
                .ToList();

            if (blockedSeatIds.Count > 0)
            {
                return new StartSeatHoldResponse
                {
                    Success = false,
                    Message = "Một hoặc nhiều ghế đã được giữ hoặc đã đặt",
                    SeatIds = blockedSeatIds
                };
            }

            var booking = new BookingEntity
            {
                UserId = user.UserId,
                ShowId = request.ShowId,
                TotalSeats = normalizedSeatIds.Count,
                Status = BookingStatus.pending
            };

            foreach (var seatId in normalizedSeatIds)
            {
                var seat = seatsById[seatId];
                booking.BookingSeats.Add(new BookingSeatEntity
                {
                    SeatId = seat.SeatId,
                    ShowId = request.ShowId,
                    Status = BookingSeatStatus.held,
                    HoldUntil = now.AddMinutes(SeatHoldMinutes),
                    TicketPrice = seat.SeatPrice
                });
            }

            await _bookingRepository.AddAsync(booking);
            await _bookingRepository.SaveChangesAsync();
            await _seatRealtimePublisher.PublishHeldAsync(
                request.ShowId,
                booking.BookingId,
                normalizedSeatIds,
                now.AddMinutes(SeatHoldMinutes));

            _logger.LogInformation(
                "Đã tạo hold bookingId={BookingId}, accountId={AccountId}, showId={ShowId}, seats={SeatCount}",
                booking.BookingId,
                accountId,
                request.ShowId,
                normalizedSeatIds.Count);

            return new StartSeatHoldResponse
            {
                Success = true,
                HoldId = booking.BookingId,
                ExpiresAtUtc = now.AddMinutes(SeatHoldMinutes),
                SeatIds = normalizedSeatIds,
                Message = "Giữ ghế thành công"
            };
        }

        public async Task<ConfirmSeatBookingResponse> ConfirmSeatBookingAsync(int accountId, ConfirmSeatBookingRequest request)
        {
            if (request.HoldId <= 0)
            {
                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "HoldId không hợp lệ"
                };
            }

            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "Không tìm thấy hồ sơ người dùng"
                };
            }

            var booking = await _bookingRepository.GetByIdWithDetailsAsync(request.HoldId);
            if (booking == null)
            {
                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "Không tìm thấy giữ ghế"
                };
            }

            if (booking.UserId != user.UserId)
            {
                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "Giữ ghế không thuộc tài khoản hiện tại"
                };
            }

            if (booking.Status != BookingStatus.pending)
            {
                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "Giữ ghế đã được xử lý"
                };
            }

            var now = DateTime.UtcNow;
            var expired = booking.BookingSeats.Any(s =>
                s.Status == BookingSeatStatus.held &&
                s.HoldUntil.HasValue &&
                s.HoldUntil.Value <= now);

            if (expired)
            {
                ReleaseBookingInternal(booking);
                await _bookingRepository.SaveChangesAsync();

                return new ConfirmSeatBookingResponse
                {
                    Success = false,
                    Message = "Hết thời gian giữ ghế"
                };
            }

            var products = NormalizeProducts(request.Products ?? new List<ConfirmBookingProductDto>());

            booking.BookingProducts.Clear();
            foreach (var item in products)
            {
                var product = await _productRepository.GetProductByIdAsync(item.ProductId);
                if (product == null)
                {
                    return new ConfirmSeatBookingResponse
                    {
                        Success = false,
                        Message = $"Không tìm thấy sản phẩm {item.ProductId}"
                    };
                }

                booking.BookingProducts.Add(new BookingProduct
                {
                    ProductId = product.ProductId,
                    Quantity = item.Quantity,
                    TotalPriceBookingProduct = (product.ProductPrice ?? 0m) * item.Quantity
                });
            }

            var paymentHoldUntil = now.AddMinutes(PaymentGraceMinutes);
            foreach (var bookingSeat in booking.BookingSeats)
            {
                bookingSeat.Status = BookingSeatStatus.held;
                bookingSeat.HoldUntil = paymentHoldUntil;
            }

            booking.Status = BookingStatus.pending;
            booking.TotalSeats = booking.BookingSeats.Count;
            await _bookingRepository.SaveChangesAsync();
            if (booking.ShowId.HasValue)
            {
                var seatIds = booking.BookingSeats
                    .Where(x => x.SeatId.HasValue)
                    .Select(x => x.SeatId!.Value)
                    .Distinct()
                    .ToList();

                await _seatRealtimePublisher.PublishHeldAsync(
                    booking.ShowId.Value,
                    booking.BookingId,
                    seatIds,
                    paymentHoldUntil);
            }

            _logger.LogInformation(
                "Đã xác nhận bookingId={BookingId}, accountId={AccountId}, productCount={ProductCount}",
                booking.BookingId,
                accountId,
                products.Count);

            return new ConfirmSeatBookingResponse
            {
                Success = true,
                BookingId = booking.BookingId,
                Message = "Đã lưu combo, vui lòng thanh toán"
            };
        }

        public async Task<bool> ReleaseExpiredHoldsAsync()
        {
            var now = DateTime.UtcNow;
            var expiredBookings = await _bookingRepository.GetExpiredPendingHoldsAsync(now);

            if (expiredBookings.Count == 0)
            {
                return false;
            }

            foreach (var booking in expiredBookings)
            {
                var seatIds = booking.BookingSeats
                    .Where(x => x.SeatId.HasValue)
                    .Select(x => x.SeatId!.Value)
                    .Distinct()
                    .ToList();
                var showId = booking.ShowId.GetValueOrDefault();

                ReleaseBookingInternal(booking);

                if (showId > 0 && seatIds.Count > 0)
                {
                    await _seatRealtimePublisher.PublishReleasedAsync(showId, booking.BookingId, seatIds, "hold_expired");
                }
            }

            await _bookingRepository.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ReleaseHoldAsync(int accountId, int holdId)
        {
            var user = await _userRepository.GetByAccountIdAsync(accountId);
            if (user == null)
            {
                return false;
            }

            var booking = await _bookingRepository.GetByIdWithDetailsAsync(holdId);
            if (booking == null || booking.UserId != user.UserId || booking.Status != BookingStatus.pending)
            {
                return false;
            }

            var seatIds = booking.BookingSeats
                .Where(x => x.SeatId.HasValue)
                .Select(x => x.SeatId!.Value)
                .Distinct()
                .ToList();
            var showId = booking.ShowId.GetValueOrDefault();

            ReleaseBookingInternal(booking);
            await _bookingRepository.SaveChangesAsync();

            if (showId > 0 && seatIds.Count > 0)
            {
                await _seatRealtimePublisher.PublishReleasedAsync(showId, booking.BookingId, seatIds, "user_cancelled");
            }
            return true;
        }

        private static List<int> NormalizeSeatSelection(
            List<int> selectedSeatIds,
            IDictionary<int, CinemaHallSeat> seatsById)
        {
            var normalized = new HashSet<int>();

            foreach (var seatId in selectedSeatIds.Distinct())
            {
                if (!seatsById.TryGetValue(seatId, out var seat))
                {
                    throw new InvalidOperationException($"Ghế {seatId} không tồn tại trong phòng chiếu");
                }

                normalized.Add(seatId);

                if (seat.SeatType == SeatType.Couple)
                {
                    if (!TryResolveCouplePairSeat(seat, seatsById, out var pairSeat))
                    {
                        throw new InvalidOperationException($"Ghế đôi {seatId} cấu hình cặp không hợp lệ");
                    }

                    normalized.Add(pairSeat!.SeatId);
                }
            }

            return normalized.ToList();
        }

        private static bool TryResolveCouplePairSeat(
            CinemaHallSeat seat,
            IDictionary<int, CinemaHallSeat> seatsById,
            out CinemaHallSeat? pairSeat)
        {
            pairSeat = null;

            // Ưu tiên cấu hình PairId nếu có và hợp lệ.
            if (seat.PairId.HasValue &&
                seatsById.TryGetValue(seat.PairId.Value, out var configuredPair) &&
                configuredPair.SeatType == SeatType.Couple)
            {
                pairSeat = configuredPair;
                return true;
            }

            // Fallback cho dữ liệu import một chiều: suy luận ghế liền kề cùng hàng.
            if (seat.ColSeat.HasValue && !string.IsNullOrWhiteSpace(seat.RowSeat))
            {
                var currentCol = seat.ColSeat.Value;
                var currentRow = seat.RowSeat.Trim();

                pairSeat = seatsById.Values
                    .Where(s =>
                        s.SeatId != seat.SeatId &&
                        s.SeatType == SeatType.Couple &&
                        s.ColSeat.HasValue &&
                        !string.IsNullOrWhiteSpace(s.RowSeat) &&
                        string.Equals(s.RowSeat!.Trim(), currentRow, StringComparison.OrdinalIgnoreCase) &&
                        Math.Abs(s.ColSeat!.Value - currentCol) == 1)
                    .OrderBy(s => Math.Abs(s.ColSeat!.Value - currentCol))
                    .FirstOrDefault();

                if (pairSeat != null)
                {
                    return true;
                }
            }

            return false;
        }

        private static bool IsSeatBlocked(int seatId, IEnumerable<BookingSeat> bookingSeats, DateTime utcNow)
        {
            return bookingSeats.Any(x =>
                x.SeatId == seatId &&
                (
                    x.Status == BookingSeatStatus.booked ||
                    (
                        x.Status == BookingSeatStatus.held &&
                        x.HoldUntil.HasValue &&
                        x.HoldUntil.Value > utcNow
                    )
                ));
        }

        private static List<ConfirmBookingProductDto> NormalizeProducts(List<ConfirmBookingProductDto> products)
        {
            return products
                .Where(x => x.ProductId > 0 && x.Quantity > 0)
                .GroupBy(x => x.ProductId)
                .Select(g => new ConfirmBookingProductDto
                {
                    ProductId = g.Key,
                    Quantity = g.Sum(x => x.Quantity)
                })
                .ToList();
        }

        private static void ReleaseBookingInternal(BookingEntity booking)
        {
            booking.Status = BookingStatus.cancelled;

            foreach (var bookingSeat in booking.BookingSeats)
            {
                bookingSeat.Status = BookingSeatStatus.available;
                bookingSeat.HoldUntil = null;
            }
        }
    }
}
