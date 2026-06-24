using GlassCollectorApi.DTOs;
using GlassCollectorApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace GlassCollectorApi.Controllers;

[ApiController]
[Route("api/collections")]
public class CollectionsController : ControllerBase
{
    private readonly CollectionService _collectionService;

    public CollectionsController(CollectionService collectionService)
    {
        _collectionService = collectionService;
    }

    [HttpPost]
    public async Task<ActionResult<CollectionResponseDto>> SubmitCollection([FromBody] CollectionRequestDto request)
    {
        var result = await _collectionService.ApplyCollectionAsync(
            request.TripId,
            request.SupplierCode,
            request.ClearKg,
            request.ColouredKg,
            request.Condition,
            DateTime.UtcNow,
            enforceNextStop: true);

        if (!result.Success)
            return StatusCode(result.StatusCode, new { message = result.Error });

        return Ok(result.Response);
    }
}
