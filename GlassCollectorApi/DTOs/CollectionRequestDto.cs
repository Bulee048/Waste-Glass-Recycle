namespace GlassCollectorApi.DTOs;

public class CollectionRequestDto
{
    public int TripId { get; set; }
    public string SupplierCode { get; set; } = string.Empty;
    public double ClearKg { get; set; }
    public double ColouredKg { get; set; }
    public string Condition { get; set; } = string.Empty;
}
