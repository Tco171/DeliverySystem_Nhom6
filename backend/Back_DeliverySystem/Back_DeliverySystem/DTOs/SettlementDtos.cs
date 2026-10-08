namespace Back_DeliverySystem.DTOs;

public class CreateSettlementRequest
{
    public List<string> ShipmentIds { get; set; } = new();

    public long Adjustment { get; set; }

    public string AdjustmentReason { get; set; } = string.Empty;
}

public class CompleteSettlementRequest
{
    public string PaymentReference { get; set; } = string.Empty;
}