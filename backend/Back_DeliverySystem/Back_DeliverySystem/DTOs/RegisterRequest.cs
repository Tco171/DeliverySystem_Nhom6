namespace Back_DeliverySystem.DTOs
{
    public class RegisterRequest
    {
        public string FullName { get; set; } = string.Empty;

        public string? ShopName { get; set; }

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;
    }
}
