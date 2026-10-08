using Back_DeliverySystem.Data;
using Microsoft.EntityFrameworkCore;
using Scalar.AspNetCore;


 
namespace Back_DeliverySystem
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers();

            builder.Services.AddOpenApi();

            builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseSqlServer(
                    builder.Configuration.GetConnectionString(
                        "DeliverySystemConnection"
                    )
                ));

            // Cho phép React Web + Flutter Web gọi Backend
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AlowFrontend", policy =>
                {
                    // Web gửi kèm credentials nên không được dùng AllowAnyOrigin (dấu *).
                    // Cho phép mọi cổng của localhost (web :5173, Flutter web :5000...).
                    policy
                        .SetIsOriginAllowed(origin =>
                            Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
                            uri.Host == "localhost")
                        .AllowCredentials()
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
            });

            var app = builder.Build();

            if (app.Environment.IsDevelopment())
            {
                app.MapOpenApi();

                // Trang giao diện xem và thử API: /scalar/v1
                app.MapScalarApiReference();
            }

            // Không bật HTTPS redirect khi đang test bằng HTTP
            // app.UseHttpsRedirection();

            app.UseCors("AlowFrontend");

            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
