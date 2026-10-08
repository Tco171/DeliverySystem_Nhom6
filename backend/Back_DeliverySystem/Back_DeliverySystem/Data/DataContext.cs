using Back_DeliverySystem.Models;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Shipment> Shipments => Set<Shipment>();
    public DbSet<ShipmentEvent> ShipmentEvents => Set<ShipmentEvent>();
    public DbSet<ShippingQuote> ShippingQuotes => Set<ShippingQuote>();
    public DbSet<PickupLocation> PickupLocations => Set<PickupLocation>();
    public DbSet<Complaint> Complaints => Set<Complaint>();

    // Đối soát COD
    public DbSet<Settlement> Settlements => Set<Settlement>();
    public DbSet<SettlementLine> SettlementLines => Set<SettlementLine>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Shipment>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(50);

            entity.Property(x => x.WeightKg).HasPrecision(10, 2);
            entity.Property(x => x.LengthCm).HasPrecision(10, 2);
            entity.Property(x => x.WidthCm).HasPrecision(10, 2);
            entity.Property(x => x.HeightCm).HasPrecision(10, 2);

            entity.HasMany(x => x.Events)
                  .WithOne()
                  .HasForeignKey(x => x.ShipmentId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ShipmentEvent>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.ShipmentId).HasMaxLength(50);
        });

        modelBuilder.Entity<ShippingQuote>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(50);
            entity.Property(x => x.InputHash).HasMaxLength(128);
        });

        modelBuilder.Entity<PickupLocation>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(100);
            entity.Property(x => x.ContactName).HasMaxLength(200);
            entity.Property(x => x.ContactPhone).HasMaxLength(30);
            entity.Property(x => x.Address).HasMaxLength(500);
        });

        // Cấu hình Settlement
        modelBuilder.Entity<Settlement>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Id).HasMaxLength(50);

            entity.HasMany(x => x.Lines)
                  .WithOne()
                  .HasForeignKey(x => x.SettlementId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // Cấu hình SettlementLine
        modelBuilder.Entity<SettlementLine>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.SettlementId).HasMaxLength(50);
            entity.Property(x => x.ShipmentId).HasMaxLength(50);
        });
    }
}