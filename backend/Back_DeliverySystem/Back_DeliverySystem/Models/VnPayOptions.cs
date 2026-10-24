namespace Back_DeliverySystem.Models;

public class VnPayOptions
{
    public string PaymentUrl { get; set; } =
        string.Empty;

    public string TmnCode { get; set; } =
        string.Empty;

    public string HashSecret { get; set; } =
        string.Empty;

    public string ReturnUrl { get; set; } =
        string.Empty;

    public string IpnUrl { get; set; } =
        string.Empty;
}