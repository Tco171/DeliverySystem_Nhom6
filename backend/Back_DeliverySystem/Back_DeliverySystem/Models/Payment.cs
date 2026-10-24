namespace Back_DeliverySystem.Models
{
    public class Payment
    {
        public string Id { get; set; } = string.Empty;

        public string ShipmentId { get; set; } = string.Empty;

        public int CustomerId { get; set; }

        public long Amount { get; set; }

        public string Method { get; set; } = "vnpay";

        // pending / paid / failed
        public string Status { get; set; } = "pending";

        // vnp_TxnRef
        public string TransactionReference { get; set; } =
            string.Empty;

        // vnp_TransactionNo
        public string? GatewayTransactionNo { get; set; }

        // vnp_BankCode
        public string? BankCode { get; set; }

        // vnp_ResponseCode
        public string? ResponseCode { get; set; }

        // vnp_TransactionStatus
        public string? TransactionStatus { get; set; }

        public DateTime CreatedAt { get; set; } =
            DateTime.UtcNow;

        public DateTime? PaidAt { get; set; }

        // Thời gian thanh toán thất bại
        public DateTime? FailedAt { get; set; }

        // Lý do thanh toán thất bại
        public string? FailureReason { get; set; }
    }
}