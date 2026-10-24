using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace Back_DeliverySystem.Controllers.Auth
{
    [ApiController]
    [Route("api/v1/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(
            AppDbContext context,
            IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // =========================================================
        // REGISTER
        // Chỉ đăng ký tài khoản Customer
        // =========================================================
        [HttpPost("register")]
        public async Task<IActionResult> Register(
            [FromBody] RegisterRequest request)
        {
            // Kiểm tra dữ liệu bắt buộc
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

            var fullName = request.FullName.Trim();

            var email = request.Email
                .Trim()
                .ToLowerInvariant();

            var phone = request.Phone.Trim();

            // Kiểm tra số điện thoại
            if (!System.Text.RegularExpressions.Regex.IsMatch(
                    phone,
                    @"^0[0-9]{9}$"))
            {
                return BadRequest(new
                {
                    message =
                        "Số điện thoại phải gồm 10 số và bắt đầu bằng số 0."
                });
            }

            // Kiểm tra định dạng email
            if (!System.Text.RegularExpressions.Regex.IsMatch(
                    email,
                    @"^[^\s@]+@[^\s@]+\.[^\s@]+$"))
            {
                return BadRequest(new
                {
                    message = "Email không hợp lệ."
                });
            }

            // Kiểm tra mật khẩu
            if (request.Password.Length < 8)
            {
                return BadRequest(new
                {
                    message =
                        "Mật khẩu phải có ít nhất 8 ký tự."
                });
            }

            // Kiểm tra email đã tồn tại
            var existedUser = await _context.Users
                .AnyAsync(x => x.Email == email);

            if (existedUser)
            {
                return Conflict(new
                {
                    message = "Email đã tồn tại."
                });
            }

            // Kiểm tra số điện thoại đã tồn tại
            var existedPhone = await _context.Users
                .AnyAsync(x => x.Phone == phone);

            if (existedPhone)
            {
                return Conflict(new
                {
                    message = "Số điện thoại đã tồn tại."
                });
            }

            // Có tên shop => Business
            // Không có tên shop => Personal
            var hasShop =
                !string.IsNullOrWhiteSpace(request.ShopName);

            var user = new User
            {
                FullName = fullName,

                ShopName = hasShop
                    ? request.ShopName!.Trim()
                    : null,

                Phone = phone,

                Email = email,

                PasswordHash =
                    HashPassword(request.Password),

                // Người dùng đăng ký công khai
                // luôn là Customer
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
                message = "Đăng ký thành công.",

                id = user.Id.ToString(),

                name = user.FullName,

                role = user.Role,

                accountType = user.AccountType
            });
        }

        // =========================================================
        // LOGIN
        // =========================================================
        [HttpPost("login")]
        public async Task<IActionResult> Login(
            [FromBody] LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new
                {
                    message =
                        "Vui lòng nhập email và mật khẩu."
                });
            }

            var email = request.Email
                .Trim()
                .ToLowerInvariant();

            var user = await _context.Users
                .FirstOrDefaultAsync(
                    x => x.Email == email
                );

            if (user == null)
            {
                return Unauthorized(new
                {
                    message =
                        "Email hoặc mật khẩu không đúng."
                });
            }

            var passwordHash =
                HashPassword(request.Password);

            if (user.PasswordHash != passwordHash)
            {
                return Unauthorized(new
                {
                    message =
                        "Email hoặc mật khẩu không đúng."
                });
            }

            // Tạo JWT Token
            var token = GenerateToken(user);

            return Ok(new
            {
                message = "Đăng nhập thành công",

                token,

                id = user.Id.ToString(),

                name = user.FullName,

                role = user.Role,

                accountType = user.AccountType
            });
        }

        // =========================================================
        // LOGOUT
        // =========================================================
        [HttpPost("logout")]
        public IActionResult Logout()
        {
            /*
             * JWT là stateless.
             *
             * Backend không lưu session nên logout chủ yếu
             * là frontend xóa token khỏi localStorage /
             * secure storage.
             */

            return Ok(new
            {
                success = true,
                message = "Đăng xuất thành công."
            });
        }

        // =========================================================
        // GENERATE JWT TOKEN
        // =========================================================
        private string GenerateToken(User user)
        {
            var jwt =
                _configuration.GetSection("Jwt");

            var jwtKey = jwt["Key"];

            var jwtIssuer = jwt["Issuer"];

            var jwtAudience = jwt["Audience"];

            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException(
                    "JWT Key chưa được cấu hình trong appsettings.json."
                );
            }

            var claims = new List<Claim>
            {
                // User ID
                new Claim(
                    ClaimTypes.NameIdentifier,
                    user.Id.ToString()
                ),

                // Họ tên
                new Claim(
                    ClaimTypes.Name,
                    user.FullName
                ),

                // Email
                new Claim(
                    ClaimTypes.Email,
                    user.Email
                ),

                // Role
                new Claim(
                    ClaimTypes.Role,
                    user.Role
                )
            };

            var key =
                new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtKey)
                );

            var credentials =
                new SigningCredentials(
                    key,
                    SecurityAlgorithms.HmacSha256
                );

            var expireMinutes = 120;

            if (int.TryParse(
                    jwt["ExpireMinutes"],
                    out var configuredExpireMinutes))
            {
                expireMinutes =
                    configuredExpireMinutes;
            }

            var token =
                new JwtSecurityToken(
                    issuer: jwtIssuer,
                    audience: jwtAudience,
                    claims: claims,
                    notBefore: DateTime.UtcNow,
                    expires:
                        DateTime.UtcNow.AddMinutes(
                            expireMinutes
                        ),
                    signingCredentials: credentials
                );

            return new JwtSecurityTokenHandler()
                .WriteToken(token);
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