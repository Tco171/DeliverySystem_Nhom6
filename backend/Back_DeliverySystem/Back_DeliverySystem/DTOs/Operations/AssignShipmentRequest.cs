using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class AssignShipmentRequest
    {
        [Range(
            1,
            int.MaxValue,
            ErrorMessage =
                "StaffId không hợp lệ."
        )]
        public int StaffId { get; set; }
    }
}