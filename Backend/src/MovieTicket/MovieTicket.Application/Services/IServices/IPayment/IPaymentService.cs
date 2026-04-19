using MovieTicket.Application.DTOs.Checkout;

namespace MovieTicket.Application.Services.IServices.IPayment
{
    public interface IPaymentService
    {
        Task<CheckoutPreviewResponse> GetPaymentPreviewAsync(int accountId, CheckoutPreviewRequest request);
        Task<MockMomoPaymentResponse> MockMomoSuccessAsync(int accountId, MockMomoPaymentRequest request);
        Task<List<VoucherViewDto>> GetAvailableVouchersAsync(int accountId);
        Task<VoucherViewDto?> GetVoucherDetailByCodeAsync(string code);
    }
}
