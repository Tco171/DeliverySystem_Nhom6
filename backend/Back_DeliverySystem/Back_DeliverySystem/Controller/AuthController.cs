using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace Back_DeliverySystem.Controllers
{
    [ApiController]
    [Route("api/v1/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName) ||
                string.IsNullOrWhiteSpace(request.Phone) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập đầy đủ thông tin."
                });
            }

            var email = request.Email.Trim().ToLower();
            var phone = request.Phone.Trim();

            if (!System.Text.RegularExpressions.Regex.IsMatch(phone, @"^0[0-9]{9}$"))
            {
                return BadRequest(new
                {
                    message = "Số điện thoại phải gồm 10 số và bắt đầu bằng số 0."
                });
            }

            var existedUser = await _context.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (existedUser != null)
            {
                return BadRequest(new
                {
                    message = "Email đã tồn tại."
                });
            }

            var existedPhone = await _context.Users
                .FirstOrDefaultAsync(x => x.Phone == phone);

            if (existedPhone != null)
            {
                return BadRequest(new
                {
                    message = "Số điện thoại đã tồn tại."
                });
            }

            var hasShop = !string.IsNullOrWhiteSpace(request.ShopName);

            var user = new User
            {
                FullName = request.FullName.Trim(),

                ShopName = hasShop
                    ? request.ShopName!.Trim()
                    : null,

                Phone = phone,
                Email = email,
                PasswordHash = HashPassword(request.Password),

                Role = "customer",

                AccountType = hasShop
                    ? "business"
                    : "personal",

                CreatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                id = user.Id.ToString(),
                name = user.FullName,
                role = user.Role,
                accountType = user.AccountType
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

        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new
                {
                    message = "Vui lòng nhập email và mật khẩu."
                });
            }

            var email = request.Email.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user == null)
            {
                return Unauthorized(new
                {
                    message = "Email hoặc mật khẩu không đúng."
                });
            }

            var passwordHash = HashPassword(request.Password);

            if (user.PasswordHash != passwordHash)
            {
                return Unauthorized(new
                {
                    message = "Email hoặc mật khẩu không đúng."
                });
            }

            return Ok(new
            { message = "Đăng nhập thành công",
                id = user.Id.ToString(),
                name = user.FullName,
                role = user.Role,
                accountType = user.AccountType
            });
        }

        [HttpPost("logout")]
        public IActionResult Logout()
        {
            return Ok(new
            {
                success = true
            });
        }
    }
}