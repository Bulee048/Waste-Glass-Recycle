namespace GlassCollectorApi.DTOs;

public class CollectionResponseDto
{
    public TodayTripStopDto UpdatedStop { get; set; } = null!;
    public TodayTripStopDto? NextStop { get; set; }
    public bool TripCompleted { get; set; }
}
