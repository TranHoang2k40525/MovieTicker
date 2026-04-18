using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Checkout;
using MovieTicket.Application.Services.IServices.ICheckout;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;

namespace MovieTicket.Presentation.Controllers.Checkout
{
    [ApiController]
    [Route("api/checkout")]
    [Authorize]
    public class CheckoutController : ControllerBase
    {
        private readonly ICheckoutService _checkoutService;
        private readonly IAccountRepository _accountRepository;

        public CheckoutController(ICheckoutService checkoutService, IAccountRepository accountRepository)
        {
            _checkoutService = checkoutService;
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

            var result = await _checkoutService.GetCheckoutPreviewAsync(accountId.Value, request);
            if (!result.Success) return Conflict(new { success = false, message = result.Message });

            return Ok(new { success = true, data = result });
        }

        [HttpPost("payments/momo/mock-success")]
        public async Task<IActionResult> MockMomoSuccess([FromBody] MockMomoPaymentRequest request)
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null) return Unauthorized(new { success = false, message = "Token không hợp lệ" });

            var result = await _checkoutService.MockMomoSuccessAsync(accountId.Value, request);
            if (!result.Success) return Conflict(new { success = false, message = result.Message });

            return Ok(new { success = true, data = result });
        }

        [HttpGet("vouchers")]
        public async Task<IActionResult> GetVouchers()
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null) return Unauthorized(new { success = false, message = "Token không hợp lệ" });

            var vouchers = await _checkoutService.GetAvailableVouchersAsync(accountId.Value);
            return Ok(new { success = true, data = vouchers });
        }

        [HttpGet("vouchers/{code}")]
        public async Task<IActionResult> GetVoucherDetail(string code)
        {
            var dto = await _checkoutService.GetVoucherDetailByCodeAsync(code);
            if (dto == null) return NotFound(new { success = false, message = "Không tìm thấy voucher" });
            return Ok(new { success = true, data = dto }); // Không trả id
        }

        private int? GetAccountIdFromToken()
        {
            var claim = User.FindFirst("accountId")?.Value;
            if (int.TryParse(claim, out var accountId) && accountId > 0) return accountId;
            return null;
        }
    }
}