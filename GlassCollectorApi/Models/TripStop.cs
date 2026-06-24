namespace GlassCollectorApi.Models;

public class TripStop
{
    public int Id { get; set; }
    public int TripId { get; set; }
    public int SupplierId { get; set; }
    public int SequenceOrder { get; set; }
    public double DistanceFromPreviousKm { get; set; }
    public string Status { get; set; } = "Pending";
    public double? CollectedClearKg { get; set; }
    public double? CollectedColouredKg { get; set; }
    public string? Condition { get; set; }
    public DateTime? CollectedAtUtc { get; set; }

    public Trip Trip { get; set; } = null!;
    public Supplier Supplier { get; set; } = null!;
}
