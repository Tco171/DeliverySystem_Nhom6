using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Controllers;

[ApiController]
[Route("api/v1")]
public class OrderController : ControllerBase
{
    private readonly AppDbContext _db;

    public OrderController(AppDbContext db) => _db = db;

    [HttpPost("shipping-quotes")]
    public async Task<IActionResult> Quote([FromBody] ShipmentInput input)
    {
        var error = Validate(input);
        if (error != null) return BadRequest(new { message = error });

        var (fee, chargeableKg) = CalculateFee(input);

        if (input.FeePayer == "deduct_cod" && input.CodAmount < fee)
            return BadRequest(new { message = "COD không đủ để khấu trừ phí vận chuyển." });

        var quote = new ShippingQuote
        {
            Id = $"Q-{Guid.NewGuid():N}".ToUpperInvariant(),
            InputHash = Hash(input),
            Fee = fee,
            ExpiresAt = DateTime.UtcNow.AddMinutes(5),
            Used = false
        };

        _db.ShippingQuotes.Add(quote);
        await _db.SaveChangesAsync();

        return Ok(new
        {
            id = quote.Id,
            fee = quote.Fee,
            expiresAt = quote.ExpiresAt,
            chargeableWeightKg = chargeableKg
        });
    }

    [HttpPost("shipments")]
    public async Task<IActionResult> Create([FromBody] CreateShipmentRequest request)
    {
        var error = Validate(request);
        if (error != null) return BadRequest(new { message = error });

        var quote = await _db.ShippingQuotes
            .FirstOrDefaultAsync(x => x.Id == request.QuoteId);

        if (quote == null || quote.Used || quote.ExpiresAt <= DateTime.UtcNow ||
            quote.InputHash != Hash(request))
        {
            return Conflict(new { message = "Báo giá hết hạn hoặc thông tin đơn hàng đã thay đổi. Hãy tính lại phí." });
        }

        var now = DateTime.UtcNow;
        var shipment = new Shipment
        {
            Id = $"EXP-{Guid.NewGuid():N}".ToUpperInvariant(),
            CustomerId = GetCustomerId(),
            SenderName = request.SenderName.Trim(),
            SenderPhone = request.SenderPhone.Trim(),
            PickupAddress = request.PickupAddress.Trim(),
            RecipientName = request.RecipientName.Trim(),
            RecipientPhone = request.RecipientPhone.Trim(),
            DeliveryAddress = request.DeliveryAddress.Trim(),
            Goods = request.Goods.Trim(),
            WeightKg = request.WeightKg,
            LengthCm = request.LengthCm,
            WidthCm = request.WidthCm,
            HeightCm = request.HeightCm,
            DeclaredValue = request.DeclaredValue,
            CodAmount = request.CodAmount,
            Service = request.Service,
            FeePayer = request.FeePayer,
            Notes = request.Notes?.Trim() ?? string.Empty,
            Fee = quote.Fee,
            Status = "pending_pickup",
            Attempts = 0,
            CodCollected = 0,
            CreatedAt = now,
            Events = new List<ShipmentEvent>
            {
                new()
                {
                    Status = "pending_pickup",
                    At = now,
                    Note = "Đã xác nhận yêu cầu giao hàng."
                }
            }
        };

        quote.Used = true;
        _db.Shipments.Add(shipment);
        await _db.SaveChangesAsync();

        return Ok(await BuildShipmentResponse(shipment.Id));
    }

    [HttpGet("shipments")]
    public async Task<IActionResult> List()
    {
        IQueryable<Shipment> query = _db.Shipments
            .Include(x => x.Events)
            .AsNoTracking();

        var customerId = GetCustomerId();
        if (customerId.HasValue)
            query = query.Where(x => x.CustomerId == customerId);

        var shipments = await query
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
        return Ok(shipments.Select(ToResponse));
    }

    [HttpGet("shipments/{shipmentId}")]
    public async Task<IActionResult> Get(string shipmentId)
    {
        var shipment = await _db.Shipments
            .Include(x => x.Events)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == shipmentId);

        if (shipment == null)
            return NotFound(new { message = "Không tìm thấy vận đơn." });

