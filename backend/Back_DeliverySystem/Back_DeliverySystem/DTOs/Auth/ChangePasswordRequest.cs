using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Auth
{
    public class ChangePasswordRequest
    {
        [Required(ErrorMessage = "Mật khẩu hiện tại không được để trống.")]
        public string CurrentPassword { get; set; } =
            string.Empty;

        [Required(ErrorMessage = "Mật khẩu mới không được để trống.")]
        [MinLength(
            8,
            ErrorMessage = "Mật khẩu mới phải có ít nhất 8 ký tự."
        )]
        [MaxLength(
            100,
            ErrorMessage = "Mật khẩu mới không được vượt quá 100 ký tự."
        )]
        public string NewPassword { get; set; } =
            string.Empty;
    }
}   