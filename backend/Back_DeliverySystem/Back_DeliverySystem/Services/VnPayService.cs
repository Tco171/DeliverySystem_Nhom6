using Back_DeliverySystem.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;
using System.Net;
using System.Security.Cryptography;
using System.Text;

namespace Back_DeliverySystem.Services
{
    public class VnPayService : IVnPayService
    {
        private readonly VnPayOptions _options;

        public VnPayService(
            IOptions<VnPayOptions> options
        )
        {
            _options = options.Value;
        }

        public string CreatePaymentUrl(
            long amount,
            string transactionReference,
            string orderInfo,
            string ipAddress
        )
        {
            if (string.IsNullOrWhiteSpace(
                _options.TmnCode))
            {
                throw new InvalidOperationException(
                    "Chưa cấu hình VnPay:TmnCode."
                );
            }

            if (string.IsNullOrWhiteSpace(
                _options.HashSecret))
            {
                throw new InvalidOperationException(
                    "Chưa cấu hình VnPay:HashSecret."
                );
            }

            // VNPay sử dụng GMT+7
            var vietnamTime =
                DateTime.UtcNow.AddHours(7);

            var expireTime =
                vietnamTime.AddMinutes(15);

            // Tránh trường hợp localhost trả IPv6 ::1
            if (string.IsNullOrWhiteSpace(ipAddress)
                || ipAddress == "::1")
            {
                ipAddress = "127.0.0.1";
            }

            var requestData =
                new SortedDictionary<string, string>(
                    StringComparer.Ordinal
                )
                {
                    ["vnp_Version"] = "2.1.0",

                    ["vnp_Command"] = "pay",

                    ["vnp_TmnCode"] =
                        _options.TmnCode,

                    ["vnp_Amount"] =
                        (amount * 100).ToString(),

                    ["vnp_CreateDate"] =
                        vietnamTime.ToString(
                            "yyyyMMddHHmmss"
                        ),

                    ["vnp_CurrCode"] = "VND",

                    ["vnp_IpAddr"] =
                        ipAddress,

                    ["vnp_Locale"] = "vn",

                    ["vnp_OrderInfo"] =
                        orderInfo,

                    ["vnp_OrderType"] =
                        "other",

                    ["vnp_ReturnUrl"] =
                        _options.ReturnUrl,

                    ["vnp_TxnRef"] =
                        transactionReference,

                    ["vnp_ExpireDate"] =
                        expireTime.ToString(
                            "yyyyMMddHHmmss"
                        )
                };

            var signData =
                BuildQueryString(
                    requestData
                );

            var secureHash =
                HmacSha512(
                    _options.HashSecret,
                    signData
                );

            return
                $"{_options.PaymentUrl}" +
                $"?{signData}" +
                $"&vnp_SecureHash={secureHash}";
        }


        public bool ValidateSignature(
            IQueryCollection query
        )
        {
            if (!query.TryGetValue(
                    "vnp_SecureHash",
                    out var receivedHash))
            {
                return false;
            }

            var responseData =
                new SortedDictionary<string, string>(
                    StringComparer.Ordinal
                );

            foreach (var item in query)
            {
                if (!item.Key.StartsWith(
                        "vnp_",
                        StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (item.Key.Equals(
                        "vnp_SecureHash",
                        StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (item.Key.Equals(
                        "vnp_SecureHashType",
                        StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                responseData[item.Key] =
                    item.Value.ToString();
            }

            var signData =
                BuildQueryString(
                    responseData
                );

            var expectedHash =
                HmacSha512(
                    _options.HashSecret,
                    signData
                );

            return string.Equals(
                expectedHash,
                receivedHash.ToString(),
                StringComparison.OrdinalIgnoreCase
            );
        }


        private static string BuildQueryString(
            SortedDictionary<string, string> data
        )
        {
            return string.Join(
                "&",
                data
                    .Where(x =>
                        !string.IsNullOrEmpty(
                            x.Value
                        ))
                    .Select(x =>
                        $"{WebUtility.UrlEncode(x.Key)}=" +
                        $"{WebUtility.UrlEncode(x.Value)}"
                    )
            );
        }


        private static string HmacSha512(
            string key,
            string inputData
        )
        {
            var keyBytes =
                Encoding.UTF8.GetBytes(
                    key
                );

            var inputBytes =
                Encoding.UTF8.GetBytes(
                    inputData
                );

            using var hmac =
                new HMACSHA512(
                    keyBytes
                );

            var hashBytes =
                hmac.ComputeHash(
                    inputBytes
                );

            return Convert
                .ToHexString(hashBytes)
                .ToLowerInvariant();
        }
    }
}