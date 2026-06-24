using GlassCollectorApi.Data;
using GlassCollectorApi.DTOs;
using GlassCollectorApi.Models;
using Microsoft.EntityFrameworkCore;

namespace GlassCollectorApi.Services;

public class CollectionService
{
    private readonly GlassCollectorDbContext _db;

    public CollectionService(GlassCollectorDbContext db)
    {
        _db = db;
    }

    public async Task<(bool Success, int StatusCode, string? Error, CollectionResponseDto? Response)> ApplyCollectionAsync(
        int tripId,
        string supplierCode,
        double clearKg,
        double colouredKg,
        string condition,
        DateTime collectedAtUtc,
        bool enforceNextStop)
    {
        var supplier = await _db.Suppliers
            .FirstOrDefaultAsync(s => s.SupplierCode == supplierCode);

        if (supplier is null)
            return (false, StatusCodes.Status404NotFound, $"Supplier '{supplierCode}' was not found.", null);

        var tripStop = await _db.TripStops
            .Include(ts => ts.Supplier)
            .FirstOrDefaultAsync(ts => ts.TripId == tripId && ts.SupplierId == supplier.Id);

        if (tripStop is null)
            return (false, StatusCodes.Status404NotFound,
                $"No trip stop found for trip {tripId} and supplier '{supplierCode}'.", null);

        if (enforceNextStop && tripStop.Status != "Next")
            return (false, StatusCodes.Status409Conflict, "This is not the current expected stop.", null);

        if (tripStop.Status == "Collected")
        {
            if (RecordsMatch(tripStop, clearKg, colouredKg, condition, collectedAtUtc))
            {
                // Idempotent retry: exact same data was already submitted. Gracefully accept it.
                return (true, StatusCodes.Status200OK, null, new CollectionResponseDto
                {
                    UpdatedStop = TripDtoMapper.ToTodayTripStopDto(tripStop),
                    NextStop = null, // Or try to find the actual next pending stop, but null is fine for retries as they already moved on locally
                    TripCompleted = false // Safe fallback
                });
            }
            return (false, StatusCodes.Status409Conflict, "This stop has already been collected with different data.", null);
        }

        tripStop.CollectedClearKg = clearKg;
        tripStop.CollectedColouredKg = colouredKg;
        tripStop.Condition = condition;
        tripStop.CollectedAtUtc = collectedAtUtc;
        tripStop.Status = "Collected";

        var nextTripStop = await _db.TripStops
            .Include(ts => ts.Supplier)
            .Where(ts => ts.TripId == tripId && ts.Status == "Pending")
            .OrderBy(ts => ts.SequenceOrder)
            .FirstOrDefaultAsync();

        var trip = await _db.Trips.FindAsync(tripId);
        var tripCompleted = false;

        if (nextTripStop is not null)
            nextTripStop.Status = "Next";
        else if (trip is not null)
        {
            trip.Status = "Completed";
            tripCompleted = true;
        }

        await _db.SaveChangesAsync();

        return (true, StatusCodes.Status200OK, null, new CollectionResponseDto
        {
            UpdatedStop = TripDtoMapper.ToTodayTripStopDto(tripStop),
            NextStop = nextTripStop is null ? null : TripDtoMapper.ToTodayTripStopDto(nextTripStop),
            TripCompleted = tripCompleted
        });
    }

    public static bool RecordsMatch(
        TripStop tripStop,
        double clearKg,
        double colouredKg,
        string condition,
        DateTime collectedAtUtc)
    {
        return tripStop.Status == "Collected"
               && tripStop.CollectedClearKg == clearKg
               && tripStop.CollectedColouredKg == colouredKg
               && tripStop.Condition == condition
               && tripStop.CollectedAtUtc.HasValue
               && tripStop.CollectedAtUtc.Value.ToUniversalTime() == collectedAtUtc.ToUniversalTime();
    }
}
