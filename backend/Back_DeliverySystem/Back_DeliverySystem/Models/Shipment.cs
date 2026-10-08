namespace Back_DeliverySystem.Models;

public class Shipment
{
    public string Id { get; set; } = string.Empty;
    public int? CustomerId { get; set; }

    public string SenderName { get; set; } = string.Empty;
    public string SenderPhone { get; set; } = string.Empty;
    public string PickupAddress { get; set; } = string.Empty;
    public string RecipientName { get; set; } = string.Empty;
    public string RecipientPhone { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public string Goods { get; set; } = string.Empty;

    public decimal WeightKg { get; set; }
    public decimal LengthCm { get; set; }
    public decimal WidthCm { get; set; }
    public decimal HeightCm { get; set; }
    public long DeclaredValue { get; set; }
    public long CodAmount { get; set; }

    public string VehicleType { get; set; } = "motorbike";
    public string Service { get; set; } = "standard";
    public string FeePayer { get; set; } = "shop_prepaid";
    public string Notes { get; set; } = string.Empty;

    public long Fee { get; set; }
    public string Status { get; set; } = "pending_pickup";
    public int Attempts { get; set; }
    public long CodCollected { get; set; }
    public string? CurrentHubId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public List<ShipmentEvent> Events { get; set; } = new();
}

public class ShipmentEvent
{
    public int Id { get; set; }
    public string ShipmentId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime At { get; set; } = DateTime.UtcNow;
    public string Note { get; set; } = string.Empty;
}
