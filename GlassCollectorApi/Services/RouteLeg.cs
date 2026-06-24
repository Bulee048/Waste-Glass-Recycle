namespace GlassCollectorApi.Services;

public sealed record RouteLeg(
    Models.Supplier Supplier,
    double DistanceFromPreviousKm,
    double CumulativeDistanceKm);
