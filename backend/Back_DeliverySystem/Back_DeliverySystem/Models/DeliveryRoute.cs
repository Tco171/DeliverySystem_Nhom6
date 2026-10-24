namespace Back_DeliverySystem.Models
{
    public class DeliveryRoute
    {
        public int Id { get; set; }

        public string RouteCode { get; set; } =
            string.Empty;

        public string Name { get; set; } =
            string.Empty;

        // Staff phụ trách tuyến
        public int StaffId { get; set; }

        public string Area { get; set; } =
            string.Empty;

        // draft / active / completed / cancelled
        public string Status { get; set; } =
            "draft";

        public DateTime PlannedDate { get; set; }

        public int CreatedByUserId { get; set; }

        public DateTime CreatedAt { get; set; } =
            DateTime.UtcNow;

        public DateTime? StartedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        public string? Notes { get; set; }

        public List<RouteStop> Stops { get; set; } =
            new();
    }
}