using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Customer;

public class CreateDeliveryRatingRequest
{
    [Range(
        1,
        5,
        ErrorMessage =
            "Số sao đánh giá phải từ 1 đến 5."
    )]
    public int Score { get; set; }


    [StringLength(
        1000,
        ErrorMessage =
            "Nội dung đánh giá không được vượt quá 1000 ký tự."
    )]
    public string Comment { get; set; } =
        string.Empty;
}


public class UpdateDeliveryRatingRequest
{
    [Range(
        1,
        5,
        ErrorMessage =
            "Số sao đánh giá phải từ 1 đến 5."
    )]
    public int Score { get; set; }


    [StringLength(
        1000,
        ErrorMessage =
            "Nội dung đánh giá không được vượt quá 1000 ký tự."
    )]
    public string Comment { get; set; } =
        string.Empty;
}