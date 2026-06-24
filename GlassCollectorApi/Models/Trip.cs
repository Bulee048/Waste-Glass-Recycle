namespace GlassCollectorApi.Models;

public class Trip
{
    public int Id { get; set; }
    public DateTime TripDate { get; set; }
    public double StartLatitude { get; set; }
    public double StartLongitude { get; set; }
    public double? TotalDistanceKm { get; set; }
    public string Status { get; set; } = "InProgress";
    public DateTime CreatedAt { get; set; }

    public ICollection<TripStop> TripStops { get; set; } = new List<TripStop>();
}
