namespace Back_DeliverySystem.Models;

public class ShippingQuote
{
    public string Id { get; set; } = string.Empty;
    public string InputHash { get; set; } = string.Empty;
    public long Fee { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool Used { get; set; }
}
