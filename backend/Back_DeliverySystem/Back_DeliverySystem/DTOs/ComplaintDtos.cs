namespace Back_DeliverySystem.DTOs;

public class CreateComplaintRequest
{
    public string Type { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;
}

public class UpdateComplaintRequest
{
    public string Status { get; set; } = string.Empty;

    public string? Response { get; set; }
}