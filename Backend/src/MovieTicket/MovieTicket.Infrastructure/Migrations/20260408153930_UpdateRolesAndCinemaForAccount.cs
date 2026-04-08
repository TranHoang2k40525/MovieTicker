using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MovieTicket.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class UpdateRolesAndCinemaForAccount : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "role_type",
                table: "Roles",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "cinema_id",
                table: "Account",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Account_cinema_id",
                table: "Account",
                column: "cinema_id");

            migrationBuilder.AddForeignKey(
                name: "FK_Account_Cinema",
                table: "Account",
                column: "cinema_id",
                principalTable: "Cinema",
                principalColumn: "CinemaID");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Account_Cinema",
                table: "Account");

            migrationBuilder.DropIndex(
                name: "IX_Account_cinema_id",
                table: "Account");

            migrationBuilder.DropColumn(
                name: "role_type",
                table: "Roles");

            migrationBuilder.DropColumn(
                name: "cinema_id",
                table: "Account");
        }
    }
}
