using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Back_DeliverySystem.Migrations
{
    /// <inheritdoc />
    public partial class AddShipmentMapCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "DeliveryLatitude",
                table: "ShippingQuotes",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryLongitude",
                table: "ShippingQuotes",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupLatitude",
                table: "ShippingQuotes",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupLongitude",
                table: "ShippingQuotes",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryLatitude",
                table: "Shipments",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryLongitude",
                table: "Shipments",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupLatitude",
                table: "Shipments",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "PickupLongitude",
                table: "Shipments",
                type: "float",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeliveryLatitude",
                table: "ShippingQuotes");

            migrationBuilder.DropColumn(
                name: "DeliveryLongitude",
                table: "ShippingQuotes");

            migrationBuilder.DropColumn(
                name: "PickupLatitude",
                table: "ShippingQuotes");

            migrationBuilder.DropColumn(
                name: "PickupLongitude",
                table: "ShippingQuotes");

            migrationBuilder.DropColumn(
                name: "DeliveryLatitude",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "DeliveryLongitude",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "PickupLatitude",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "PickupLongitude",
                table: "Shipments");
        }
    }
}
