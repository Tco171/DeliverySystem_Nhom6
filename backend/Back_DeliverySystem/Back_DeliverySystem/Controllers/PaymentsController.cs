using Back_DeliverySystem.Data;
using Back_DeliverySystem.DTOs.Customer;
using Back_DeliverySystem.Models;
using Back_DeliverySystem.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Back_DeliverySystem.Controllers
{
    [ApiController]
    [Route("api/v1/payments")]
    public class PaymentsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IVnPayService _vnPayService;

        public PaymentsController(
            AppDbContext context,
            IVnPayService vnPayService)
        {
            _context = context;
            _vnPayService = vnPayService;
        }


        // =========================================================
        // CUSTOMER - TẠO THANH TOÁN VNPAY
        // POST: /api/v1/payments/vnpay
        // =========================================================
        [Authorize(Roles = "customer")]
        [HttpPost("vnpay")]
        public async Task<IActionResult> CreateVnPayPayment(
            [FromBody] CreateVnPayPaymentRequest request)
        {
            var customerIdText =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier
                );

            if (!int.TryParse(
                    customerIdText,
                    out var customerId))
            {
                return Unauthorized(new
                {
                    message = "Token không hợp lệ."
                });
            }


            // Kiểm tra đơn hàng có thuộc customer này không
            var shipment =
                await _context.Shipments
                    .FirstOrDefaultAsync(x =>
                        x.Id == request.ShipmentId &&
                        x.CustomerId == customerId
                    );

            if (shipment == null)
            {
                return NotFound(new
                {
                    message =
                        "Không tìm thấy đơn hàng hoặc đơn hàng không thuộc tài khoản của bạn."
                });
            }


            // Chỉ shop_prepaid mới thanh toán phí vận chuyển online
            if (shipment.FeePayer != "shop_prepaid")
            {
                return BadRequest(new
                {
                    message =
                        "Đơn hàng này không sử dụng hình thức người gửi thanh toán phí trước."
                });
            }


            if (shipment.Fee <= 0)
            {
                return BadRequest(new
                {
                    message =
                        "Phí vận chuyển của đơn hàng không hợp lệ."
                });
            }


            // Nếu đã thanh toán thành công rồi thì không tạo lại
            var alreadyPaid =
                await _context.Payments
                    .AnyAsync(x =>
                        x.ShipmentId == shipment.Id &&
                        x.Status == "paid"
                    );

            if (alreadyPaid)
            {
                return Conflict(new
                {
                    message =
                        "Đơn hàng này đã được thanh toán."
                });
            }


            // Mã giao dịch gửi sang VNPay
            // vnp_TxnRef yêu cầu duy nhất
            var transactionReference =
                Guid.NewGuid()
                    .ToString("N")
                    .ToUpperInvariant();


            var payment =
                new Payment
                {
                    Id =
                        $"PAY-{Guid.NewGuid():N}"
                            .ToUpperInvariant(),

                    ShipmentId =
                        shipment.Id,

                    CustomerId =
                        customerId,

                    Amount =
                        shipment.Fee,

                    Method =
                        "vnpay",

                    Status =
                        "pending",

                    TransactionReference =
                        transactionReference,

                    CreatedAt =
                        DateTime.UtcNow
                };


            // Lấy IP client
            var forwardedIp =
                Request.Headers[
                    "X-Forwarded-For"
                ].FirstOrDefault();

            var ipAddress =
                !string.IsNullOrWhiteSpace(
                    forwardedIp)
                    ? forwardedIp
                        .Split(',')[0]
                        .Trim()
                    : HttpContext
                        .Connection
                        .RemoteIpAddress?
                        .ToString()
                        ?? "127.0.0.1";


            // Tạo URL thanh toán VNPay
            var paymentUrl =
                _vnPayService.CreatePaymentUrl(
                    payment.Amount,
                    payment.TransactionReference,
                    $"Thanh toan phi van chuyen don hang {shipment.Id}",
                    ipAddress
                );


            // Lưu Payment pending
            _context.Payments.Add(
                payment
            );

            await _context.SaveChangesAsync();


            return Ok(new
            {
                message =
                    "Tạo yêu cầu thanh toán VNPay thành công.",

                paymentId =
                    payment.Id,

                shipmentId =
                    shipment.Id,

                amount =
                    payment.Amount,

                status =
                    payment.Status,

                transactionReference =
                    payment.TransactionReference,

                paymentUrl
            });
        }


        // =========================================================
        // CUSTOMER - XEM TRẠNG THÁI PAYMENT
        // GET: /api/v1/payments/{paymentId}
        // =========================================================
        [Authorize(Roles = "customer")]
        [HttpGet("{paymentId}")]
        public async Task<IActionResult> GetPayment(
            string paymentId)
        {
            var customerIdText =
                User.FindFirstValue(
                    ClaimTypes.NameIdentifier
                );

            if (!int.TryParse(
                    customerIdText,
                    out var customerId))
            {
                return Unauthorized();
            }


            var payment =
                await _context.Payments
                    .AsNoTracking()
                    .FirstOrDefaultAsync(x =>
                        x.Id == paymentId &&
                        x.CustomerId == customerId
                    );

            if (payment == null)
            {
                return NotFound(new
                {
                    message =
                        "Không tìm thấy giao dịch."
                });
            }


            return Ok(new
            {
                payment.Id,
                payment.ShipmentId,
                payment.Amount,
                payment.Method,
                payment.Status,
                payment.TransactionReference,
                payment.GatewayTransactionNo,
                payment.BankCode,
                payment.ResponseCode,
                payment.TransactionStatus,
                payment.CreatedAt,
                payment.PaidAt
            });
        }


        // =========================================================
        // VNPAY RETURN URL
        // VNPay redirect trình duyệt khách hàng về đây
        //
        // GET:
        // /api/v1/payments/vnpay/return
        // =========================================================
        [AllowAnonymous]
        [HttpGet("vnpay/return")]
        public async Task<IActionResult> VnPayReturn()
        {
            var query = Request.Query;

            // 1. Kiểm tra chữ ký
            if (!_vnPayService.ValidateSignature(query))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Chữ ký VNPay không hợp lệ."
                });
            }

            var transactionReference =
                query["vnp_TxnRef"].ToString();

            // 2. Tìm payment
            var payment =
                await _context.Payments
                    .FirstOrDefaultAsync(x =>
                        x.TransactionReference ==
                        transactionReference
                    );

            if (payment == null)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy giao dịch."
                });
            }

            // 3. Kiểm tra số tiền
            if (!long.TryParse(
                    query["vnp_Amount"],
                    out var vnpAmount))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Số tiền VNPay trả về không hợp lệ."
                });
            }

            if (vnpAmount != payment.Amount * 100)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Số tiền giao dịch không khớp."
                });
            }

            var responseCode =
                query["vnp_ResponseCode"].ToString();

            var transactionStatus =
                query["vnp_TransactionStatus"].ToString();

            var success =
                responseCode == "00" &&
                transactionStatus == "00";

            // =====================================================
            // FALLBACK CHO SANDBOX
            // Nếu IPN chưa gọi về thì Return URL vẫn cập nhật DB.
            // Chỉ xử lý khi Payment còn pending để tránh update lặp.
            // =====================================================
            if (payment.Status == "pending")
            {
                payment.ResponseCode =
                    responseCode;

                payment.TransactionStatus =
                    transactionStatus;

                payment.GatewayTransactionNo =
                    query["vnp_TransactionNo"].ToString();

                payment.BankCode =
                    query["vnp_BankCode"].ToString();

                if (success)
                {
                    payment.Status = "paid";

                    payment.PaidAt =
                        DateTime.UtcNow;

                    payment.FailedAt = null;

                    payment.FailureReason = null;
                }
                else
                {
                    payment.Status = "failed";

                    payment.FailedAt =
                        DateTime.UtcNow;

                    payment.FailureReason =
                        $"VNPay ResponseCode: {responseCode}";
                }

                await _context.SaveChangesAsync();
            }

            return Ok(new
            {
                success,

                message =
                    success
                        ? "Thanh toán VNPay thành công."
                        : "Thanh toán VNPay không thành công.",

                paymentId =
                    payment.Id,

                shipmentId =
                    payment.ShipmentId,

                amount =
                    payment.Amount,

                responseCode,

                transactionStatus,

                databaseStatus =
                    payment.Status
            });
        }


        // =========================================================
        // VNPAY IPN
        //
        // Server VNPay gọi trực tiếp endpoint này.
        // Đây là nơi cập nhật database.
        //
        // GET:
        // /api/v1/payments/vnpay/ipn
        // =========================================================
        [AllowAnonymous]
        [HttpGet("vnpay/ipn")]
        public async Task<IActionResult> VnPayIpn()
        {
            try
            {
                var query =
                    Request.Query;


                // 1. Kiểm tra checksum
                if (!_vnPayService
                    .ValidateSignature(query))
                {
                    return Ok(new
                    {
                        RspCode = "97",
                        Message =
                            "Invalid Signature"
                    });
                }


                var transactionReference =
                    query["vnp_TxnRef"]
                        .ToString();


                // 2. Tìm payment
                var payment =
                    await _context.Payments
                        .FirstOrDefaultAsync(x =>
                            x.TransactionReference ==
                            transactionReference
                        );

                if (payment == null)
                {
                    return Ok(new
                    {
                        RspCode = "01",
                        Message =
                            "Order not found"
                    });
                }


                // 3. Kiểm tra amount
                if (!long.TryParse(
                        query["vnp_Amount"],
                        out var vnpAmount))
                {
                    return Ok(new
                    {
                        RspCode = "04",
                        Message =
                            "Invalid Amount"
                    });
                }


                if (vnpAmount !=
                    payment.Amount * 100)
                {
                    return Ok(new
                    {
                        RspCode = "04",
                        Message =
                            "Invalid Amount"
                    });
                }


                // 4. Tránh xử lý lại giao dịch
                if (payment.Status != "pending")
                {
                    return Ok(new
                    {
                        RspCode = "02",
                        Message =
                            "Order already confirmed"
                    });
                }


                var responseCode =
                    query["vnp_ResponseCode"]
                        .ToString();

                var transactionStatus =
                    query[
                        "vnp_TransactionStatus"
                    ].ToString();


                // Lưu dữ liệu VNPay trả về
                payment.ResponseCode =
                    responseCode;

                payment.TransactionStatus =
                    transactionStatus;

                payment.GatewayTransactionNo =
                    query["vnp_TransactionNo"]
                        .ToString();

                payment.BankCode =
                    query["vnp_BankCode"]
                        .ToString();


                // 5. Thành công
                if (responseCode == "00" &&
                    transactionStatus == "00")
                {
                    payment.Status =
                        "paid";

                    payment.PaidAt =
                        DateTime.UtcNow;
                }
                else
                {
                    payment.Status =
                        "failed";
                }


                await _context
                    .SaveChangesAsync();


                // VNPay yêu cầu JSON RspCode + Message
                return Ok(new
                {
                    RspCode = "00",
                    Message =
                        "Confirm Success"
                });
            }
            catch
            {
                return Ok(new
                {
                    RspCode = "99",
                    Message =
                        "Unknown error"
                });
            }
        }
    }
}