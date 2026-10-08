using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace Back_DeliverySystem.Controllers
{
    [ApiController]
    [Route("api/v1/account")]
    public class AccountController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AccountController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("me")]
        public async Task<IActionResult> GetMe()
        {
            var userIdHeader =
                Request.Headers["X-User-Id"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(userIdHeader))
            {
                return Unauthorized(new
                {
                    message = "Vui lòng đăng nhập."
                });
            }

            if (!int.TryParse(userIdHeader, out var userId))
            {
                return Unauthorized(new
                {
                    message = "Thông tin đăng nhập không hợp lệ."
                });
            }

            var user = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == userId);

            if (user == null)
            {
                return NotFound(new
                {
                    message = "Không tìm thấy tài khoản."
                });
            }

            return Ok(new
            {
                id = user.Id,
                fullName = user.FullName,
                name = user.FullName,
                email = user.Email,
                phone = user.Phone,
                shopName = user.ShopName,
                accountType = user.AccountType,
                role = user.Role,
                createdAt = user.CreatedAt
            });
        }

        [HttpPut("me")]
        public async Task<IActionResult> UpdateMe(
            [FromBody] UpdateAccountRequest request)
        {
            var userIdHeader =
                Request.Headers["X-User-Id"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(userIdHeader))
            {
                return Unauthorized(new
                {
                    message = "Vui lòng đăng nhập."
                });
            }

            if (!int.TryParse(userIdHeader, out var userId))
            {
                return Unauthorized(new
                {
                    message = "Thông tin đăng nhập không hợp lệ."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Id == userId);

            if (user == null)
            {
                return NotFound(new
                {
                    message = "Không tìm thấy tài khoản."
                });
            }

            var fullName =
                request.FullName?.Trim() ?? string.Empty;

            var email =
                request.Email?.Trim().ToLowerInvariant()
                ?? string.Empty;

            var phone =
                request.Phone?.Trim() ?? string.Empty;

            var shopName =
                request.ShopName?.Trim();

            if (string.IsNullOrWhiteSpace(fullName))
            {
                return BadRequest(new
                {
                    message = "Họ và tên không được để trống."
                });
            }

            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest(new
                {
                    message = "Email không được để trống."
                });
            }

            if (!System.Text.RegularExpressions.Regex.IsMatch(
                    email,
                    @"^[^\s@]+@[^\s@]+\.[^\s@]+$"))
            {
                return BadRequest(new
                {
                    message = "Email không hợp lệ."
                });
            }

            if (!System.Text.RegularExpressions.Regex.IsMatch(
                    phone,
                    @"^0[0-9]{9}$"))
            {
                return BadRequest(new
                {
                    message =
                        "Số điện thoại phải gồm 10 số và bắt đầu bằng 0."
                });
            }

            var emailExists =
                await _context.Users.AnyAsync(
                    x =>
                        x.Id != user.Id &&
                        x.Email == email
                );

            if (emailExists)
            {
                return Conflict(new
                {
                    message = "Email này đã được sử dụng."
                });
            }

            var phoneExists =
                await _context.Users.AnyAsync(
                    x =>
                        x.Id != user.Id &&
                        x.Phone == phone
                );

            if (phoneExists)
            {
                return Conflict(new
                {
                    message =
                        "Số điện thoại này đã được sử dụng."
                });
            }

            user.FullName = fullName;
            user.Email = email;
            user.Phone = phone;

            if (user.AccountType == "business")
            {
                user.ShopName =
                    string.IsNullOrWhiteSpace(shopName)
                        ? null
                        : shopName;
            }
            else
            {
                user.ShopName = null;
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Cập nhật thông tin thành công.",
                id = user.Id,
                fullName = user.FullName,
                name = user.FullName,
                email = user.Email,
                phone = user.Phone,
                shopName = user.ShopName,
                accountType = user.AccountType,
                role = user.Role,
                createdAt = user.CreatedAt
            });
        }

        private static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();

            var bytes = sha256.ComputeHash(
                Encoding.UTF8.GetBytes(password)
            );

            return Convert.ToHexString(bytes);
        }

        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword(
        [FromBody] ChangePasswordRequest request)
        {
            var userIdHeader =
                Request.Headers["X-User-Id"].FirstOrDefault();

            if (string.IsNullOrWhiteSpace(userIdHeader))
            {
                return Unauthorized(new
                {
                    message = "Vui lòng đăng nhập."
                });
            }

            if (!int.TryParse(userIdHeader, out var userId))
            {
                return Unauthorized(new
                {
                    message = "Thông tin đăng nhập không hợp lệ."
                });
            }

            if (string.IsNullOrWhiteSpace(request.CurrentPassword))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập mật khẩu hiện tại."
                });
            }

            if (string.IsNullOrWhiteSpace(request.NewPassword))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập mật khẩu mới."
                });
            }

            if (request.NewPassword.Length < 8)
            {
                return BadRequest(new
                {
                    message = "Mật khẩu mới phải có ít nhất 8 ký tự."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Id == userId);

            if (user == null)
            {
                return NotFound(new
                {
                    message = "Không tìm thấy tài khoản."
                });
            }

            var currentHash =
                HashPassword(request.CurrentPassword);

            if (user.PasswordHash != currentHash)
            {
                return BadRequest(new
                {
                    message = "Mật khẩu hiện tại không đúng."
                });
            }

            var newHash =
                HashPassword(request.NewPassword);

            if (newHash == user.PasswordHash)
            {
                return BadRequest(new
                {
                    message = "Mật khẩu mới phải khác mật khẩu hiện tại."
                });
            }

            user.PasswordHash = newHash;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Đổi mật khẩu thành công."
            });
        }
    }
}