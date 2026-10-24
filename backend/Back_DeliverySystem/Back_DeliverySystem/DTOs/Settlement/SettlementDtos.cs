using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Settlement;

public class CreateSettlementRequest
{
    [Required(ErrorMessage = "Danh sách đơn hàng không được để trống.")]
    [MinLength(
        1,
        ErrorMessage =
            "Phải có ít nhất một đơn hàng để đối soát."
    )]
    public List<string> ShipmentIds { get; set; } =
        new();


    public long Adjustment { get; set; }


    [StringLength(
        500,
        ErrorMessage =
            "Lý do điều chỉnh không được vượt quá 500 ký tự."
    )]
    public string AdjustmentReason { get; set; } =
        string.Empty;
}


public class CompleteSettlementRequest
{
    [Required(
        ErrorMessage =
            "Mã tham chiếu thanh toán không được để trống."
    )]
    [StringLength(
        100,
        MinimumLength = 3,
        ErrorMessage =
            "Mã tham chiếu thanh toán phải từ 3 đến 100 ký tự."
    )]
    public string PaymentReference { get; set; } =
        string.Empty;
}