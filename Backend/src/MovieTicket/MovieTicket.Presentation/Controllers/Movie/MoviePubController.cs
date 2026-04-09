using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.Services.IServices.IMovie;

namespace MovieTicket.Presentation.Controllers.Movie
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class MoviePubController : ControllerBase
    {
        private readonly IMoviePubService _moviePubService;

        public MoviePubController(IMoviePubService moviePubService)
        {
            _moviePubService = moviePubService;
        }

        [HttpGet("now-showing")]
        public async Task<IActionResult> GetNowShowingMovies()
        {
            var result = await _moviePubService.GetNowShowingMoviesAsync();
            return Ok(result);
        }

        [HttpGet("upcoming")]
        public async Task<IActionResult> GetUpcomingMovies()
        {
            var result = await _moviePubService.GetUpcomingMoviesAsync();
            return Ok(result);
        }

        [HttpGet("special")]
        public async Task<IActionResult> GetSpecialMovies()
        {
            var result = await _moviePubService.GetSpecialMoviesAsync();
            return Ok(result);
        }

        [HttpGet("showing-and-upcoming")]
        public async Task<IActionResult> GetShowingAndUpcomingMovies([FromQuery] int page = 1, [FromQuery] int sizePage = 10)
        {
            var result = await _moviePubService.GetAllShowingAndUpcomingMoviesAsync(page, sizePage);
            return Ok(result);
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetMovieById(int id)
        {
            var result = await _moviePubService.GetMovieByIdAsync(id);
            if (result == null)
                return NotFound(new { message = "Movie not found" });

            return Ok(result);
        }

        [HttpGet("search")]
        public async Task<IActionResult> GetMovieByName([FromQuery] string name)
        {
            if (string.IsNullOrWhiteSpace(name))
                return BadRequest(new { message = "Name parameter is required" });

            var result = await _moviePubService.GetMovieByNameAsync(name);
            if (result == null)
                return NotFound(new { message = "Movie not found" });

            return Ok(result);
        }
    }
}
