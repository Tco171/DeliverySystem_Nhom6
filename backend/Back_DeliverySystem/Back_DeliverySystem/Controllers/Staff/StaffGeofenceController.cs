using System.Data;
using System.Security.Claims;
using Back_DeliverySystem.Data;
using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Back_DeliverySystem.Controllers;

/// <summary>
/// Ghi nhận sự kiện Staff đi vào bán kính điểm lấy/giao. Đây chỉ là lịch sử;
/// trạng thái Shipment vẫn phải được Staff xác nhận qua các thao tác hiện có.
/// </summary>
[ApiController]
[Route("api/v1/staff/assignments/{assignmentId:int}/geofence-arrivals")]
[Authorize(Roles = "staff")]
public sealed class StaffGeofenceController : ControllerBase
{
    private const double RadiusMeters = 150;
    private const double MaxAccuracyMeters = 100;
    private readonly AppDbContext _db;

    public StaffGeofenceController(AppDbContext db) => _db = db;

    [HttpPost]
    public async Task<IActionResult> RecordArrival(
        int assignmentId,
        [FromBody] GeofenceArrivalRequest request,
        CancellationToken cancellationToken)
    {
        if (assignmentId <= 0 || !IsCoordinate(request.Latitude, request.Longitude) ||
            !double.IsFinite(request.Accuracy) || request.Accuracy is <= 0 or > MaxAccuracyMeters)
            return BadRequest(new { message = "Tọa độ hoặc độ chính xác GPS không hợp lệ." });

        var stage = request.Stage?.Trim().ToLowerInvariant();
        if (stage is not ("pickup" or "delivery"))
            return BadRequest(new { message = "Giai đoạn Geofence không hợp lệ." });

        if (!int.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return Unauthorized(new { message = "Không xác định được tài khoản Staff." });

        var staff = await _db.Staffs.FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);
        if (staff is null)
            return Unauthorized(new { message = "Không tìm thấy hồ sơ nhân viên." });

        // Giao dịch tuần tự hóa + kiểm tra trùng giúp nhiều GPS callback không tạo nhiều event.
        await using var transaction = await _db.Database.BeginTransactionAsync(IsolationLevel.Serializable, cancellationToken);
        var assignment = await _db.DeliveryAssignments.FirstOrDefaultAsync(
            x => x.Id == assignmentId && x.StaffId == staff.Id && x.IsActive && x.Status == "in_progress",
            cancellationToken);
        if (assignment is null)
            return Conflict(new { message = "Không tìm thấy phân công đang thực hiện của Staff." });

        var shipment = await _db.Shipments.FirstOrDefaultAsync(x => x.Id == assignment.ShipmentId, cancellationToken);
        if (shipment is null)
            return NotFound(new { message = "Không tìm thấy Shipment." });

        var isPickup = stage == "pickup";
        var expectedStatus = isPickup ? "picking_up" : "delivering";
        var eventStatus = isPickup ? "arrived_at_pickup" : "arrived_at_delivery";
        var placeLabel = isPickup ? "điểm lấy hàng" : "điểm giao hàng";
        var targetLatitude = isPickup ? shipment.PickupLatitude : shipment.DeliveryLatitude;
        var targetLongitude = isPickup ? shipment.PickupLongitude : shipment.DeliveryLongitude;

        if (!targetLatitude.HasValue || !targetLongitude.HasValue ||
            !IsCoordinate(targetLatitude.Value, targetLongitude.Value) ||
            (targetLatitude.Value == 0 && targetLongitude.Value == 0))
            return BadRequest(new { message = $"Shipment chưa có tọa độ hợp lệ cho {placeLabel}." });

        if (!string.Equals(shipment.Status, expectedStatus, StringComparison.OrdinalIgnoreCase))
            return Conflict(new { message = $"Staff chưa ở đúng giai đoạn công việc để ghi nhận đến {placeLabel}." });

        var distanceMeters = DistanceMeters(request.Latitude, request.Longitude, targetLatitude.Value, targetLongitude.Value);
        if (distanceMeters > RadiusMeters)
            return BadRequest(new { message = "Staff vẫn ở ngoài vùng Geofence.", distanceMeters = Math.Round(distanceMeters, 1), radiusMeters = RadiusMeters });

        var alreadyRecorded = await _db.ShipmentEvents.AnyAsync(
            x => x.ShipmentId == shipment.Id && x.Status == eventStatus, cancellationToken);
        if (alreadyRecorded)
        {
            await transaction.CommitAsync(cancellationToken);
            return Ok(new { message = "Sự kiện Staff đến điểm đã được ghi nhận trước đó.", alreadyRecorded = true, eventStatus });
        }

        var recordedAt = DateTime.UtcNow;
        _db.ShipmentEvents.Add(new ShipmentEvent
        {
            ShipmentId = shipment.Id,
            Status = eventStatus,
            At = recordedAt,
            Note = $"Staff {staff.EmployeeCode} đã đến {placeLabel}. Khoảng cách GPS: {Math.Round(distanceMeters, 1)} m; độ chính xác: {Math.Round(request.Accuracy, 1)} m."
        });
        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return Ok(new { message = $"Đã ghi nhận Staff đến {placeLabel}.", alreadyRecorded = false, eventStatus, recordedAt, distanceMeters = Math.Round(distanceMeters, 1), radiusMeters = RadiusMeters });
    }

    private static bool IsCoordinate(double latitude, double longitude) =>
        double.IsFinite(latitude) && double.IsFinite(longitude) &&
        latitude is >= -90 and <= 90 && longitude is >= -180 and <= 180;

    private static double DistanceMeters(double latitude1, double longitude1, double latitude2, double longitude2)
    {
        const double earthRadiusMeters = 6_371_000;
        static double ToRadians(double degrees) => degrees * Math.PI / 180;
        var latitudeDelta = ToRadians(latitude2 - latitude1);
        var longitudeDelta = ToRadians(longitude2 - longitude1);
        var a = Math.Pow(Math.Sin(latitudeDelta / 2), 2) +
                Math.Cos(ToRadians(latitude1)) * Math.Cos(ToRadians(latitude2)) *
                Math.Pow(Math.Sin(longitudeDelta / 2), 2);
        return earthRadiusMeters * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }
}

public sealed class GeofenceArrivalRequest
{
    public string Stage { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double Accuracy { get; set; }
}
