namespace Back_DeliverySystem.DTOs;

public class ShipmentInput
{
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
}

public class CreateShipmentRequest : ShipmentInput
{
    public string QuoteId { get; set; } = string.Empty;
}

public class TransitionRequest
{
    public string Status { get; set; } = string.Empty;
    public string Note { get; set; } = string.Empty;
    public long? CodCollected { get; set; }
}

public class CreatePickupLocationRequest
{
    public string Name { get; set; } = string.Empty;
    public string ContactName { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
}
