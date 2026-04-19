using MovieTicket.Application.DTOs.Checkout;
using MovieTicket.Application.Services.IServices.ICheckout;
using MovieTicket.Application.Services.IServices.IPayment;

namespace MovieTicket.Application.Services.Implementations.Payment
{
    public class PaymentService : IPaymentService
    {
        private readonly ICheckoutService _checkoutService;

        public PaymentService(ICheckoutService checkoutService)
        {
            _checkoutService = checkoutService;
        }

        public Task<CheckoutPreviewResponse> GetPaymentPreviewAsync(int accountId, CheckoutPreviewRequest request)
        {
            return _checkoutService.GetCheckoutPreviewAsync(accountId, request);
        }

        public Task<MockMomoPaymentResponse> MockMomoSuccessAsync(int accountId, MockMomoPaymentRequest request)
        {
            return _checkoutService.MockMomoSuccessAsync(accountId, request);
        }

        public Task<List<VoucherViewDto>> GetAvailableVouchersAsync(int accountId)
        {
            return _checkoutService.GetAvailableVouchersAsync(accountId);
        }

        public Task<VoucherViewDto?> GetVoucherDetailByCodeAsync(string code)
        {
            return _checkoutService.GetVoucherDetailByCodeAsync(code);
        }
    }
}
