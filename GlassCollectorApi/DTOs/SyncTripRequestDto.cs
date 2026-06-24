namespace GlassCollectorApi.DTOs;

public class SyncTripRequestDto
{
    public int TripId { get; set; }
    public List<SyncRecordDto> Records { get; set; } = new();
}
