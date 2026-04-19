using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Checkout;
using MovieTicket.Application.Services.IServices.IPayment;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;

namespace MovieTicket.Presentation.Controllers.Payment
{
    [ApiController]
    [Route("api/payments")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly IAccountRepository _accountRepository;

        public PaymentController(IPaymentService paymentService, IAccountRepository accountRepository)
        {
            _paymentService = paymentService;
            _accountRepository = accountRepository;
        }

        [HttpPost("preview")]
        public async Task<IActionResult> Preview([FromBody] CheckoutPreviewRequest request)
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null) return Unauthorized(new { success = false, message = "Token không hợp lệ" });

            var account = await _accountRepository.GetByIdAsync(accountId.Value);
            if (account == null || account.Status != Status.active)
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Tài khoản không đủ điều kiện" });

            var result = await _paymentService.GetPaymentPreviewAsync(accountId.Value, request);
            if (!result.Success) return Conflict(new { success = false, message = result.Message });

            return Ok(new { success = true, data = result });
        }

        [HttpPost("momo/mock-success")]
        public async Task<IActionResult> MockMomoSuccess([FromBody] MockMomoPaymentRequest request)
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null) return Unauthorized(new { success = false, message = "Token không hợp lệ" });

            var result = await _paymentService.MockMomoSuccessAsync(accountId.Value, request);
            if (!result.Success) return Conflict(new { success = false, message = result.Message });

            return Ok(new { success = true, data = result });
        }

        [HttpGet("vouchers")]
        public async Task<IActionResult> GetVouchers()
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null) return Unauthorized(new { success = false, message = "Token không hợp lệ" });

            var vouchers = await _paymentService.GetAvailableVouchersAsync(accountId.Value);
            return Ok(new { success = true, data = vouchers });
        }

        [HttpGet("vouchers/{code}")]
        public async Task<IActionResult> GetVoucherDetail(string code)
        {
            var dto = await _paymentService.GetVoucherDetailByCodeAsync(code);
            if (dto == null) return NotFound(new { success = false, message = "Không tìm thấy voucher" });
            return Ok(new { success = true, data = dto });
        }

        private int? GetAccountIdFromToken()
        {
            var claim = User.FindFirst("accountId")?.Value;
            if (int.TryParse(claim, out var accountId) && accountId > 0) return accountId;
            return null;
        }
    }
}
