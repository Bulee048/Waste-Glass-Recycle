using GlassCollectorApi.DTOs;
using GlassCollectorApi.Models;

namespace GlassCollectorApi.Services;

public static class TripDtoMapper
{
    public static TodayTripStopDto ToTodayTripStopDto(TripStop tripStop) => new()
    {
        SequenceOrder = tripStop.SequenceOrder,
        SupplierId = tripStop.SupplierId,
        SupplierCode = tripStop.Supplier.SupplierCode,
        SupplierName = tripStop.Supplier.Name,
        Address = tripStop.Supplier.Address,
        Latitude = tripStop.Supplier.Latitude,
        Longitude = tripStop.Supplier.Longitude,
        DistanceFromPreviousKm = tripStop.DistanceFromPreviousKm,
        Status = tripStop.Status,
        ExpectedClearKg = tripStop.Supplier.ExpectedClearKg,
        ExpectedColouredKg = tripStop.Supplier.ExpectedColouredKg
    };

    public static TodayTripResponseDto ToTodayTripResponseDto(Trip trip, List<TripStop> stops) => new()
    {
        TripId = trip.Id,
        TripDate = DateOnly.FromDateTime(trip.TripDate),
        TotalDistanceKm = trip.TotalDistanceKm,
        RemainingStops = stops.Count(s => s.Status != "Collected"),
        Stops = stops
            .OrderBy(s => s.SequenceOrder)
            .Select(ToTodayTripStopDto)
            .ToList()
    };

    public static TripReportResponseDto ToTripReportResponseDto(Trip trip, List<TripStop> stops)
    {
        var collectedStops = stops
            .Where(s => s.CollectedAtUtc.HasValue)
            .OrderBy(s => s.CollectedAtUtc)
            .ToList();

        double? tripDurationMinutes = null;
        if (trip.Status == "Completed" && collectedStops.Count >= 2)
        {
            var first = collectedStops.First().CollectedAtUtc!.Value;
            var last = collectedStops.Last().CollectedAtUtc!.Value;
            tripDurationMinutes = (last - first).TotalMinutes;
        }
        else if (trip.Status == "Completed" && collectedStops.Count == 1)
        {
            tripDurationMinutes = 0;
        }

        return new TripReportResponseDto
        {
            TripId = trip.Id,
            TripDate = DateOnly.FromDateTime(trip.TripDate),
            TotalDistanceKm = trip.TotalDistanceKm,
            TripDurationMinutes = tripDurationMinutes,
            TotalClearKg = stops.Sum(s => s.CollectedClearKg ?? 0),
            TotalColouredKg = stops.Sum(s => s.CollectedColouredKg ?? 0),
            Suppliers = stops
                .OrderBy(s => s.SequenceOrder)
                .Select(s => new TripReportSupplierDto
                {
                    SupplierCode = s.Supplier.SupplierCode,
                    SupplierName = s.Supplier.Name,
                    ExpectedClearKg = s.Supplier.ExpectedClearKg,
                    ExpectedColouredKg = s.Supplier.ExpectedColouredKg,
                    CollectedClearKg = s.CollectedClearKg,
                    CollectedColouredKg = s.CollectedColouredKg,
                    Condition = s.Condition,
                    IsShortfall = IsShortfall(s),
                    Status = s.Status
                })
                .ToList()
        };
    }

    private static bool IsShortfall(TripStop tripStop)
    {
        if (tripStop.Status != "Collected")
            return false;

        var expectedTotal = tripStop.Supplier.ExpectedClearKg + tripStop.Supplier.ExpectedColouredKg;
        var collectedTotal = (tripStop.CollectedClearKg ?? 0) + (tripStop.CollectedColouredKg ?? 0);
        return collectedTotal < expectedTotal;
    }
}
