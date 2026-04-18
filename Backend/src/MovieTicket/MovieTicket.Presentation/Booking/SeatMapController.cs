using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;

namespace MovieTicket.Presentation.Booking
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class SeatMapController : ControllerBase
    {
        private readonly ISeatMapService _seatMapService;
        private readonly IAccountRepository _accountRepository;
        private readonly ILogger<SeatMapController> _logger;

        public SeatMapController(
            ISeatMapService seatMapService,
            IAccountRepository accountRepository,
            ILogger<SeatMapController> logger)
        {
            _seatMapService = seatMapService;
            _accountRepository = accountRepository;
            _logger = logger;
        }
        [HttpGet("showtimes/{showId:int}/layout")]
        public async Task<IActionResult> GetSeatMapByShow(int showId, [FromQuery] int? accountId)
        {
            if (showId <= 0)
            {
                _logger.LogWarning("showId không hợp lệ cho sơ đồ ghế: {ShowId}", showId);
                return BadRequest(new { success = false, message = "showId không hợp lệ" });
            }

            var tokenAccountIdClaim = User.FindFirst("accountId")?.Value;
            if (!int.TryParse(tokenAccountIdClaim, out var tokenAccountId) || tokenAccountId <= 0)
            {
                _logger.LogWarning("Token không hợp lệ khi lấy sơ đồ ghế cho showId {ShowId}", showId);
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var requesterAccountId = accountId ?? tokenAccountId;
            if (requesterAccountId != tokenAccountId)
            {
                _logger.LogWarning(
                    "Từ chối truy cập sơ đồ ghế do accountId không khớp. tokenAccountId={TokenAccountId}, requestAccountId={RequestAccountId}, showId={ShowId}",
                    tokenAccountId,
                    requesterAccountId,
                    showId);
                return Forbid();
            }

            var account = await _accountRepository.GetByIdAsync(requesterAccountId);
            if (account == null)
            {
                _logger.LogWarning("Không tìm thấy tài khoản {AccountId} khi lấy sơ đồ ghế showId={ShowId}", requesterAccountId, showId);
                return Unauthorized(new { success = false, message = "Tài khoản không tồn tại hoặc đã bị xóa" });
            }

            if (account.Status != Status.active)
            {
                _logger.LogWarning(
                    "Từ chối lấy sơ đồ ghế do tài khoản không active. accountId={AccountId}, status={Status}, showId={ShowId}",
                    requesterAccountId,
                    account.Status,
                    showId);
                return StatusCode(StatusCodes.Status403Forbidden, new { success = false, message = "Tài khoản không đủ điều kiện truy cập" });
            }

            var result = await _seatMapService.GetSeatMapByShowAsync(showId);
            if (result == null)
            {
                _logger.LogWarning("Không tìm thấy sơ đồ ghế cho showId {ShowId}", showId);
                return NotFound(new { success = false, message = "Không tìm thấy suất chiếu hoặc dữ liệu sơ đồ ghế" });
            }

            return Ok(new { success = true, data = result });
        }
    }
}
