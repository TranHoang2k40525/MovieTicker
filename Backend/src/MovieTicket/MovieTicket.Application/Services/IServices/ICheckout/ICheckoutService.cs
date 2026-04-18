using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Application.DTOs.Checkout;

namespace MovieTicket.Application.Services.IServices.ICheckout
{
    public interface ICheckoutService
    {
        Task<CheckoutPreviewResponse> GetCheckoutPreviewAsync(int accountId, CheckoutPreviewRequest request);
        Task<MockMomoPaymentResponse> MockMomoSuccessAsync(int accountId, MockMomoPaymentRequest request);
        Task<List<VoucherViewDto>> GetAvailableVouchersAsync(int accountId);
        Task<VoucherViewDto?> GetVoucherDetailByCodeAsync(string code);
    }
}
