using Microsoft.AspNetCore.Http;

namespace Back_DeliverySystem.Services
{
    public interface IVnPayService
    {
        string CreatePaymentUrl(
            long amount,
            string transactionReference,
            string orderInfo,
            string ipAddress
        );

        bool ValidateSignature(
            IQueryCollection query
        );
    }
}