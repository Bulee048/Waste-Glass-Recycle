namespace GlassCollectorApi.Models;

public class Supplier
{
    public int Id { get; set; }
    public string SupplierCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double ExpectedClearKg { get; set; }
    public double ExpectedColouredKg { get; set; }

    public ICollection<TripStop> TripStops { get; set; } = new List<TripStop>();
}
