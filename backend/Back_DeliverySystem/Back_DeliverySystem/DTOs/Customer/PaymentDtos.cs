using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Customer;

public class CreateOnlinePaymentRequest
{
    [Required(
        ErrorMessage =
            "ShipmentId không được để trống."
    )]
    public string ShipmentId { get; set; } =
        string.Empty;
}


public class FailMockPaymentRequest
{
    [Required(
        ErrorMessage =
            "Vui lòng nhập lý do thanh toán thất bại."
    )]
    [StringLength(
        300,
        MinimumLength = 3,
        ErrorMessage =
            "Lý do phải từ 3 đến 300 ký tự."
    )]
    public string Reason { get; set; } =
        string.Empty;
}