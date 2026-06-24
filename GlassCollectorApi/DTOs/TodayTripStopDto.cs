namespace GlassCollectorApi.DTOs;

public class TodayTripStopDto
{
    public int SequenceOrder { get; set; }
    public int SupplierId { get; set; }
    public string SupplierCode { get; set; } = string.Empty;
    public string SupplierName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double DistanceFromPreviousKm { get; set; }
    public string Status { get; set; } = string.Empty;
    public double ExpectedClearKg { get; set; }
    public double ExpectedColouredKg { get; set; }
}
