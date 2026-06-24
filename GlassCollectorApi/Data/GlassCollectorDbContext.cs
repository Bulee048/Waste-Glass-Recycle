using GlassCollectorApi.Models;
using Microsoft.EntityFrameworkCore;

namespace GlassCollectorApi.Data;

public class GlassCollectorDbContext : DbContext
{
    public GlassCollectorDbContext(DbContextOptions<GlassCollectorDbContext> options)
        : base(options)
    {
    }

    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripStop> TripStops => Set<TripStop>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Supplier>(entity =>
        {
            entity.HasKey(s => s.Id);

            entity.HasIndex(s => s.SupplierCode)
                .IsUnique();

            entity.Property(s => s.SupplierCode)
                .IsRequired();

            entity.Property(s => s.Name)
                .IsRequired();

            entity.Property(s => s.ExpectedClearKg)
                .HasDefaultValue(0.0);

            entity.Property(s => s.ExpectedColouredKg)
                .HasDefaultValue(0.0);
        });

        modelBuilder.Entity<Trip>(entity =>
        {
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Status)
                .IsRequired()
                .HasDefaultValue("InProgress");

            entity.Property(t => t.CreatedAt)
                .IsRequired()
                .HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasMany(t => t.TripStops)
                .WithOne(ts => ts.Trip)
                .HasForeignKey(ts => ts.TripId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<TripStop>(entity =>
        {
            entity.HasKey(ts => ts.Id);

            entity.Property(ts => ts.Status)
                .IsRequired()
                .HasDefaultValue("Pending");

            entity.HasOne(ts => ts.Supplier)
                .WithMany(s => s.TripStops)
                .HasForeignKey(ts => ts.SupplierId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
