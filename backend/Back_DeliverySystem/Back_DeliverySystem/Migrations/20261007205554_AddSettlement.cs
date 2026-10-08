using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Back_DeliverySystem.Migrations
{
    /// <inheritdoc />
    public partial class AddSettlement : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Settlements",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CustomerId = table.Column<int>(type: "int", nullable: false),
                    TotalCod = table.Column<long>(type: "bigint", nullable: false),
                    ShippingDeduction = table.Column<long>(type: "bigint", nullable: false),
                    Adjustment = table.Column<long>(type: "bigint", nullable: false),
                    AdjustmentReason = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NetAmount = table.Column<long>(type: "bigint", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    PaymentReference = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Settlements", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SettlementLines",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SettlementId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ShipmentId = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CodCollected = table.Column<long>(type: "bigint", nullable: false),
                    ShippingDeduction = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SettlementLines", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SettlementLines_Settlements_SettlementId",
                        column: x => x.SettlementId,
                        principalTable: "Settlements",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SettlementLines_SettlementId",
                table: "SettlementLines",
                column: "SettlementId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SettlementLines");

            migrationBuilder.DropTable(
                name: "Settlements");
        }
    }
}
