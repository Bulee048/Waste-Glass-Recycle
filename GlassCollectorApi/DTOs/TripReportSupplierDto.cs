namespace GlassCollectorApi.DTOs;

public class TripReportSupplierDto
{
    public string SupplierCode { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public double ExpectedClearKg { get; set; }
    public double ExpectedColouredKg { get; set; }
    public double? CollectedClearKg { get; set; }
    public double? CollectedColouredKg { get; set; }
    public string? Condition { get; set; }
    public bool IsShortfall { get; set; }
    public string Status { get; set; } = string.Empty;
}
