using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs.Settlement;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Back_DeliverySystem.Controllers;

[ApiController]
[Route("api/v1/settlements")]
[Authorize(Roles = "customer,operations")]
public class SettlementsController : ControllerBase
{
    private readonly AppDbContext _db;

    public SettlementsController(AppDbContext db)
    {
        _db = db;
    }


    // =========================================================
    // USER ID TỪ JWT
    // =========================================================
    private int? GetCurrentUserId()
    {
        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier
            );

        if (!int.TryParse(value, out var id))
        {
            return null;
        }

        return id;
    }


    // =========================================================
    // GET /api/v1/settlements
    // Customer: xem đối soát của chính mình
    // Operations: xem toàn bộ
    // =========================================================
    [HttpGet]
    public async Task<IActionResult> GetSettlements()
    {
        var currentUserId =
            GetCurrentUserId();

        if (currentUserId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }

        var role =
            User.FindFirstValue(
                ClaimTypes.Role
            );


        var settledShipmentIds =
            await _db.SettlementLines
                .AsNoTracking()
                .Select(x => x.ShipmentId)
                .ToListAsync();


        IQueryable<Shipment> eligibleQuery =
            _db.Shipments
                .AsNoTracking()
                .Where(x =>
                    x.Status == "delivered" &&
                    x.CodCollected > 0 &&
                    x.CustomerId != null &&
                    !settledShipmentIds.Contains(x.Id)
                );


        if (role == "customer")
        {
            eligibleQuery =
                eligibleQuery.Where(
                    x =>
                        x.CustomerId ==
                        currentUserId.Value
                );
        }


        var eligibleShipments =
            await eligibleQuery
                .OrderByDescending(
                    x => x.CreatedAt
                )
                .Select(x => new
                {
                    id = x.Id,

                    customerId =
                        x.CustomerId,

                    codAmount =
                        x.CodAmount,

                    codCollected =
                        x.CodCollected,

                    fee =
                        x.Fee,

                    feePayer =
                        x.FeePayer,

                    shippingDeduction =
                        x.FeePayer == "deduct_cod"
                            ? x.Fee
                            : 0,

                    netAmount =
                        x.CodCollected -
                        (
                            x.FeePayer == "deduct_cod"
                                ? x.Fee
                                : 0
                        ),

                    status =
                        x.Status,

                    createdAt =
                        x.CreatedAt
                })
                .ToListAsync();


        IQueryable<Settlement> settlementQuery =
            _db.Settlements
                .AsNoTracking()
                .Include(x => x.Lines);


        if (role == "customer")
        {
            settlementQuery =
                settlementQuery.Where(
                    x =>
                        x.CustomerId ==
                        currentUserId.Value
                );
        }


        var settlements =
            await settlementQuery
                .OrderByDescending(
                    x => x.CreatedAt
                )
                .Select(x => new
                {
                    id =
                        x.Id,

                    customerId =
                        x.CustomerId,

                    totalCod =
                        x.TotalCod,

                    shippingDeduction =
                        x.ShippingDeduction,

                    adjustment =
                        x.Adjustment,

                    adjustmentReason =
                        x.AdjustmentReason,

                    netAmount =
                        x.NetAmount,

                    status =
                        x.Status,

                    createdAt =
                        x.CreatedAt,

                    completedAt =
                        x.CompletedAt,

                    paymentReference =
                        x.PaymentReference,

                    lines =
                        x.Lines.Select(
                            line => new
                            {
                                line.Id,
                                line.ShipmentId,
                                line.CodCollected,
                                line.ShippingDeduction
                            }
                        )
                })
                .ToListAsync();


        return Ok(new
        {
            eligibleShipments,
            settlements
        });
    }


    // =========================================================
    // GET /api/v1/settlements/eligible-shipments
    // =========================================================
    [HttpGet("eligible-shipments")]
    public async Task<IActionResult>
        GetEligibleShipments()
    {
        var currentUserId =
            GetCurrentUserId();

        if (currentUserId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }


        var role =
            User.FindFirstValue(
                ClaimTypes.Role
            );


        var settledShipmentIds =
            await _db.SettlementLines
                .AsNoTracking()
                .Select(x => x.ShipmentId)
                .ToListAsync();


        IQueryable<Shipment> query =
            _db.Shipments
                .AsNoTracking()
                .Where(x =>
                    x.Status == "delivered" &&
                    x.CodCollected > 0 &&
                    x.CustomerId != null &&
                    !settledShipmentIds.Contains(x.Id)
                );


        if (role == "customer")
        {
            query =
                query.Where(
                    x =>
                        x.CustomerId ==
                        currentUserId.Value
                );
        }


        var shipments =
            await query
                .OrderByDescending(
                    x => x.CreatedAt
                )
                .Select(x => new
                {
                    id =
                        x.Id,

                    customerId =
                        x.CustomerId,

                    senderName =
                        x.SenderName,

                    recipientName =
                        x.RecipientName,

                    codAmount =
                        x.CodAmount,

                    codCollected =
                        x.CodCollected,

                    fee =
                        x.Fee,

                    feePayer =
                        x.FeePayer,

                    shippingDeduction =
                        x.FeePayer == "deduct_cod"
                            ? x.Fee
                            : 0,

                    expectedNet =
                        x.CodCollected -
                        (
                            x.FeePayer == "deduct_cod"
                                ? x.Fee
                                : 0
                        ),

                    status =
                        x.Status,

                    createdAt =
                        x.CreatedAt
                })
                .ToListAsync();


        return Ok(shipments);
    }


    // =========================================================
    // GET /api/v1/settlements/{id}
    // =========================================================
    [HttpGet("{id}")]
    public async Task<IActionResult>
        GetSettlementById(string id)
    {
        var currentUserId =
            GetCurrentUserId();

        if (currentUserId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }


        var role =
            User.FindFirstValue(
                ClaimTypes.Role
            );


        var settlement =
            await _db.Settlements
                .AsNoTracking()
                .Include(x => x.Lines)
                .FirstOrDefaultAsync(
                    x => x.Id == id
                );


        if (settlement == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đợt đối soát."
            });
        }


        if (role == "customer" &&
            settlement.CustomerId !=
            currentUserId.Value)
        {
            return Forbid();
        }


        return Ok(new
        {
            id =
                settlement.Id,

            customerId =
                settlement.CustomerId,

            totalCod =
                settlement.TotalCod,

            shippingDeduction =
                settlement.ShippingDeduction,

            adjustment =
                settlement.Adjustment,

            adjustmentReason =
                settlement.AdjustmentReason,

            netAmount =
                settlement.NetAmount,

            status =
                settlement.Status,

            createdAt =
                settlement.CreatedAt,

            completedAt =
                settlement.CompletedAt,

            paymentReference =
                settlement.PaymentReference,

            lines =
                settlement.Lines.Select(
                    x => new
                    {
                        x.Id,
                        x.ShipmentId,
                        x.CodCollected,
                        x.ShippingDeduction
                    }
                )
        });
    }


    // =========================================================
    // POST /api/v1/settlements
    // Operations tạo đối soát
    // =========================================================
    [HttpPost]
    [Authorize(Roles = "operations")]
    public async Task<IActionResult>
        CreateSettlement(
            [FromBody]
            CreateSettlementRequest request)
    {
        if (request.Adjustment != 0 &&
            string.IsNullOrWhiteSpace(
                request.AdjustmentReason))
        {
            return BadRequest(new
            {
                message =
                    "Phải nhập lý do khi có điều chỉnh đối soát."
            });
        }


        var shipmentIds =
            request.ShipmentIds
                .Where(
                    x =>
                        !string.IsNullOrWhiteSpace(x)
                )
                .Select(
                    x => x.Trim()
                )
                .Distinct()
                .ToList();


        if (shipmentIds.Count == 0)
        {
            return BadRequest(new
            {
                message =
                    "Danh sách đơn hàng không hợp lệ."
            });
        }


        var shipments =
            await _db.Shipments
                .Where(
                    x =>
                        shipmentIds.Contains(x.Id)
                )
                .ToListAsync();


        if (shipments.Count !=
            shipmentIds.Count)
        {
            return BadRequest(new
            {
                message =
                    "Có đơn hàng không tồn tại."
            });
        }


        var alreadySettled =
            await _db.SettlementLines
                .Where(
                    x =>
                        shipmentIds.Contains(
                            x.ShipmentId
                        )
                )
                .Select(
                    x => x.ShipmentId
                )
                .ToListAsync();


        if (alreadySettled.Count > 0)
        {
            return Conflict(new
            {
                message =
                    "Có đơn hàng đã được đưa vào đối soát trước đó.",

                shipmentIds =
                    alreadySettled
            });
        }


        var invalidShipments =
            shipments
                .Where(x =>
                    x.Status != "delivered" ||
                    x.CodCollected <= 0 ||
                    x.CustomerId == null
                )
                .Select(x => x.Id)
                .ToList();


        if (invalidShipments.Count > 0)
        {
            return Conflict(new
            {
                message =
                    "Chỉ được đối soát các đơn đã giao thành công và đã thu COD.",

                shipmentIds =
                    invalidShipments
            });
        }


        var customerIds =
            shipments
                .Select(
                    x =>
                        x.CustomerId!.Value
                )
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


        var customerId =
            customerIds[0];


        long totalCod = 0;

        long shippingDeduction = 0;


        var lines =
            new List<SettlementLine>();


        foreach (var shipment in shipments)
        {
            var deduction =
                shipment.FeePayer == "deduct_cod"
                    ? shipment.Fee
                    : 0;


            totalCod +=
                shipment.CodCollected;


            shippingDeduction +=
                deduction;


            lines.Add(
                new SettlementLine
                {
                    ShipmentId =
                        shipment.Id,

                    CodCollected =
                        shipment.CodCollected,

                    ShippingDeduction =
                        deduction
                }
            );
        }


        var netAmount =
            totalCod -
            shippingDeduction +
            request.Adjustment;


        if (netAmount < 0)
        {
            return BadRequest(new
            {
                message =
                    "Số tiền thực nhận không thể nhỏ hơn 0."
            });
        }


        var settlement =
            new Settlement
            {
                Id =
                    $"SET-{Guid.NewGuid():N}"
                        .ToUpperInvariant(),

                CustomerId =
                    customerId,

                TotalCod =
                    totalCod,

                ShippingDeduction =
                    shippingDeduction,

                Adjustment =
                    request.Adjustment,

                AdjustmentReason =
                    request.AdjustmentReason?
                        .Trim()
                    ?? string.Empty,

                NetAmount =
                    netAmount,

                Status =
                    "pending",

                CreatedAt =
                    DateTime.UtcNow,

                Lines =
                    lines
            };


        _db.Settlements.Add(
            settlement
        );


        await _db.SaveChangesAsync();


        return StatusCode(
            StatusCodes.Status201Created,
            new
            {
                message =
                    "Tạo đợt đối soát COD thành công.",

                settlement =
                    new
                    {
                        id =
                            settlement.Id,

                        customerId =
                            settlement.CustomerId,

                        totalCod =
                            settlement.TotalCod,

                        shippingDeduction =
                            settlement.ShippingDeduction,

                        adjustment =
                            settlement.Adjustment,

                        adjustmentReason =
                            settlement.AdjustmentReason,

                        netAmount =
                            settlement.NetAmount,

                        status =
                            settlement.Status,

                        createdAt =
                            settlement.CreatedAt,

                        lines =
                            settlement.Lines.Select(
                                x => new
                                {
                                    x.Id,
                                    x.ShipmentId,
                                    x.CodCollected,
                                    x.ShippingDeduction
                                }
                            )
                    }
            }
        );
    }


    // =========================================================
    // POST /api/v1/settlements/{id}/complete
    // Operations xác nhận chuyển tiền
    // =========================================================
    [HttpPost("{id}/complete")]
    [Authorize(Roles = "operations")]
    public async Task<IActionResult>
        CompleteSettlement(
            string id,
            [FromBody]
            CompleteSettlementRequest request)
    {
        var settlement =
            await _db.Settlements
                .Include(x => x.Lines)
                .FirstOrDefaultAsync(
                    x => x.Id == id
                );


        if (settlement == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đợt đối soát."
            });
        }


        if (settlement.Status ==
            "completed")
        {
            return Conflict(new
            {
                message =
                    "Đợt đối soát này đã được thanh toán."
            });
        }


        if (settlement.Status !=
            "pending")
        {
            return Conflict(new
            {
                message =
                    "Trạng thái đối soát không hợp lệ."
            });
        }


        var paymentReference =
            request.PaymentReference.Trim();


        var paymentReferenceExists =
            await _db.Settlements
                .AnyAsync(x =>
                    x.PaymentReference ==
                    paymentReference
                );


        if (paymentReferenceExists)
        {
            return Conflict(new
            {
                message =
                    "Mã tham chiếu thanh toán đã được sử dụng."
            });
        }


        settlement.Status =
            "completed";

        settlement.CompletedAt =
            DateTime.UtcNow;

        settlement.PaymentReference =
            paymentReference;


        await _db.SaveChangesAsync();


        return Ok(new
        {
            message =
                "Hoàn tất đối soát COD thành công.",

            settlement =
                new
                {
                    id =
                        settlement.Id,

                    customerId =
                        settlement.CustomerId,

                    totalCod =
                        settlement.TotalCod,

                    shippingDeduction =
                        settlement.ShippingDeduction,

                    adjustment =
                        settlement.Adjustment,

                    adjustmentReason =
                        settlement.AdjustmentReason,

                    netAmount =
                        settlement.NetAmount,

                    status =
                        settlement.Status,

                    createdAt =
                        settlement.CreatedAt,

                    completedAt =
                        settlement.CompletedAt,

                    paymentReference =
                        settlement.PaymentReference,

                    lines =
                        settlement.Lines.Select(
                            x => new
                            {
                                x.Id,
                                x.ShipmentId,
                                x.CodCollected,
                                x.ShippingDeduction
                            }
                        )
                }
        });
    }
}