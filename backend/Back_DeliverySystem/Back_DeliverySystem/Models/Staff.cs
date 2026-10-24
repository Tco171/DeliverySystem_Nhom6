namespace Back_DeliverySystem.Models
{
    public class Staff
    {
        public int Id { get; set; }

        // Liên kết với tài khoản đăng nhập
        public int UserId { get; set; }

        // Mã nhân viên, ví dụ STF0001
        public string EmployeeCode { get; set; } = string.Empty;

        // Khu vực đang phụ trách
        public string? Area { get; set; }

        // available / busy / inactive
        public string Status { get; set; } = "available";

        // Có sẵn sàng nhận đơn hay không
        public bool IsAvailable { get; set; } = true;

        public DateTime CreatedAt { get; set; } =
            DateTime.UtcNow;
    }
}