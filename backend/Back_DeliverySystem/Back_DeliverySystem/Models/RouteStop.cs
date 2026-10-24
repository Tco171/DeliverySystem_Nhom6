namespace Back_DeliverySystem.Models
{
    public class RouteStop
    {
        public int Id { get; set; }

        public int RouteId { get; set; }

        public string ShipmentId { get; set; } =
            string.Empty;

        // thứ tự điểm dừng
        public int StopOrder { get; set; }

        // pickup / delivery
        public string StopType { get; set; } =
            "delivery";

        public string AddressSnapshot { get; set; } =
            string.Empty;

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        // pending / completed / skipped
        public string Status { get; set; } =
            "pending";

        public DateTime? CompletedAt { get; set; }

        public string? Notes { get; set; }

        public DeliveryRoute? Route { get; set; }
    }
}