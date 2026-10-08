using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Controllers;

[ApiController]
[Route("api/v1/settlements")]
public class SettlementsController : ControllerBase
{
    private readonly AppDbContext _db;

    public SettlementsController(AppDbContext db)
    {
        _db = db;
    }

    // =========================================================
    // GET /api/v1/settlements
    // Customer xem đối soát COD của chính mình
    // =========================================================
    [HttpGet]
    public async Task<IActionResult> GetSettlements()
    {
        var currentUser = await GetCurrentUserAsync();

        if (currentUser == null)
        {
            return Unauthorized(new
            {
                message = "Vui lòng đăng nhập."
            });
        }

        if (currentUser.Role != "customer" &&
            currentUser.Role != "operations")
        {
            return Forbid();
        }

        // Các shipment đã nằm trong SettlementLine
        var settledShipmentIds = await _db.SettlementLines
            .AsNoTracking()
            .Select(x => x.ShipmentId)
            .ToListAsync();

        // Các đơn COD đủ điều kiện đối soát
        IQueryable<Shipment> eligibleQuery = _db.Shipments
            .AsNoTracking()
            .Where(x =>
                x.Status == "delivered" &&
                x.CodCollected > 0 &&
                x.CustomerId != null &&
                !settledShipmentIds.Contains(x.Id));

        // Customer chỉ được xem đơn của chính mình
        if (currentUser.Role == "customer")
        {
            eligibleQuery = eligibleQuery
                .Where(x => x.CustomerId == currentUser.Id);
        }

        var eligibleShipments = await eligibleQuery
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                id = x.Id,
                codAmount = x.CodAmount,
                codCollected = x.CodCollected,
                fee = x.Fee,
                feePayer = x.FeePayer,
                shippingDeduction =
                    x.FeePayer == "deduct_cod"
                        ? x.Fee
                        : 0,
                netAmount =
                    x.CodCollected -
                    (x.FeePayer == "deduct_cod"
                        ? x.Fee
                        : 0),
                status = x.Status,
                createdAt = x.CreatedAt
            })
            .ToListAsync();

        // Lịch sử đối soát
        IQueryable<Settlement> settlementQuery = _db.Settlements
            .AsNoTracking()
            .Include(x => x.Lines);

        if (currentUser.Role == "customer")
        {
            settlementQuery = settlementQuery
                .Where(x => x.CustomerId == currentUser.Id);
        }

        var settlements = await settlementQuery
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new
            {
                id = x.Id,
                customerId = x.CustomerId,
                totalCod = x.TotalCod,
                shippingDeduction = x.ShippingDeduction,
                adjustment = x.Adjustment,
                adjustmentReason = x.AdjustmentReason,
                netAmount = x.NetAmount,
                status = x.Status,
                createdAt = x.CreatedAt,
                completedAt = x.CompletedAt,
                paymentReference = x.PaymentReference,
                lines = x.Lines.Select(line => new
                {
                    line.Id,
                    line.ShipmentId,
                    line.CodCollected,
                    line.ShippingDeduction
                })
            })
            .ToListAsync();

        return Ok(new
        {
            eligibleShipments,
            settlements
        });
    }

    // =========================================================
    // POST /api/v1/settlements
    // Operations tạo một đợt đối soát
    // =========================================================
    [HttpPost]
    public async Task<IActionResult> CreateSettlement(
        [FromBody] CreateSettlementRequest request)
    {
        var currentUser = await GetCurrentUserAsync();

        if (currentUser == null)
        {
            return Unauthorized(new
            {
                message = "Vui lòng đăng nhập."
            });
        }

        if (currentUser.Role != "operations")
        {
            return Forbid();
        }

        if (request.ShipmentIds == null ||
            request.ShipmentIds.Count == 0)
        {
            return BadRequest(new
            {
                message = "Vui lòng chọn ít nhất một đơn hàng để đối soát."
            });
        }

        var shipmentIds = request.ShipmentIds
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct()
            .ToList();

        if (shipmentIds.Count == 0)
        {
            return BadRequest(new
            {
                message = "Danh sách đơn hàng không hợp lệ."
            });
        }

        // Kiểm tra các đơn đã tồn tại
        var shipments = await _db.Shipments
            .Where(x => shipmentIds.Contains(x.Id))
            .ToListAsync();

        if (shipments.Count != shipmentIds.Count)
        {
            return BadRequest(new
            {
                message = "Có đơn hàng không tồn tại."
            });
        }

        // Kiểm tra đơn đã được đối soát trước đó chưa
        var alreadySettled = await _db.SettlementLines
            .Where(x => shipmentIds.Contains(x.ShipmentId))
            .Select(x => x.ShipmentId)
            .ToListAsync();

        if (alreadySettled.Count > 0)
        {
            return Conflict(new
            {
                message = "Có đơn hàng đã được đưa vào đối soát trước đó.",
                shipmentIds = alreadySettled
            });
        }

        // Chỉ cho phép đơn delivered + đã thu COD
        var invalidShipments = shipments
            .Where(x =>
                x.Status != "delivered" ||
                x.CodCollected <= 0 ||
                x.CustomerId == null)
            .Select(x => x.Id)
            .ToList();

        if (invalidShipments.Count > 0)
        {
            return Conflict(new
            {
                message =
                    "Chỉ được đối soát các đơn đã giao thành công và đã thu COD.",
                shipmentIds = invalidShipments
            });
        }

        // Một đợt settlement chỉ nên thuộc về một customer
        var customerIds = shipments
            .Select(x => x.CustomerId!.Value)
            .Distinct()
            .ToList();

        if (customerIds.Count != 1)
        {
            return BadRequest(new
            {
                message =
                    "Các đơn trong một đợt đối soát phải thuộc cùng một khách hàng."
            });
        }

        var customerId = customerIds[0];

        long totalCod = 0;
        long shippingDeduction = 0;

        var lines = new List<SettlementLine>();

        foreach (var shipment in shipments)
        {
            var deduction =
                shipment.FeePayer == "deduct_cod"
                    ? shipment.Fee
                    : 0;

            totalCod += shipment.CodCollected;
            shippingDeduction += deduction;

            lines.Add(new SettlementLine
            {
                ShipmentId = shipment.Id,
                CodCollected = shipment.CodCollected,
                ShippingDeduction = deduction
            });
        }

        var netAmount =
            totalCod -
            shippingDeduction +
            request.Adjustment;

        if (netAmount < 0)
        {
            return BadRequest(new
            {
                message = "Số tiền thực nhận không thể nhỏ hơn 0."
            });
        }

        var settlement = new Settlement
        {
            Id = $"SET-{Guid.NewGuid():N}".ToUpperInvariant(),
            CustomerId = customerId,
            TotalCod = totalCod,
            ShippingDeduction = shippingDeduction,
            Adjustment = request.Adjustment,
            AdjustmentReason =
                request.AdjustmentReason?.Trim() ?? string.Empty,
            NetAmount = netAmount,
            Status = "pending",
            CreatedAt = DateTime.UtcNow,
            Lines = lines
        };

        _db.Settlements.Add(settlement);

        await _db.SaveChangesAsync();

        return Ok(new
        {
            id = settlement.Id,
            customerId = settlement.CustomerId,
            totalCod = settlement.TotalCod,
            shippingDeduction = settlement.ShippingDeduction,
            adjustment = settlement.Adjustment,
            adjustmentReason = settlement.AdjustmentReason,
            netAmount = settlement.NetAmount,
            status = settlement.Status,
            createdAt = settlement.CreatedAt,
            completedAt = settlement.CompletedAt,
            paymentReference = settlement.PaymentReference,
            lines = settlement.Lines.Select(x => new
            {
                x.Id,
                x.ShipmentId,
                x.CodCollected,
                x.ShippingDeduction
            })
        });
    }

   
    // POST /api/v1/settlements/{id}/complete
    // Operations xác nhận đã thanh toán
  
    [HttpPost("{id}/complete")]
    public async Task<IActionResult> CompleteSettlement(
        string id,
        [FromBody] CompleteSettlementRequest request)
    {
        var currentUser = await GetCurrentUserAsync();

        if (currentUser == null)
        {
            return Unauthorized(new
            {
                message = "Vui lòng đăng nhập."
            });
        }

        if (currentUser.Role != "operations")
        {
            return Forbid();
        }

        var settlement = await _db.Settlements
            .Include(x => x.Lines)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (settlement == null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy đợt đối soát."
            });
        }

        if (settlement.Status == "completed")
        {
            return Conflict(new
            {
                message = "Đợt đối soát này đã được thanh toán."
            });
        }

        if (settlement.Status != "pending")
        {
            return Conflict(new
            {
                message = "Trạng thái đối soát không hợp lệ."
            });
        }

        var paymentReference =
            request.PaymentReference?.Trim() ?? string.Empty;

        if (string.IsNullOrWhiteSpace(paymentReference))
        {
            return BadRequest(new
            {
                message = "Vui lòng nhập mã tham chiếu thanh toán."
            });
        }

        settlement.Status = "completed";
        settlement.CompletedAt = DateTime.UtcNow;
        settlement.PaymentReference = paymentReference;

        await _db.SaveChangesAsync();

        return Ok(new
        {
            id = settlement.Id,
            customerId = settlement.CustomerId,
            totalCod = settlement.TotalCod,
            shippingDeduction = settlement.ShippingDeduction,
            adjustment = settlement.Adjustment,
            adjustmentReason = settlement.AdjustmentReason,
            netAmount = settlement.NetAmount,
            status = settlement.Status,
            createdAt = settlement.CreatedAt,
            completedAt = settlement.CompletedAt,
            paymentReference = settlement.PaymentReference,
            lines = settlement.Lines.Select(x => new
            {
                x.Id,
                x.ShipmentId,
                x.CodCollected,
                x.ShippingDeduction
            })
        });
    }

   
    // Lấy user hiện tại từ X-User-Id
   
    private async Task<User?> GetCurrentUserAsync()
    {
        var value = Request.Headers["X-User-Id"].FirstOrDefault();

        if (!int.TryParse(value, out var id))
            return null;

        return await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id);
    }
}