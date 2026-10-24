using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Back_DeliverySystem.Migrations
{
    /// <inheritdoc />
    public partial class UpdateDeliveryAssignmentResponse : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "AcceptedAt",
                table: "DeliveryAssignments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EndedAt",
                table: "DeliveryAssignments",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "DeliveryAssignments",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "RejectionReason",
                table: "DeliveryAssignments",
                type: "nvarchar(300)",
                maxLength: 300,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AcceptedAt",
                table: "DeliveryAssignments");

            migrationBuilder.DropColumn(
                name: "EndedAt",
                table: "DeliveryAssignments");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "DeliveryAssignments");

            migrationBuilder.DropColumn(
                name: "RejectionReason",
                table: "DeliveryAssignments");
        }
    }
}
