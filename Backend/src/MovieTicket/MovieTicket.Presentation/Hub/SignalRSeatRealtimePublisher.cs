using Microsoft.AspNetCore.SignalR;
using MovieTicket.Application.Services.IServices.IBooking;

namespace MovieTicket.Presentation.Hub
{
    public class SignalRSeatRealtimePublisher : ISeatRealtimePublisher
    {
        private readonly IHubContext<SeatBookingHub> _hubContext;

        public SignalRSeatRealtimePublisher(IHubContext<SeatBookingHub> hubContext)
        {
            _hubContext = hubContext;
        }

        public Task PublishHeldAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, DateTime expiresAtUtc, CancellationToken cancellationToken = default)
        {
            var payload = new SeatBookingRealtimePayload
            {
                ShowId = showId,
                HoldId = holdId,
                State = "held",
                ExpiresAtUtc = expiresAtUtc,
                SeatIds = seatIds.Distinct().OrderBy(x => x).ToList(),
                OccurredAtUtc = DateTime.UtcNow,
                Reason = "hold_started"
            };

            return _hubContext.Clients.Group(SeatBookingHub.BuildRoomName(showId)).SendAsync("SeatStateChanged", payload, cancellationToken);
        }

        public Task PublishBookedAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, CancellationToken cancellationToken = default)
        {
            var payload = new SeatBookingRealtimePayload
            {
                ShowId = showId,
                HoldId = holdId,
                State = "booked",
                SeatIds = seatIds.Distinct().OrderBy(x => x).ToList(),
                OccurredAtUtc = DateTime.UtcNow,
                Reason = "payment_success"
            };

            return _hubContext.Clients.Group(SeatBookingHub.BuildRoomName(showId)).SendAsync("SeatStateChanged", payload, cancellationToken);
        }

        public Task PublishReleasedAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, string reason, CancellationToken cancellationToken = default)
        {
            var payload = new SeatBookingRealtimePayload
            {
                ShowId = showId,
                HoldId = holdId,
                State = "available",
                SeatIds = seatIds.Distinct().OrderBy(x => x).ToList(),
                OccurredAtUtc = DateTime.UtcNow,
                Reason = reason
            };

            return _hubContext.Clients.Group(SeatBookingHub.BuildRoomName(showId)).SendAsync("SeatStateChanged", payload, cancellationToken);
        }
    }
}
