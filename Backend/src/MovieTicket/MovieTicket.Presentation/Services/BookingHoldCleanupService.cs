using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.Services.IServices.IBooking;

namespace MovieTicket.Presentation.Services
{
    public class BookingHoldCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<BookingHoldCleanupService> _logger;

        public BookingHoldCleanupService(IServiceProvider serviceProvider, ILogger<BookingHoldCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);

                    using var scope = _serviceProvider.CreateScope();
                    var bookingFlowService = scope.ServiceProvider.GetRequiredService<IBookingFlowService>();

                    var released = await bookingFlowService.ReleaseExpiredHoldsAsync();
                    if (released)
                    {
                        _logger.LogInformation("Đã giải phóng các giữ ghế đã hết hạn.");
                    }
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi xảy ra trong BookingHoldCleanupService.");
                }
            }
        }
    }
}
