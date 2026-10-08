namespace Back_DeliverySystem.Models;

public class Settlement
{
    public string Id { get; set; } = string.Empty;

    public int CustomerId { get; set; }

    public long TotalCod { get; set; }

    public long ShippingDeduction { get; set; }

    public long Adjustment { get; set; }

    public string AdjustmentReason { get; set; } = string.Empty;

    public long NetAmount { get; set; }

    public string Status { get; set; } = "pending";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? CompletedAt { get; set; }

    public string? PaymentReference { get; set; }

    public List<SettlementLine> Lines { get; set; } = new();
}

public class SettlementLine
{
    public int Id { get; set; }

    public string SettlementId { get; set; } = string.Empty;

    public string ShipmentId { get; set; } = string.Empty;

    public long CodCollected { get; set; }

    public long ShippingDeduction { get; set; }
}