namespace GlassCollectorApi.DTOs;

public class SyncRecordDto
{
    public string SupplierCode { get; set; } = string.Empty;
    public double ClearKg { get; set; }
    public double ColouredKg { get; set; }
    public string Condition { get; set; } = string.Empty;
    public DateTime CollectedAtUtc { get; set; }
}
