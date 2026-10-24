using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class UpdateStaffRequest
    {
        [Required(ErrorMessage = "Họ tên không được để trống.")]
        [StringLength(
            100,
            MinimumLength = 2,
            ErrorMessage = "Họ tên phải từ 2 đến 100 ký tự."
        )]
        public string FullName { get; set; } =
            string.Empty;


        [Required(ErrorMessage = "Số điện thoại không được để trống.")]
        [RegularExpression(
            @"^0[0-9]{9}$",
            ErrorMessage =
                "Số điện thoại phải gồm 10 số và bắt đầu bằng 0."
        )]
        public string Phone { get; set; } =
            string.Empty;


        [Required(ErrorMessage = "Email không được để trống.")]
        [EmailAddress(
            ErrorMessage = "Email không hợp lệ."
        )]
        [StringLength(150)]
        public string Email { get; set; } =
            string.Empty;


        [StringLength(
            100,
            ErrorMessage =
                "Khu vực không được vượt quá 100 ký tự."
        )]
        public string? Area { get; set; }
    }
}