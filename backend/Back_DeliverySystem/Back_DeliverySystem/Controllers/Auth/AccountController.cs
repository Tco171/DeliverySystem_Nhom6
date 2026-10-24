using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Back_DeliverySystem.Controllers.Auth
{
    [ApiController]
    [Route("api/v1/account")]
    [Authorize]
    public class AccountController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AccountController(AppDbContext context)
        {
            _context = context;
        }

        // =========================================================
        // LẤY USER ID TỪ JWT TOKEN
        // =========================================================
        private int? GetCurrentUserId()
        {
            var userIdClaim =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier
                );

            if (!int.TryParse(userIdClaim, out var userId))
            {
                return null;
            }

            return userId;
        }

        // =========================================================
        // GET CURRENT USER
        // GET: /api/v1/account/me
        // =========================================================
        [HttpGet("me")]
        public async Task<IActionResult> GetMe()
        {
            var userId = GetCurrentUserId();

            if (userId == null)
            {
                return Unauthorized(new
                {
                    message =
                        "Thông tin đăng nhập không hợp lệ."
                });
            }

            var user = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == userId.Value
                );

            if (user == null)
            {
                return NotFound(new
                {
                    message =
                        "Không tìm thấy tài khoản."
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

        // =========================================================
        // UPDATE CURRENT USER
        // PUT: /api/v1/account/me
        // =========================================================
        [HttpPut("me")]
        public async Task<IActionResult> UpdateMe(
            [FromBody] UpdateAccountRequest request)
        {
            var userId = GetCurrentUserId();

            if (userId == null)
            {
                return Unauthorized(new
                {
                    message =
                        "Thông tin đăng nhập không hợp lệ."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(
                    x => x.Id == userId.Value
                );

            if (user == null)
            {
                return NotFound(new
                {
                    message =
                        "Không tìm thấy tài khoản."
                });
            }

            var fullName =
                request.FullName?.Trim()
                ?? string.Empty;

            var email =
                request.Email?
                    .Trim()
                    .ToLowerInvariant()
                ?? string.Empty;

            var phone =
                request.Phone?.Trim()
                ?? string.Empty;

            var shopName =
                request.ShopName?.Trim();

            // =====================================================
            // VALIDATION
            // =====================================================

            if (string.IsNullOrWhiteSpace(fullName))
            {
                return BadRequest(new
                {
                    message =
                        "Họ và tên không được để trống."
                });
            }

            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest(new
                {
                    message =
                        "Email không được để trống."
                });
            }

            if (!System.Text.RegularExpressions.Regex.IsMatch(
                    email,
                    @"^[^\s@]+@[^\s@]+\.[^\s@]+$"))
            {
                return BadRequest(new
                {
                    message =
                        "Email không hợp lệ."
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

            // =====================================================
            // KIỂM TRA EMAIL TRÙNG
            // =====================================================

            var emailExists =
                await _context.Users
                    .AnyAsync(
                        x =>
                            x.Id != user.Id &&
                            x.Email == email
                    );

            if (emailExists)
            {
                return Conflict(new
                {
                    message =
                        "Email này đã được sử dụng."
                });
            }

            // =====================================================
            // KIỂM TRA PHONE TRÙNG
            // =====================================================

            var phoneExists =
                await _context.Users
                    .AnyAsync(
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

            // =====================================================
            // UPDATE
            // =====================================================

            user.FullName = fullName;
            user.Email = email;
            user.Phone = phone;

            // Chỉ Customer Business mới có ShopName
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
                message =
                    "Cập nhật thông tin thành công.",

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

        // =========================================================
        // CHANGE PASSWORD
        // PUT: /api/v1/account/change-password
        // =========================================================
        [HttpPut("change-password")]
        public async Task<IActionResult> ChangePassword(
            [FromBody] ChangePasswordRequest request)
        {
            var userId = GetCurrentUserId();

            if (userId == null)
            {
                return Unauthorized(new
                {
                    message =
                        "Thông tin đăng nhập không hợp lệ."
                });
            }

            // =====================================================
            // VALIDATION
            // =====================================================

            if (string.IsNullOrWhiteSpace(
                    request.CurrentPassword))
            {
                return BadRequest(new
                {
                    message =
                        "Vui lòng nhập mật khẩu hiện tại."
                });
            }

            if (string.IsNullOrWhiteSpace(
                    request.NewPassword))
            {
                return BadRequest(new
                {
                    message =
                        "Vui lòng nhập mật khẩu mới."
                });
            }

            if (request.NewPassword.Length < 8)
            {
                return BadRequest(new
                {
                    message =
                        "Mật khẩu mới phải có ít nhất 8 ký tự."
                });
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(
                    x => x.Id == userId.Value
                );

            if (user == null)
            {
                return NotFound(new
                {
                    message =
                        "Không tìm thấy tài khoản."
                });
            }

            // =====================================================
            // KIỂM TRA PASSWORD HIỆN TẠI
            // =====================================================

            var currentHash =
                HashPassword(
                    request.CurrentPassword
                );

            if (user.PasswordHash != currentHash)
            {
                return BadRequest(new
                {
                    message =
                        "Mật khẩu hiện tại không đúng."
                });
            }

            // =====================================================
            // KIỂM TRA PASSWORD MỚI
            // =====================================================

            var newHash =
                HashPassword(
                    request.NewPassword
                );

            if (newHash == user.PasswordHash)
            {
                return BadRequest(new
                {
                    message =
                        "Mật khẩu mới phải khác mật khẩu hiện tại."
                });
            }

            // =====================================================
            // UPDATE PASSWORD
            // =====================================================

            user.PasswordHash = newHash;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message =
                    "Đổi mật khẩu thành công."
            });
        }

        // =========================================================
        // HASH PASSWORD
        // =========================================================
        private static string HashPassword(
            string password)
        {
            using var sha256 =
                SHA256.Create();

            var bytes =
                sha256.ComputeHash(
                    Encoding.UTF8.GetBytes(password)
                );

            return Convert.ToHexString(bytes);
        }
    }
}