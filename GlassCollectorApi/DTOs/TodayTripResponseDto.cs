namespace GlassCollectorApi.DTOs;

public class TodayTripResponseDto
{
    public int TripId { get; set; }
    public DateOnly TripDate { get; set; }
    public double? TotalDistanceKm { get; set; }
    public int RemainingStops { get; set; }
    public List<TodayTripStopDto> Stops { get; set; } = new();
}
