namespace Back_DeliverySystem.DTOs
{
    public class UpdateAccountRequest
    {
        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string? ShopName { get; set; }
    }
}