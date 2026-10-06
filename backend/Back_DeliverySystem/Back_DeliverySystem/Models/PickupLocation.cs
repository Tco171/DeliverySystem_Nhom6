namespace Back_DeliverySystem.Models;

public class PickupLocation
{
    public int Id { get; set; }
    public int? CustomerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ContactName { get; set; } = string.Empty;
    public string ContactPhone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
}
