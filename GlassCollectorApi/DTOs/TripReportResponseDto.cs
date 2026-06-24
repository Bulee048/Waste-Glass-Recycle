namespace GlassCollectorApi.DTOs;

public class TripReportResponseDto
{
    public int TripId { get; set; }
    public DateOnly TripDate { get; set; }
    public double? TotalDistanceKm { get; set; }
    public double? TripDurationMinutes { get; set; }
    public double TotalClearKg { get; set; }
    public double TotalColouredKg { get; set; }
    public List<TripReportSupplierDto> Suppliers { get; set; } = new();
}
