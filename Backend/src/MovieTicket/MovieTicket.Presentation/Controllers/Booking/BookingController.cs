// Backend/src/MovieTicket/MovieTicket.Presentation/Controllers/Booking/BookingController.cs
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Booking;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;

namespace MovieTicket.Presentation.Controllers.Booking
{
    [ApiController]
    [Route("api/bookings")]
    [Authorize]
    public class BookingController : ControllerBase
    {
        private readonly IBookingFlowService _bookingFlowService;
        private readonly IAccountRepository _accountRepository;
        private readonly ILogger<BookingController> _logger;

        public BookingController(
            IBookingFlowService bookingFlowService,
            IAccountRepository accountRepository,
            ILogger<BookingController> logger)
        {
            _bookingFlowService = bookingFlowService;
            _accountRepository = accountRepository;
            _logger = logger;
        }

        [HttpPost("holds")]
        public async Task<IActionResult> StartHold([FromBody] StartSeatHoldRequest? request)
        {
            if (request == null)
            {
                return BadRequest(new { success = false, message = "Body không hợp lệ" });
            }

            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var account = await _accountRepository.GetByIdAsync(accountId.Value);
            if (account == null || account.Status != Status.active)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Tài khoản không đủ điều kiện" });
            }

            try
            {
                var result = await _bookingFlowService.StartSeatHoldAsync(accountId.Value, request);
                if (!result.Success)
                {
                    return Conflict(new { success = false, message = result.Message, data = result });
                }

                return Ok(new { success = true, data = result });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpPost("holds/confirm")]
        public async Task<IActionResult> ConfirmHold([FromBody] ConfirmSeatBookingRequest? request)
        {
            if (request == null)
            {
                return BadRequest(new { success = false, message = "Body không hợp lệ" });
            }

            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var account = await _accountRepository.GetByIdAsync(accountId.Value);
            if (account == null || account.Status != Status.active)
            {
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Tài khoản không đủ điều kiện" });
            }

            var result = await _bookingFlowService.ConfirmSeatBookingAsync(accountId.Value, request);
            if (!result.Success)
            {
                return Conflict(new { success = false, message = result.Message });
            }

            return Ok(new { success = true, data = result });
        }

        [HttpDelete("holds/{holdId:int}")]
        public async Task<IActionResult> ReleaseHold(int holdId)
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var released = await _bookingFlowService.ReleaseHoldAsync(accountId.Value, holdId);
            if (!released)
            {
                return NotFound(new { success = false, message = "Không tìm thấy giữ ghế hoặc giữ ghế đã hết hạn" });
            }

            return Ok(new { success = true, message = "Đã hủy giữ ghế" });
        }

        private int? GetAccountIdFromToken()
        {
            var claim = User.FindFirst("accountId")?.Value;
            if (int.TryParse(claim, out var accountId) && accountId > 0)
            {
                return accountId;
            }

            return null;
        }
    }
}