using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MovieTicket.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateRoomLayoutAndSeats : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_CinemaHallSeat_HallID",
                table: "CinemaHallSeat");

            migrationBuilder.AddColumn<int>(
                name: "col_seat",
                table: "CinemaHallSeat",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "row_seat",
                table: "CinemaHallSeat",
                type: "nvarchar(5)",
                maxLength: 5,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RoomLayout",
                columns: table => new
                {
                    layout_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    HallID = table.Column<int>(type: "int", nullable: false),
                    row_seat = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: false),
                    col_seat = table.Column<int>(type: "int", nullable: false),
                    cell_type = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoomLayout", x => x.layout_id);
                    table.ForeignKey(
                        name: "FK_RoomLayout_Hall",
                        column: x => x.HallID,
                        principalTable: "CinemaHall",
                        principalColumn: "HallID",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "UQ_Hall_Row_Col",
                table: "CinemaHallSeat",
                columns: new[] { "HallID", "row_seat", "col_seat" },
                unique: true,
                filter: "[HallID] IS NOT NULL AND [row_seat] IS NOT NULL AND [col_seat] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UQ_RoomLayout_Position",
                table: "RoomLayout",
                columns: new[] { "HallID", "row_seat", "col_seat" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RoomLayout");

            migrationBuilder.DropIndex(
                name: "UQ_Hall_Row_Col",
                table: "CinemaHallSeat");

            migrationBuilder.DropColumn(
                name: "col_seat",
                table: "CinemaHallSeat");

            migrationBuilder.DropColumn(
                name: "row_seat",
                table: "CinemaHallSeat");

            migrationBuilder.CreateIndex(
                name: "IX_CinemaHallSeat_HallID",
                table: "CinemaHallSeat",
                column: "HallID");
        }
    }
}
