namespace MovieTicket.Application.Services.IServices.IBooking
{
    public interface ISeatRealtimePublisher
    {
        Task PublishHeldAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, DateTime expiresAtUtc, CancellationToken cancellationToken = default);
        Task PublishBookedAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, CancellationToken cancellationToken = default);
        Task PublishReleasedAsync(int showId, int holdId, IReadOnlyCollection<int> seatIds, string reason, CancellationToken cancellationToken = default);
    }
}
