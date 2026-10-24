using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class UpdateStaffStatusRequest
    {
        [Required(
            ErrorMessage =
                "Trạng thái không được để trống."
        )]
        public string Status { get; set; } =
            string.Empty;
    }
}