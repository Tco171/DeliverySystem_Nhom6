namespace Back_DeliverySystem.Models;

public class ShippingQuote
{
    public string Id { get; set; } =
        string.Empty;

    public string InputHash { get; set; } =
        string.Empty;

    public long Fee { get; set; }


    // =====================================================
    // MAP COORDINATES
    // =====================================================

    // ?i?m l?y hàng
    public double? PickupLatitude { get; set; }

    public double? PickupLongitude { get; set; }


    // ?i?m giao hàng
    public double? DeliveryLatitude { get; set; }

    public double? DeliveryLongitude { get; set; }


    public DateTime ExpiresAt { get; set; }

    public bool Used { get; set; }
}