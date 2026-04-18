using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.ICheckout
{
    public interface ICheckoutRepository
    {
        Task<Booking?> GetBookingForCheckoutAsync(int bookingId);
        Task<Voucher?> GetVoucherByCodeAsync(string code);
        Task<List<Voucher>> GetAvailableVouchersAsync(DateOnly today);
        Task<bool> HasUserUsedVoucherAsync(int userId, int voucherId, int bookingId);
        Task AddVoucherUsageAsync(VoucherUsage usage);
        Task AddPaymentAsync(Payment payment);
        Task AddNotificationAsync(Notification notification);
        Task SaveChangesAsync();
    }
}
