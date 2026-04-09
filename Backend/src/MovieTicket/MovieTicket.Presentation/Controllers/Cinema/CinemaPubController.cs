using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Cinema;
using MovieTicket.Application.Services.IServices.ICinema;
using System.Threading.Tasks;

namespace MovieTicket.Presentation.Controllers.Cinema
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class CinemaPubController : ControllerBase
    {
        private readonly ICinemaPubService _cinemaPubService;

        public CinemaPubController(ICinemaPubService cinemaPubService)
        {
            _cinemaPubService = cinemaPubService;
        }

        [HttpPost("nearby")]
        public async Task<IActionResult> GetNearbyCinemas([FromBody] LocationRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            var result = await _cinemaPubService.GetCinemasSortedByDistanceAsync(request.Latitude, request.Longitude);
            return Ok(result);
        }

        [HttpGet("{cinemaId:int}/showtimes")]
        public async Task<IActionResult> GetShowtimes(int cinemaId, [FromQuery] DateOnly? filterDate)
        {
            if (cinemaId <= 0)
                return BadRequest(new { message = "Invalid Cinema ID" });

            var result = await _cinemaPubService.GetShowtimesByCinemaAsync(cinemaId, filterDate);
            return Ok(result);
        }
    }
}