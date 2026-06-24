namespace GlassCollectorApi.DTOs;

public class SyncRecordResultDto
{
    public string SupplierCode { get; set; } = string.Empty;
    public bool AlreadySynced { get; set; }
    public bool Synced { get; set; }
    public bool Failed { get; set; }
    public string? Reason { get; set; }
}
