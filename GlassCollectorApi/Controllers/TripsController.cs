using GlassCollectorApi.Data;
using GlassCollectorApi.DTOs;
using GlassCollectorApi.Models;
using GlassCollectorApi.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GlassCollectorApi.Controllers;

[ApiController]
[Route("api/trips")]
public class TripsController : ControllerBase
{
    private readonly GlassCollectorDbContext _db;
    private readonly RouteOptimizationService _routeOptimization;
    private readonly CollectionService _collectionService;

    public TripsController(
        GlassCollectorDbContext db,
        RouteOptimizationService routeOptimization,
        CollectionService collectionService)
    {
        _db = db;
        _routeOptimization = routeOptimization;
        _collectionService = collectionService;
    }

    [HttpGet("today")]
    public async Task<ActionResult<TodayTripResponseDto>> GetTodayTrip()
    {
        var today = DateTime.UtcNow.Date;
        var trip = await _db.Trips
            .Where(t => t.TripDate == today && (t.Status == "InProgress" || t.Status == "Completed"))
            .OrderByDescending(t => t.Id)
            .FirstOrDefaultAsync();

        if (trip is null)
            return NotFound(new { message = "No trip found for today." });

        var existingStops = await _db.TripStops
            .Where(ts => ts.TripId == trip.Id)
            .AnyAsync();

        if (!existingStops)
        {
            await GenerateTripStopsAsync(trip);
            await _db.Entry(trip).ReloadAsync();
        }

        var stops = await _db.TripStops
            .Include(ts => ts.Supplier)
            .Where(ts => ts.TripId == trip.Id)
            .OrderBy(ts => ts.SequenceOrder)
            .ToListAsync();

        return Ok(TripDtoMapper.ToTodayTripResponseDto(trip, stops));
    }

    [HttpGet("{tripId:int}/report")]
    public async Task<ActionResult<TripReportResponseDto>> GetTripReport(int tripId)
    {
        var trip = await _db.Trips.FindAsync(tripId);
        if (trip is null)
            return NotFound(new { message = $"Trip {tripId} was not found." });

        var stops = await _db.TripStops
            .Include(ts => ts.Supplier)
            .Where(ts => ts.TripId == tripId)
            .OrderBy(ts => ts.SequenceOrder)
            .ToListAsync();

        return Ok(TripDtoMapper.ToTripReportResponseDto(trip, stops));
    }

    [HttpPost("{tripId:int}/sync")]
    public async Task<ActionResult<SyncTripResponseDto>> SyncTrip(int tripId, [FromBody] SyncTripRequestDto request)
    {
        if (request.TripId != tripId)
            return BadRequest(new { message = "Trip ID in the URL does not match the request body." });

        var tripExists = await _db.Trips.AnyAsync(t => t.Id == tripId);
        if (!tripExists)
            return NotFound(new { message = $"Trip {tripId} was not found." });

        var results = new List<SyncRecordResultDto>();

        foreach (var record in request.Records)
        {
            var supplier = await _db.Suppliers
                .FirstOrDefaultAsync(s => s.SupplierCode == record.SupplierCode);

            if (supplier is null)
            {
                results.Add(new SyncRecordResultDto
                {
                    SupplierCode = record.SupplierCode,
                    Failed = true,
                    Reason = $"Supplier '{record.SupplierCode}' was not found."
                });
                continue;
            }

            var tripStop = await _db.TripStops
                .FirstOrDefaultAsync(ts => ts.TripId == tripId && ts.SupplierId == supplier.Id);

            if (tripStop is null)
            {
                results.Add(new SyncRecordResultDto
                {
                    SupplierCode = record.SupplierCode,
                    Failed = true,
                    Reason = $"No trip stop found for trip {tripId} and supplier '{record.SupplierCode}'."
                });
                continue;
            }

            if (tripStop.Status == "Collected")
            {
                if (CollectionService.RecordsMatch(
                    tripStop,
                    record.ClearKg,
                    record.ColouredKg,
                    record.Condition,
                    record.CollectedAtUtc))
                {
                    results.Add(new SyncRecordResultDto
                    {
                        SupplierCode = record.SupplierCode,
                        AlreadySynced = true
                    });
                }
                else
                {
                    results.Add(new SyncRecordResultDto
                    {
                        SupplierCode = record.SupplierCode,
                        Failed = true,
                        Reason = "Stop already collected with different data."
                    });
                }

                continue;
            }

            var applyResult = await _collectionService.ApplyCollectionAsync(
                tripId,
                record.SupplierCode,
                record.ClearKg,
                record.ColouredKg,
                record.Condition,
                record.CollectedAtUtc,
                enforceNextStop: true);

            if (!applyResult.Success)
            {
                results.Add(new SyncRecordResultDto
                {
                    SupplierCode = record.SupplierCode,
                    Failed = true,
                    Reason = applyResult.Error
                });
                continue;
            }

            results.Add(new SyncRecordResultDto
            {
                SupplierCode = record.SupplierCode,
                Synced = true
            });
        }

        return Ok(new SyncTripResponseDto
        {
            TripId = tripId,
            AllSynced = results.All(r => r.AlreadySynced || r.Synced),
            Results = results
        });
    }

    private async Task GenerateTripStopsAsync(Trip trip)
    {
        var suppliers = await _db.Suppliers.OrderBy(s => s.Id).ToListAsync();
        var route = _routeOptimization.CalculateOptimalRoute(
            trip.StartLatitude,
            trip.StartLongitude,
            suppliers);

        var tripStops = route.Select((leg, index) => new TripStop
        {
            TripId = trip.Id,
            SupplierId = leg.Supplier.Id,
            SequenceOrder = index + 1,
            DistanceFromPreviousKm = leg.DistanceFromPreviousKm,
            Status = index == 0 ? "Next" : "Pending"
        }).ToList();

        trip.TotalDistanceKm = route.LastOrDefault()?.CumulativeDistanceKm;
        _db.TripStops.AddRange(tripStops);
        await _db.SaveChangesAsync();
    }

    [HttpPost("reset")]
    public async Task<IActionResult> ResetData()
    {
        _db.TripStops.RemoveRange(_db.TripStops);
        _db.Trips.RemoveRange(_db.Trips);
        _db.Suppliers.RemoveRange(_db.Suppliers);
        await _db.SaveChangesAsync();
        await DatabaseSeeder.SeedAsync(_db);
        return Ok(new { message = "Database successfully wiped and re-seeded! You can now start a fresh demo." });
    }
}
