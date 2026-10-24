namespace Back_DeliverySystem.Models;

public class DeliveryRating
{
    public int Id { get; set; }

    public string ShipmentId { get; set; } =
        string.Empty;

    public int CustomerId { get; set; }

    // 1 -> 5 sao
    public int Score { get; set; }

    public string Comment { get; set; } =
        string.Empty;

    public DateTime CreatedAt { get; set; } =
        DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }
}