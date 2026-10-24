using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class CancelAssignmentRequest
    {
        [Required(
            ErrorMessage = "Vui lòng nhập lý do hủy phân công."
        )]
        [StringLength(
            300,
            MinimumLength = 3,
            ErrorMessage = "Lý do phải từ 3 đến 300 ký tự."
        )]
        public string Reason { get; set; } =
            string.Empty;
    }
}