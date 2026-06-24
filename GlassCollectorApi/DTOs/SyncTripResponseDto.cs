namespace GlassCollectorApi.DTOs;

public class SyncTripResponseDto
{
    public int TripId { get; set; }
    public bool AllSynced { get; set; }
    public List<SyncRecordResultDto> Results { get; set; } = new();
}
