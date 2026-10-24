using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Customer
{
    public class CreateVnPayPaymentRequest
    {
        [Required(ErrorMessage = "ShipmentId không được để trống.")]
        public string ShipmentId { get; set; } = string.Empty;
    }
}