namespace Back_DeliverySystem.Models
{
    public class User
    {
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string? ShopName { get; set; }

        public string Phone { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        // Quyền sử dụng hệ thống
        public string Role { get; set; } = "customer";

        // personal hoặc business
        public string AccountType { get; set; } = "personal";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
