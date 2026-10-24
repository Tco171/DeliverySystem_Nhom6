using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class ReassignShipmentRequest
    {
        [Range(
            1,
            int.MaxValue,
            ErrorMessage = "StaffId không hợp lệ."
        )]
        public int StaffId { get; set; }


        [Required(
            ErrorMessage = "Vui lòng nhập lý do đổi nhân viên."
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