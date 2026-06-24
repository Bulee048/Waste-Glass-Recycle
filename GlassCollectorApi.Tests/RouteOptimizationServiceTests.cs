using GlassCollectorApi.Models;
using GlassCollectorApi.Services;

namespace GlassCollectorApi.Tests;

public class RouteOptimizationServiceTests
{
    private readonly RouteOptimizationService _service = new();

    [Fact]
    public void HaversineDistance_KnownPoints_ReturnsApproximatelyFiveKilometres()
    {
        // Two points on the same meridian in Colombo, ~0.045° latitude apart (~5 km).
        const double latNorth = 6.9271;
        const double latSouth = 6.8821;
        const double longitude = 79.8612;

        var distanceKm = _service.HaversineDistance(latNorth, longitude, latSouth, longitude);

        Assert.InRange(distanceKm, 4.8, 5.2);
    }

    [Fact]
    public void CalculateOptimalRoute_ThreeCollinearSuppliers_ReturnsNearestFirstOrder()
    {
        const double depotLat = 6.9000;
        const double depotLon = 79.8500;

        var suppliers = new List<Supplier>
        {
            new()
            {
                SupplierCode = "FAR",
                Name = "Far Supplier",
                Latitude = 6.9100,
                Longitude = depotLon
            },
            new()
            {
                SupplierCode = "NEAR",
                Name = "Near Supplier",
                Latitude = 6.9010,
                Longitude = depotLon
            },
            new()
            {
                SupplierCode = "MID",
                Name = "Mid Supplier",
                Latitude = 6.9050,
                Longitude = depotLon
            }
        };

        var route = _service.CalculateOptimalRoute(depotLat, depotLon, suppliers);

        Assert.Equal(3, route.Count);
        Assert.Equal(new[] { "NEAR", "MID", "FAR" }, route.Select(leg => leg.Supplier.SupplierCode));

        Assert.True(route[0].DistanceFromPreviousKm < route[1].DistanceFromPreviousKm);
        Assert.True(route[1].DistanceFromPreviousKm < route[2].DistanceFromPreviousKm);

        Assert.Equal(route[0].DistanceFromPreviousKm, route[0].CumulativeDistanceKm);
        Assert.Equal(
            route[0].DistanceFromPreviousKm + route[1].DistanceFromPreviousKm,
            route[1].CumulativeDistanceKm);
        Assert.Equal(
            route.Sum(leg => leg.DistanceFromPreviousKm),
            route[2].CumulativeDistanceKm);
    }
}
