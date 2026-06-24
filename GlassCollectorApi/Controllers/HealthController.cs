using GlassCollectorApi.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace GlassCollectorApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    public ActionResult<HealthResponseDto> Get()
    {
        return Ok(new HealthResponseDto { Status = "ok" });
    }
}
