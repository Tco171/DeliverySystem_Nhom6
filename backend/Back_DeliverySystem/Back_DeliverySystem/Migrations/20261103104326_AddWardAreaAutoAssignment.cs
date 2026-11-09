using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Back_DeliverySystem.Migrations
{
    /// <inheritdoc />
    public partial class AddWardAreaAutoAssignment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DeliveryAreaId",
                table: "Shipments",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PickupAreaId",
                table: "Shipments",
                type: "int",
                nullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "AssignedByUserId",
                table: "DeliveryAssignments",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<string>(
                name: "AssignmentSource",
                table: "DeliveryAssignments",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "Areas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Areas", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "StaffAreas",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    StaffId = table.Column<int>(type: "int", nullable: false),
                    AreaId = table.Column<int>(type: "int", nullable: false),
                    MaxActiveOrders = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StaffAreas", x => x.Id);
                    table.ForeignKey(
                        name: "FK_StaffAreas_Areas_AreaId",
                        column: x => x.AreaId,
                        principalTable: "Areas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_StaffAreas_Staffs_StaffId",
                        column: x => x.StaffId,
                        principalTable: "Staffs",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Shipments_DeliveryAreaId",
                table: "Shipments",
                column: "DeliveryAreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Shipments_PickupAreaId",
                table: "Shipments",
                column: "PickupAreaId");

            migrationBuilder.CreateIndex(
                name: "IX_Areas_Code",
                table: "Areas",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Areas_Name",
                table: "Areas",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_StaffAreas_AreaId",
                table: "StaffAreas",
                column: "AreaId");

            migrationBuilder.CreateIndex(
                name: "IX_StaffAreas_StaffId_AreaId",
                table: "StaffAreas",
                columns: new[] { "StaffId", "AreaId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Shipments_Areas_DeliveryAreaId",
                table: "Shipments",
                column: "DeliveryAreaId",
                principalTable: "Areas",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Shipments_Areas_PickupAreaId",
                table: "Shipments",
                column: "PickupAreaId",
                principalTable: "Areas",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Shipments_Areas_DeliveryAreaId",
                table: "Shipments");

            migrationBuilder.DropForeignKey(
                name: "FK_Shipments_Areas_PickupAreaId",
                table: "Shipments");

            migrationBuilder.DropTable(
                name: "StaffAreas");

            migrationBuilder.DropTable(
                name: "Areas");

            migrationBuilder.DropIndex(
                name: "IX_Shipments_DeliveryAreaId",
                table: "Shipments");

            migrationBuilder.DropIndex(
                name: "IX_Shipments_PickupAreaId",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "DeliveryAreaId",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "PickupAreaId",
                table: "Shipments");

            migrationBuilder.DropColumn(
                name: "AssignmentSource",
                table: "DeliveryAssignments");

            migrationBuilder.AlterColumn<int>(
                name: "AssignedByUserId",
                table: "DeliveryAssignments",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);
        }
    }
}
