using GlassCollectorApi.Models;
using Microsoft.EntityFrameworkCore;

namespace GlassCollectorApi.Data;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(GlassCollectorDbContext db)
    {
        if (await db.Suppliers.AnyAsync())
            return;

        var suppliers = new[]
        {
            new Supplier
            {
                SupplierCode = "SUP-001",
                Name = "Green Bottle Restaurant",
                Address = "42 Galle Road, Colombo 03",
                Latitude = 6.9032,
                Longitude = 79.8541,
                ExpectedClearKg = 48.5,
                ExpectedColouredKg = 22.0
            },
            new Supplier
            {
                SupplierCode = "SUP-002",
                Name = "Lakeside Hotel",
                Address = "18 Sir Chittampalam Gardiner Mawatha, Colombo 02",
                Latitude = 6.9187,
                Longitude = 79.8498,
                ExpectedClearKg = 72.0,
                ExpectedColouredKg = 38.5
            },
            new Supplier
            {
                SupplierCode = "SUP-003",
                Name = "Spice Garden Cafe",
                Address = "7 Main Street, Pettah, Colombo 11",
                Latitude = 6.9364,
                Longitude = 79.8472,
                ExpectedClearKg = 14.0,
                ExpectedColouredKg = 9.5
            },
            new Supplier
            {
                SupplierCode = "SUP-004",
                Name = "Ocean View Bar",
                Address = "215 Galle Road, Wellawatte, Colombo 06",
                Latitude = 6.8728,
                Longitude = 79.8593,
                ExpectedClearKg = 56.0,
                ExpectedColouredKg = 41.0
            },
            new Supplier
            {
                SupplierCode = "SUP-005",
                Name = "Temple Trees Bistro",
                Address = "33 Station Road, Bambalapitiya, Colombo 04",
                Latitude = 6.8891,
                Longitude = 79.8637,
                ExpectedClearKg = 31.5,
                ExpectedColouredKg = 17.0
            },
            new Supplier
            {
                SupplierCode = "SUP-006",
                Name = "Harbour Lights Restaurant",
                Address = "5 Bristol Street, Fort, Colombo 01",
                Latitude = 6.9348,
                Longitude = 79.8435,
                ExpectedClearKg = 65.0,
                ExpectedColouredKg = 19.5
            }
        };

        db.Suppliers.AddRange(suppliers);

        var depotLatitude = suppliers.Average(s => s.Latitude);
        var depotLongitude = suppliers.Average(s => s.Longitude);

        db.Trips.Add(new Trip
        {
            TripDate = DateTime.UtcNow.Date,
            StartLatitude = depotLatitude,
            StartLongitude = depotLongitude,
            Status = "InProgress",
            CreatedAt = DateTime.UtcNow
        });

        await db.SaveChangesAsync();

        Console.WriteLine();
        Console.WriteLine("=== Seeded suppliers (copy for barcode generation) ===");
        foreach (var supplier in suppliers.OrderBy(s => s.SupplierCode))
        {
            Console.WriteLine(
                $"{supplier.SupplierCode}: {supplier.Latitude:F6}, {supplier.Longitude:F6}  ({supplier.Name})");
        }
        Console.WriteLine("====================================================");
        Console.WriteLine();
    }
}
