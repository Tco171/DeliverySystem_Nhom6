using System.ComponentModel.DataAnnotations;

namespace Back_DeliverySystem.DTOs.Operations
{
    // =========================================================
    // TẠO TUYẾN GIAO HÀNG
    // =========================================================
    public class CreateDeliveryRouteRequest
    {
        [Required(ErrorMessage = "Tên tuyến không được để trống.")]
        [StringLength(200)]
        public string Name { get; set; } = string.Empty;


        [Required(ErrorMessage = "StaffId không được để trống.")]
        public int StaffId { get; set; }


        [StringLength(200)]
        public string Area { get; set; } = string.Empty;


        [Required(ErrorMessage = "Ngày dự kiến không được để trống.")]
        public DateTime PlannedDate { get; set; }


        [StringLength(1000)]
        public string? Notes { get; set; }
    }


    // =========================================================
    // THÊM ĐIỂM DỪNG VÀO TUYẾN
    // =========================================================
    public class AddRouteStopRequest
    {
        [Required(ErrorMessage = "ShipmentId không được để trống.")]
        public string ShipmentId { get; set; } = string.Empty;


        [Range(1, int.MaxValue,
            ErrorMessage = "StopOrder phải lớn hơn 0.")]
        public int StopOrder { get; set; }


        [Required(ErrorMessage = "StopType không được để trống.")]
        public string StopType { get; set; } = "delivery";


        [StringLength(1000)]
        public string? Notes { get; set; }
    }


    // =========================================================
    // ĐỔI THỨ TỰ ĐIỂM DỪNG
    // =========================================================
    public class ReorderRouteStopItem
    {
        [Required]
        public int StopId { get; set; }


        [Range(1, int.MaxValue,
            ErrorMessage = "StopOrder phải lớn hơn 0.")]
        public int StopOrder { get; set; }
    }


    public class ReorderRouteStopsRequest
    {
        [Required]
        [MinLength(1,
            ErrorMessage = "Danh sách điểm dừng không được rỗng.")]
        public List<ReorderRouteStopItem> Stops { get; set; } =
            new();
    }


    // =========================================================
    // CẬP NHẬT THÔNG TIN TUYẾN
    // =========================================================
    public class UpdateDeliveryRouteRequest
    {
        [StringLength(200)]
        public string? Name { get; set; }


        public int? StaffId { get; set; }


        [StringLength(200)]
        public string? Area { get; set; }


        public DateTime? PlannedDate { get; set; }


        [StringLength(1000)]
        public string? Notes { get; set; }
    }
}