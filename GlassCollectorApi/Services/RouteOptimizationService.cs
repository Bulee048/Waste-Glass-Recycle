using GlassCollectorApi.Models;

namespace GlassCollectorApi.Services;

public class RouteOptimizationService
{
    private const double EarthRadiusKm = 6371.0;

    public double HaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var lat1Rad = ToRadians(lat1);
        var lat2Rad = ToRadians(lat2);
        var deltaLat = ToRadians(lat2 - lat1);
        var deltaLon = ToRadians(lon2 - lon1);

        var a = Math.Pow(Math.Sin(deltaLat / 2), 2)
              + Math.Cos(lat1Rad) * Math.Cos(lat2Rad) * Math.Pow(Math.Sin(deltaLon / 2), 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return EarthRadiusKm * c;
    }

    public IReadOnlyList<RouteLeg> CalculateOptimalRoute(
        double startLat,
        double startLon,
        List<Supplier> suppliers)
    {
        if (suppliers.Count == 0)
            return Array.Empty<RouteLeg>();

        var nodeCount = suppliers.Count + 1;
        var latitudes = new double[nodeCount];
        var longitudes = new double[nodeCount];

        latitudes[0] = startLat;
        longitudes[0] = startLon;

        for (var i = 0; i < suppliers.Count; i++)
        {
            latitudes[i + 1] = suppliers[i].Latitude;
            longitudes[i + 1] = suppliers[i].Longitude;
        }

        var edgeWeight = BuildCompleteGraphWeights(latitudes, longitudes, nodeCount);
        var supplierVisited = new bool[suppliers.Count];
        var route = new List<RouteLeg>();
        var currentNode = 0;
        var cumulativeDistanceKm = 0.0;

        for (var visit = 0; visit < suppliers.Count; visit++)
        {
            var shortestDistances = RunDijkstra(edgeWeight, nodeCount, currentNode);

            var nextSupplierIndex = -1;
            var shortestLegKm = double.PositiveInfinity;

            for (var supplierIndex = 0; supplierIndex < suppliers.Count; supplierIndex++)
            {
                if (supplierVisited[supplierIndex])
                    continue;

                var supplierNode = supplierIndex + 1;
                var distanceKm = shortestDistances[supplierNode];

                if (distanceKm < shortestLegKm)
                {
                    shortestLegKm = distanceKm;
                    nextSupplierIndex = supplierIndex;
                }
            }

            if (nextSupplierIndex < 0)
                break;

            supplierVisited[nextSupplierIndex] = true;
            currentNode = nextSupplierIndex + 1;
            cumulativeDistanceKm += shortestLegKm;

            route.Add(new RouteLeg(
                suppliers[nextSupplierIndex],
                shortestLegKm,
                cumulativeDistanceKm));
        }

        return route;
    }

    private double[,] BuildCompleteGraphWeights(double[] latitudes, double[] longitudes, int nodeCount)
    {
        var weights = new double[nodeCount, nodeCount];

        for (var from = 0; from < nodeCount; from++)
        {
            for (var to = 0; to < nodeCount; to++)
            {
                weights[from, to] = from == to
                    ? 0
                    : HaversineDistance(latitudes[from], longitudes[from], latitudes[to], longitudes[to]);
            }
        }

        return weights;
    }

    private static double[] RunDijkstra(double[,] edgeWeight, int nodeCount, int sourceNode)
    {
        var distances = new double[nodeCount];
        var visited = new bool[nodeCount];
        Array.Fill(distances, double.PositiveInfinity);
        distances[sourceNode] = 0;

        var priorityQueue = new PriorityQueue<int, double>();
        priorityQueue.Enqueue(sourceNode, 0);

        while (priorityQueue.Count > 0)
        {
            priorityQueue.TryDequeue(out var currentNode, out _);

            if (visited[currentNode])
                continue;

            visited[currentNode] = true;

            for (var neighbour = 0; neighbour < nodeCount; neighbour++)
            {
                if (visited[neighbour])
                    continue;

                var candidateDistance = distances[currentNode] + edgeWeight[currentNode, neighbour];
                if (candidateDistance < distances[neighbour])
                {
                    distances[neighbour] = candidateDistance;
                    priorityQueue.Enqueue(neighbour, candidateDistance);
                }
            }
        }

        return distances;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180.0;
}