        return Ok(ToResponse(shipment));
    }

    [HttpPost("shipments/{shipmentId}/events")]
    public async Task<IActionResult> Transition(string shipmentId, [FromBody] TransitionRequest request)
    {
        var shipment = await _db.Shipments
            .Include(x => x.Events)
            .FirstOrDefaultAsync(x => x.Id == shipmentId);

        if (shipment == null)
            return NotFound(new { message = "Không tìm thấy đơn hàng." });

        var allowed = new Dictionary<string, string[]>
        {
            ["pending_pickup"] = new[] { "pickup_failed", "picked_up" },
            ["pickup_failed"] = new[] { "pending_pickup", "picked_up" },
            ["picked_up"] = new[] { "in_transit", "at_hub" },
            ["in_transit"] = new[] { "at_hub", "out_for_delivery" },
            ["at_hub"] = new[] { "in_transit", "out_for_delivery" },
            ["out_for_delivery"] = new[] { "delivery_failed", "delivered" },
            ["delivery_failed"] = new[] { "out_for_delivery", "returning" },
            ["returning"] = new[] { "returned" },
            ["returned"] = new[] { "return_confirmed" },
            ["delivered"] = Array.Empty<string>(),
            ["return_confirmed"] = Array.Empty<string>()
        };

        if (!allowed.TryGetValue(shipment.Status, out var next) || !next.Contains(request.Status))
            return Conflict(new { message = "Chuyển trạng thái không hợp lệ." });

        if (new[] { "pickup_failed", "delivery_failed", "returning" }.Contains(request.Status)
            && string.IsNullOrWhiteSpace(request.Note))
            return BadRequest(new { message = "Vui lòng nhập lý do." });

        if (request.Status == "out_for_delivery" && shipment.Attempts >= 3)
            return Conflict(new { message = "Đơn hàng đã đạt giới hạn 3 lần giao. Vui lòng chuyển hoàn." });

        if (request.Status == "delivered" && shipment.CodAmount > 0 &&
            request.CodCollected != shipment.CodAmount)
            return BadRequest(new { message = "Cần xác nhận đã thu đủ tiền COD." });

        shipment.Status = request.Status;
        if (request.Status == "out_for_delivery") shipment.Attempts++;
        if (request.Status == "delivered") shipment.CodCollected = shipment.CodAmount;
        if (request.Status != "at_hub") shipment.CurrentHubId = null;

        shipment.Events.Add(new ShipmentEvent
        {
            ShipmentId = shipment.Id,
            Status = shipment.Status,
            At = DateTime.UtcNow,
            Note = request.Note?.Trim() ?? string.Empty
        });

        await _db.SaveChangesAsync();
        return Ok(ToResponse(shipment));
    }

    [HttpGet("pickup-locations")]
    public async Task<IActionResult> PickupLocations()
    {
        var query = _db.PickupLocations.AsNoTracking();
        var customerId = GetCustomerId();
        if (customerId.HasValue)
            query = query.Where(x => x.CustomerId == customerId);

        return Ok(await query.OrderBy(x => x.Name).ToListAsync());
    }

    [HttpPost("pickup-locations")]
    public async Task<IActionResult> CreatePickupLocation([FromBody] CreatePickupLocationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(request.ContactName) ||
            string.IsNullOrWhiteSpace(request.ContactPhone) ||
            string.IsNullOrWhiteSpace(request.Address))
            return BadRequest(new { message = "Vui lòng nhập đầy đủ thông tin điểm lấy hàng." });

        if (!System.Text.RegularExpressions.Regex.IsMatch(request.ContactPhone.Trim(), @"^\+?[0-9 ()-]{8,20}$"))
            return BadRequest(new { message = "Số điện thoại tại điểm lấy hàng không hợp lệ." });

        var customerId = GetCustomerId();
        var exists = await _db.PickupLocations.AnyAsync(x =>
            x.Name == request.Name.Trim() && x.CustomerId == customerId);
        if (exists)
            return Conflict(new { message = "Tên điểm lấy hàng đã tồn tại." });

        var location = new PickupLocation
        {
            CustomerId = customerId,
            Name = request.Name.Trim(),
            ContactName = request.ContactName.Trim(),
            ContactPhone = request.ContactPhone.Trim(),
            Address = request.Address.Trim()
        };

        _db.PickupLocations.Add(location);
        await _db.SaveChangesAsync();
        return Ok(location);
    }
    


    // Lấy lịch sử khiếu nại của một đơn hàng
    [HttpGet("shipments/{shipmentId}/complaints")]
    public async Task<IActionResult> GetComplaints(string shipmentId)
    {
        var shipment = await _db.Shipments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == shipmentId);

        if (shipment == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy đơn hàng."
            });
        }

        var customerId = GetCustomerId();

        // Nếu có UserId thì chỉ cho xem đơn của chính user đó
        if (customerId.HasValue &&
            shipment.CustomerId.HasValue &&
            shipment.CustomerId != customerId)
        {
            return Forbid();
        }

        var complaints = await _db.Complaints
            .AsNoTracking()
            .Where(x => x.ShipmentId == shipmentId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                x.ShipmentId,
                x.Type,
                x.Content,
                x.Status,
                x.Response,
                x.CreatedAt,
                x.ResolvedAt
            })
            .ToListAsync();

        return Ok(complaints);
    }


    // Tạo khiếu nại mới
    [HttpPost("shipments/{shipmentId}/complaints")]
    public async Task<IActionResult> CreateComplaint(
        string shipmentId,
        [FromBody] CreateComplaintRequest request)
    {
        // 1. Kiểm tra đơn hàng tồn tại
        var shipment = await _db.Shipments
            .FirstOrDefaultAsync(x => x.Id == shipmentId);

        if (shipment == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy đơn hàng."
            });
        }

        var customerId = GetCustomerId();

        // 2. Kiểm tra đơn có thuộc user hiện tại không
        if (customerId.HasValue &&
            shipment.CustomerId.HasValue &&
            shipment.CustomerId != customerId)
        {
            return Forbid();
        }

        // 3. Kiểm tra loại sự cố
        var allowedTypes = new[]
        {
        "damaged",
        "delayed",
        "lost",
        "wrong_item",
        "other"
    };

        if (string.IsNullOrWhiteSpace(request.Type) ||
            !allowedTypes.Contains(request.Type))
        {
            return BadRequest(new
            {
                message = "Loại sự cố không hợp lệ."
            });
        }

        // 4. Kiểm tra nội dung
        if (string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest(new
            {
                message = "Vui lòng nhập nội dung sự cố."
            });
        }

        var content = request.Content.Trim();

        if (content.Length < 10)
        {
            return BadRequest(new
            {
                message = "Nội dung sự cố phải có ít nhất 10 ký tự."
            });
        }

        if (content.Length > 2000)
        {
            return BadRequest(new
            {
                message = "Nội dung sự cố không được vượt quá 2000 ký tự."
            });
        }

        // 5. Tạo Complaint
        var complaint = new Complaint
        {
            ShipmentId = shipment.Id,
            CustomerId = customerId,
            Type = request.Type,
            Content = content,

            // Khi mới tạo luôn là chờ xử lý
            Status = "pending",

            CreatedAt = DateTime.UtcNow
        };

        // 6. Lưu database
        _db.Complaints.Add(complaint);

        await _db.SaveChangesAsync();

        // 7. Trả dữ liệu về frontend
        return Ok(new
        {
            complaint.Id,
            complaint.ShipmentId,
            complaint.Type,
            complaint.Content,
            complaint.Status,
            complaint.Response,
            complaint.CreatedAt,
            complaint.ResolvedAt
        });
    }
  

    // Lấy tất cả khiếu nại cho trang quản lý
    [HttpGet("complaints")]
    public async Task<IActionResult> GetAllComplaints()
    {
        var complaints = await _db.Complaints
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                x.Id,
                x.ShipmentId,
                x.Type,
                x.Content,
                x.Status,
                x.Response,
                x.CreatedAt,
                x.ResolvedAt
            })
            .ToListAsync();

        return Ok(complaints);
    }


    // Cập nhật trạng thái / kết quả xử lý khiếu nại
    [HttpPatch("complaints/{complaintId:int}")]
    public async Task<IActionResult> UpdateComplaint(
        int complaintId,
        [FromBody] UpdateComplaintRequest request)
    {
        var complaint = await _db.Complaints
            .FirstOrDefaultAsync(x => x.Id == complaintId);

        if (complaint == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy báo cáo sự cố."
            });
        }

        var status = request.Status?.Trim();

        if (status != "processing" &&
            status != "resolved")
        {
            return BadRequest(new
            {
                message = "Trạng thái xử lý không hợp lệ."
            });
        }

        // Chỉ cho phép:
        // pending -> processing
        // processing -> resolved

        if (complaint.Status == "pending" &&
            status != "processing")
        {
            return Conflict(new
            {
                message =
                    "Báo cáo phải được bắt đầu xử lý trước."
            });
        }

        if (complaint.Status == "processing" &&
            status != "resolved")
        {
            return Conflict(new
            {
                message =
                    "Báo cáo đang xử lý chỉ có thể chuyển sang đã giải quyết."
            });
        }

        if (complaint.Status == "resolved")
        {
            return Conflict(new
            {
                message =
                    "Báo cáo này đã được giải quyết."
            });
        }

        var response = request.Response?.Trim();

        if (status == "resolved" &&
            string.IsNullOrWhiteSpace(response))
        {
            return BadRequest(new
            {
                message =
                    "Vui lòng nhập kết quả giải quyết."
            });
        }

        if (response != null &&
            response.Length > 2000)
        {
            return BadRequest(new
            {
                message =
                    "Kết quả giải quyết không được vượt quá 2000 ký tự."
            });
        }

        complaint.Status = status;

        if (status == "processing")
        {
            complaint.Response = null;
            complaint.ResolvedAt = null;
        }

        if (status == "resolved")
        {
            complaint.Response = response;
            complaint.ResolvedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();

        return Ok(new
        {
            complaint.Id,
            complaint.ShipmentId,
            complaint.Type,
            complaint.Content,
            complaint.Status,
            complaint.Response,
            complaint.CreatedAt,
            complaint.ResolvedAt
        });
    }
    private int? GetCustomerId()
    {
        var value = Request.Headers["X-User-Id"].FirstOrDefault();
        return int.TryParse(value, out var id) ? id : null;
    }

    private static string? Validate(ShipmentInput input)
    {
        if (new[] { input.SenderName, input.SenderPhone, input.PickupAddress,
                    input.RecipientName, input.RecipientPhone, input.DeliveryAddress, input.Goods }
            .Any(string.IsNullOrWhiteSpace))
            return "Vui lòng điền đầy đủ thông tin bắt buộc.";

        var phone = new System.Text.RegularExpressions.Regex(@"^\+?[0-9 ()-]{8,20}$");
        if (!phone.IsMatch(input.SenderPhone.Trim()) || !phone.IsMatch(input.RecipientPhone.Trim()))
            return "Số điện thoại người gửi/người nhận không hợp lệ.";

        if (input.WeightKg <= 0 || input.LengthCm <= 0 || input.WidthCm <= 0 || input.HeightCm <= 0)
            return "Khối lượng và kích thước phải lớn hơn 0.";

        if (input.DeclaredValue < 0 || input.CodAmount < 0)
            return "Giá trị hàng và COD phải là số nguyên không âm.";

        if (input.Service is not ("standard" or "express"))
            return "Dịch vụ không hợp lệ.";

        if (input.FeePayer is not ("shop_prepaid" or "recipient" or "deduct_cod"))
            return "Hình thức thanh toán phí không hợp lệ.";

        return null;
    }

    private static (long fee, decimal chargeableKg) CalculateFee(ShipmentInput input)
    {
        const decimal includedWeightKg = 1m;
        const decimal volumetricDivisor = 5000m;

        var standardBase = input.Service == "standard" ? 25000L : 40000L;
        const long extraKgFee = 5000L;

        var volumetricKg = input.LengthCm * input.WidthCm * input.HeightCm / volumetricDivisor;
        var chargeableKg = Math.Max(input.WeightKg, volumetricKg);
        var extraKg = Math.Max(0, (int)Math.Ceiling(chargeableKg - includedWeightKg));
        return (checked(standardBase + extraKg * extraKgFee), chargeableKg);
    }

    private static string Hash(ShipmentInput input)
    {
        var json = JsonSerializer.Serialize(new
        {
            input.SenderName,
            input.SenderPhone,
            input.PickupAddress,
            input.RecipientName,
            input.RecipientPhone,
            input.DeliveryAddress,
            input.Goods,
            input.WeightKg,
            input.LengthCm,
            input.WidthCm,
            input.HeightCm,
            input.DeclaredValue,
            input.CodAmount,
            input.Service,
            input.FeePayer,
            Notes = input.Notes ?? string.Empty
        });

        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(json)));
    }

    private async Task<object?> BuildShipmentResponse(string id)
    {
        var shipment = await _db.Shipments
            .Include(x => x.Events)
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id);
        return shipment == null ? null : ToResponse(shipment);
    }

    private static object ToResponse(Shipment x) => new
    {
        x.Id,
        x.SenderName,
        x.SenderPhone,
        x.PickupAddress,
        x.RecipientName,
        x.RecipientPhone,
        x.DeliveryAddress,
        x.Goods,
        x.WeightKg,
        x.LengthCm,
        x.WidthCm,
        x.HeightCm,
        x.DeclaredValue,
        x.CodAmount,
        x.Service,
        x.FeePayer,
        x.Notes,
        x.CurrentHubId,
        x.Status,
        x.Fee,
        x.Attempts,
        x.CodCollected,
        x.CreatedAt,
        events = x.Events.OrderBy(e => e.At).Select(e => new
        {
            e.Status,
            e.At,
            e.Note
        })
    };
}
