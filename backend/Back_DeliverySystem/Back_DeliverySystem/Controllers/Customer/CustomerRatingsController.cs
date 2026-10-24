using System.Security.Claims;
using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs.Customer;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Controllers.Customer;

[ApiController]
[Route(
    "api/v1/customer/shipments/{shipmentId}/rating"
)]
[Authorize(Roles = "customer")]
public class CustomerRatingsController : ControllerBase
{
    private readonly AppDbContext _db;

    public CustomerRatingsController(
        AppDbContext db)
    {
        _db = db;
    }


    // =========================================================
    // CUSTOMER ID TỪ JWT
    // =========================================================
    private int? GetCurrentCustomerId()
    {
        var value =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier
            );

        if (!int.TryParse(
                value,
                out var id))
        {
            return null;
        }

        return id;
    }


    // =========================================================
    // XEM ĐÁNH GIÁ CỦA SHIPMENT
    // GET:
    // /api/v1/customer/shipments/{shipmentId}/rating
    // =========================================================
    [HttpGet]
    public async Task<IActionResult> GetRating(
        string shipmentId)
    {
        var customerId =
            GetCurrentCustomerId();

        if (customerId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }


        var shipment =
            await _db.Shipments
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == shipmentId
                );

        if (shipment == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đơn hàng."
            });
        }


        if (shipment.CustomerId !=
            customerId.Value)
        {
            return Forbid();
        }


        var rating =
            await _db.DeliveryRatings
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x =>
                        x.ShipmentId ==
                        shipment.Id
                );


        if (rating == null)
        {
            return NotFound(new
            {
                message =
                    "Đơn hàng chưa được đánh giá."
            });
        }


        return Ok(new
        {
            id =
                rating.Id,

            shipmentId =
                rating.ShipmentId,

            score =
                rating.Score,

            comment =
                rating.Comment,

            createdAt =
                rating.CreatedAt,

            updatedAt =
                rating.UpdatedAt
        });
    }


    // =========================================================
    // TẠO ĐÁNH GIÁ
    // POST:
    // /api/v1/customer/shipments/{shipmentId}/rating
    // =========================================================
    [HttpPost]
    public async Task<IActionResult> CreateRating(
        string shipmentId,
        [FromBody]
        CreateDeliveryRatingRequest request)
    {
        var customerId =
            GetCurrentCustomerId();

        if (customerId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }


        var shipment =
            await _db.Shipments
                .FirstOrDefaultAsync(
                    x => x.Id == shipmentId
                );


        if (shipment == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đơn hàng."
            });
        }


        // Customer chỉ được đánh giá
        // đơn của chính mình
        if (shipment.CustomerId !=
            customerId.Value)
        {
            return Forbid();
        }


        // Chỉ đánh giá sau khi giao thành công
        if (shipment.Status != "delivered")
        {
            return Conflict(new
            {
                message =
                    "Chỉ có thể đánh giá sau khi đơn hàng đã được giao thành công."
            });
        }


        var exists =
            await _db.DeliveryRatings
                .AnyAsync(
                    x =>
                        x.ShipmentId ==
                        shipment.Id
                );


        if (exists)
        {
            return Conflict(new
            {
                message =
                    "Đơn hàng này đã được đánh giá."
            });
        }


        var rating =
            new DeliveryRating
            {
                ShipmentId =
                    shipment.Id,

                CustomerId =
                    customerId.Value,

                Score =
                    request.Score,

                Comment =
                    request.Comment?
                        .Trim()
                    ?? string.Empty,

                CreatedAt =
                    DateTime.UtcNow
            };


        _db.DeliveryRatings.Add(
            rating
        );


        await _db.SaveChangesAsync();


        return StatusCode(
            StatusCodes.Status201Created,
            new
            {
                message =
                    "Đánh giá dịch vụ thành công.",

                rating = new
                {
                    id =
                        rating.Id,

                    shipmentId =
                        rating.ShipmentId,

                    score =
                        rating.Score,

                    comment =
                        rating.Comment,

                    createdAt =
                        rating.CreatedAt
                }
            }
        );
    }


    // =========================================================
    // CẬP NHẬT ĐÁNH GIÁ
    // PUT:
    // /api/v1/customer/shipments/{shipmentId}/rating
    // =========================================================
    [HttpPut]
    public async Task<IActionResult> UpdateRating(
        string shipmentId,
        [FromBody]
        UpdateDeliveryRatingRequest request)
    {
        var customerId =
            GetCurrentCustomerId();

        if (customerId == null)
        {
            return Unauthorized(new
            {
                message =
                    "Thông tin đăng nhập không hợp lệ."
            });
        }


        var shipment =
            await _db.Shipments
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.Id == shipmentId
                );


        if (shipment == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đơn hàng."
            });
        }


        if (shipment.CustomerId !=
            customerId.Value)
        {
            return Forbid();
        }


        var rating =
            await _db.DeliveryRatings
                .FirstOrDefaultAsync(
                    x =>
                        x.ShipmentId ==
                        shipment.Id &&
                        x.CustomerId ==
                        customerId.Value
                );


        if (rating == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy đánh giá của đơn hàng."
            });
        }


        rating.Score =
            request.Score;

        rating.Comment =
            request.Comment?
                .Trim()
            ?? string.Empty;

        rating.UpdatedAt =
            DateTime.UtcNow;


        await _db.SaveChangesAsync();


        return Ok(new
        {
            message =
                "Cập nhật đánh giá thành công.",

            rating = new
            {
                id =
                    rating.Id,

                shipmentId =
                    rating.ShipmentId,

                score =
                    rating.Score,

                comment =
                    rating.Comment,

                createdAt =
                    rating.CreatedAt,

                updatedAt =
                    rating.UpdatedAt
            }
        });
    }
}