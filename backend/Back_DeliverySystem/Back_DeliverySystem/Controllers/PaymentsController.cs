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
        private readonly IConfiguration _configuration;

        public PaymentsController(
            AppDbContext context,
            IVnPayService vnPayService,
            IConfiguration configuration)
        {
            _context = context;
            _vnPayService = vnPayService;
            _configuration = configuration;
        }


        // =========================================================
        // CUSTOMER - Táº O THANH TOÃN VNPAY
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
                    message = "Token khÃ´ng há»£p lá»‡."
                });
            }


            // Kiá»ƒm tra Ä‘Æ¡n hÃ ng cÃ³ thuá»™c customer nÃ y khÃ´ng
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
                        "KhÃ´ng tÃ¬m tháº¥y Ä‘Æ¡n hÃ ng hoáº·c Ä‘Æ¡n hÃ ng khÃ´ng thuá»™c tÃ i khoáº£n cá»§a báº¡n."
                });
            }


            // Chá»‰ shop_prepaid má»›i thanh toÃ¡n phÃ­ váº­n chuyá»ƒn online
            if (shipment.FeePayer != "shop_prepaid")
            {
                return BadRequest(new
                {
                    message =
                        "ÄÆ¡n hÃ ng nÃ y khÃ´ng sá»­ dá»¥ng hÃ¬nh thá»©c ngÆ°á»i gá»­i thanh toÃ¡n phÃ­ trÆ°á»›c."
                });
            }


            if (shipment.Fee <= 0)
            {
                return BadRequest(new
                {
                    message =
                        "PhÃ­ váº­n chuyá»ƒn cá»§a Ä‘Æ¡n hÃ ng khÃ´ng há»£p lá»‡."
                });
            }


            // Náº¿u Ä‘Ã£ thanh toÃ¡n thÃ nh cÃ´ng rá»“i thÃ¬ khÃ´ng táº¡o láº¡i
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
                        "ÄÆ¡n hÃ ng nÃ y Ä‘Ã£ Ä‘Æ°á»£c thanh toÃ¡n."
                });
            }


            // MÃ£ giao dá»‹ch gá»­i sang VNPay
            // vnp_TxnRef yÃªu cáº§u duy nháº¥t
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


            // Láº¥y IP client
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


            // Táº¡o URL thanh toÃ¡n VNPay
            var paymentUrl =
                _vnPayService.CreatePaymentUrl(
                    payment.Amount,
                    payment.TransactionReference,
                    $"Thanh toan phi van chuyen don hang {shipment.Id}",
                    ipAddress
                );


            // LÆ°u Payment pending
            _context.Payments.Add(
                payment
            );

            await _context.SaveChangesAsync();


            return Ok(new
            {
                message =
                    "Táº¡o yÃªu cáº§u thanh toÃ¡n VNPay thÃ nh cÃ´ng.",

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
        [Authorize(Roles = "customer")]
        [HttpGet("statuses")]
        public async Task<IActionResult> GetPaymentStatuses()
        {
            var customerIdText =
                User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (!int.TryParse(customerIdText, out var customerId))
                return Unauthorized();

            var payments = await _context.Payments
                .AsNoTracking()
                .Where(p => p.CustomerId == customerId)
                .OrderByDescending(p => p.CreatedAt)
                .Select(p => new
                {
                    p.ShipmentId,
                    p.Status,
                    p.CreatedAt
                })
                .ToListAsync();

            var result = payments
     .GroupBy(p => p.ShipmentId)
     .Select(group => new
     {
         shipmentId = group.Key,
         status = group.Any(p => p.Status == "paid")
             ? "paid"
             : group.OrderByDescending(p => p.CreatedAt)
                    .First().Status
     })
     .ToList();

            return Ok(result);
        }

        // =========================================================
        // CUSTOMER - XEM TRáº NG THÃI PAYMENT
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
                        "KhÃ´ng tÃ¬m tháº¥y giao dá»‹ch."
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
        // VNPay redirect trÃ¬nh duyá»‡t khÃ¡ch hÃ ng vá» Ä‘Ã¢y
        //
        // GET:
        // /api/v1/payments/vnpay/return
        // =========================================================
        [AllowAnonymous]
        [HttpGet("vnpay/return")]
        public async Task<IActionResult> VnPayReturn()
        {
            var query = Request.Query;

            // 1. Kiá»ƒm tra chá»¯ kÃ½
            if (!_vnPayService.ValidateSignature(query))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Chá»¯ kÃ½ VNPay khÃ´ng há»£p lá»‡."
                });
            }

            var transactionReference =
                query["vnp_TxnRef"].ToString();

            // 2. TÃ¬m payment
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
                    message = "KhÃ´ng tÃ¬m tháº¥y giao dá»‹ch."
                });
            }

            // 3. Kiá»ƒm tra sá»‘ tiá»n
            if (!long.TryParse(
                    query["vnp_Amount"],
                    out var vnpAmount))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Sá»‘ tiá»n VNPay tráº£ vá» khÃ´ng há»£p lá»‡."
                });
            }

            if (vnpAmount != payment.Amount * 100)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Sá»‘ tiá»n giao dá»‹ch khÃ´ng khá»›p."
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
            // Náº¿u IPN chÆ°a gá»i vá» thÃ¬ Return URL váº«n cáº­p nháº­t DB.
            // Chá»‰ xá»­ lÃ½ khi Payment cÃ²n pending Ä‘á»ƒ trÃ¡nh update láº·p.
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

            // URL Ä‘Æ°á»£c cáº¥u hÃ¬nh cá»‘ Ä‘á»‹nh á»Ÿ server, khÃ´ng nháº­n URL redirect tá»« query.
            // Frontend sá»­ dá»¥ng JWT Ä‘á»ƒ táº£i tráº¡ng thÃ¡i payment tá»« API riÃªng.
            var webBaseUrl = _configuration["Frontend:BaseUrl"];
            if (string.IsNullOrWhiteSpace(webBaseUrl) ||
                !Uri.TryCreate(webBaseUrl, UriKind.Absolute, out var webUri) ||
                (webUri.Scheme != Uri.UriSchemeHttp && webUri.Scheme != Uri.UriSchemeHttps))
            {
                return StatusCode(500, new { message = "ChÆ°a cáº¥u hÃ¬nh Frontend:BaseUrl há»£p lá»‡." });
            }

            var resultUrl = webBaseUrl.TrimEnd('/') +
                "/payment/result?paymentId=" + Uri.EscapeDataString(payment.Id);
            return Redirect(resultUrl);
        }


        // =========================================================
        // VNPAY IPN
        //
        // Server VNPay gá»i trá»±c tiáº¿p endpoint nÃ y.
        // ÄÃ¢y lÃ  nÆ¡i cáº­p nháº­t database.
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


                // 1. Kiá»ƒm tra checksum
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


                // 2. TÃ¬m payment
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


                // 3. Kiá»ƒm tra amount
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


                // 4. TrÃ¡nh xá»­ lÃ½ láº¡i giao dá»‹ch
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


                // LÆ°u dá»¯ liá»‡u VNPay tráº£ vá»
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


                // 5. ThÃ nh cÃ´ng
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


                // VNPay yÃªu cáº§u JSON RspCode + Message
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
