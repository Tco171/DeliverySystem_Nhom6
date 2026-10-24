using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs
{
    public class RegisterRequest
    {
        [Required(ErrorMessage = "Họ tên không được để trống.")]
        [StringLength(100, MinimumLength = 2)]
        public string FullName { get; set; } =
            string.Empty;


        [StringLength(100)]
        public string? ShopName { get; set; }


        [Required(ErrorMessage = "Số điện thoại không được để trống.")]
        [RegularExpression(
            @"^0[0-9]{9}$",
            ErrorMessage =
                "Số điện thoại phải gồm 10 số và bắt đầu bằng 0."
        )]
        public string Phone { get; set; } =
            string.Empty;


        [Required(ErrorMessage = "Email không được để trống.")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ.")]
        [StringLength(150)]
        public string Email { get; set; } =
            string.Empty;


        [Required(ErrorMessage = "Mật khẩu không được để trống.")]
        [MinLength(
            8,
            ErrorMessage =
                "Mật khẩu phải có ít nhất 8 ký tự."
        )]
        [MaxLength(100)]
        public string Password { get; set; } =
            string.Empty;
    }
}