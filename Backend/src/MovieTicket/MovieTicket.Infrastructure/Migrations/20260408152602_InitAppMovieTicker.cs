using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MovieTicket.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitAppMovieTicker : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Account",
                columns: table => new
                {
                    account_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    email = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    password_hash = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true, defaultValue: "active"),
                    created_at = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Accounts__46A222CD72F2C3F9", x => x.account_id);
                });

            migrationBuilder.CreateTable(
                name: "City",
                columns: table => new
                {
                    CityID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CityName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__City__F2D21A964D499A0D", x => x.CityID);
                });

            migrationBuilder.CreateTable(
                name: "Movie",
                columns: table => new
                {
                    MovieID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MovieTitle = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    MovieDescription = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MovieLanguage = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    MovieGenre = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    MovieReleaseDate = table.Column<DateOnly>(type: "date", nullable: true),
                    MovieRuntime = table.Column<int>(type: "int", nullable: true),
                    MovieAge = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MovieActor = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    MovieTrailler = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Movie__4BD2943A61565677", x => x.MovieID);
                });

            migrationBuilder.CreateTable(
                name: "Permissions",
                columns: table => new
                {
                    permission_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    permission_name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Permissi__E5331AFA7EADD613", x => x.permission_id);
                });

            migrationBuilder.CreateTable(
                name: "Product",
                columns: table => new
                {
                    ProductID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ProductName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    ProductPrice = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    ImageProduct = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ProductDescription = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Product__B40CC6ED714480AB", x => x.ProductID);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    role_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    role_name = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Roles__760965CC90713F13", x => x.role_id);
                });

            migrationBuilder.CreateTable(
                name: "Voucher",
                columns: table => new
                {
                    VoucherID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    DiscountValue = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: true),
                    EndDate = table.Column<DateOnly>(type: "date", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    PaymentID = table.Column<int>(type: "int", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: true),
                    Title = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    ImageVoucher = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UsageLimit = table.Column<int>(type: "int", nullable: true),
                    UsageCount = table.Column<int>(type: "int", nullable: true),
                    IsRestricted = table.Column<bool>(type: "bit", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Voucher__3AEE79C1C5C1E2B9", x => x.VoucherID);
                });

            migrationBuilder.CreateTable(
                name: "LoginHistory",
                columns: table => new
                {
                    history_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_id = table.Column<int>(type: "int", nullable: true),
                    ip_address = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    device_info = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    login_time = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__LoginHis__096AA2E9C6FFBA14", x => x.history_id);
                    table.ForeignKey(
                        name: "FK__LoginHist__accou__2180FB33",
                        column: x => x.account_id,
                        principalTable: "Account",
                        principalColumn: "account_id");
                });

            migrationBuilder.CreateTable(
                name: "OTPs",
                columns: table => new
                {
                    otp_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_id = table.Column<int>(type: "int", nullable: false),
                    otp_hash = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: false),
                    purpose = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    expires_at = table.Column<DateTime>(type: "datetime", nullable: false),
                    used = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__OTPs__AEE35435EEDB761D", x => x.otp_id);
                    table.ForeignKey(
                        name: "FK__OTPs__account_id__236943A5",
                        column: x => x.account_id,
                        principalTable: "Account",
                        principalColumn: "account_id");
                });

            migrationBuilder.CreateTable(
                name: "RefreshTokens",
                columns: table => new
                {
                    token_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_id = table.Column<int>(type: "int", nullable: true),
                    refresh_token = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    expires_at = table.Column<DateTime>(type: "datetime", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__RefreshT__CB3C9E17FDA18B1A", x => x.token_id);
                    table.ForeignKey(
                        name: "FK__RefreshTo__accou__25518C17",
                        column: x => x.account_id,
                        principalTable: "Account",
                        principalColumn: "account_id");
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_id = table.Column<int>(type: "int", nullable: false),
                    full_name = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    email = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    gender = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: true),
                    date_of_birth = table.Column<DateOnly>(type: "date", nullable: true),
                    address = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    avatar_url = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Users__B9BE370FF8267C82", x => x.user_id);
                    table.ForeignKey(
                        name: "FK__Users__account_i__2A164134",
                        column: x => x.account_id,
                        principalTable: "Account",
                        principalColumn: "account_id");
                });

            migrationBuilder.CreateTable(
                name: "Cinema",
                columns: table => new
                {
                    CinemaID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CinemaName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    CityID = table.Column<int>(type: "int", nullable: true),
                    CityAddress = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    Latitude = table.Column<double>(type: "float", nullable: true),
                    Longitude = table.Column<double>(type: "float", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Cinema__59C9262697EE2F56", x => x.CinemaID);
                    table.ForeignKey(
                        name: "FK__Cinema__CityID__1CBC4616",
                        column: x => x.CityID,
                        principalTable: "City",
                        principalColumn: "CityID");
                });

            migrationBuilder.CreateTable(
                name: "AccountRole",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    account_id = table.Column<int>(type: "int", nullable: true),
                    role_id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__AccountR__3213E83F3BE93F40", x => x.id);
                    table.ForeignKey(
                        name: "FK__AccountRo__accou__151B244E",
                        column: x => x.account_id,
                        principalTable: "Account",
                        principalColumn: "account_id");
                    table.ForeignKey(
                        name: "FK__AccountRo__role___160F4887",
                        column: x => x.role_id,
                        principalTable: "Roles",
                        principalColumn: "role_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "RolePermissions",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    role_id = table.Column<int>(type: "int", nullable: true),
                    permission_id = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__RolePerm__3213E83FD957185C", x => x.id);
                    table.ForeignKey(
                        name: "FK__RolePermi__permi__2645B050",
                        column: x => x.permission_id,
                        principalTable: "Permissions",
                        principalColumn: "permission_id");
                    table.ForeignKey(
                        name: "FK__RolePermi__role___2739D489",
                        column: x => x.role_id,
                        principalTable: "Roles",
                        principalColumn: "role_id");
                });

            migrationBuilder.CreateTable(
                name: "LikeMovie",
                columns: table => new
                {
                    UserID = table.Column<int>(type: "int", nullable: false),
                    MovieID = table.Column<int>(type: "int", nullable: false),
                    IsLiked = table.Column<bool>(type: "bit", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__LikeMovi__A335E5EF7319EB51", x => new { x.UserID, x.MovieID });
                    table.ForeignKey(
                        name: "FK__LikeMovie__Movie__1F98B2C1",
                        column: x => x.MovieID,
                        principalTable: "Movie",
                        principalColumn: "MovieID");
                    table.ForeignKey(
                        name: "FK__LikeMovie__UserI__208CD6FA",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "Notification",
                columns: table => new
                {
                    NotificationID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: true),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DateSent = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    IsRead = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    DeviceInfo = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    IPAddress = table.Column<string>(type: "varchar(45)", unicode: false, maxLength: 45, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Notifica__20CF2E329C748D74", x => x.NotificationID);
                    table.ForeignKey(
                        name: "FK__Notificat__UserI__22751F6C",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "VoucherUsage",
                columns: table => new
                {
                    VoucherUsageID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    VoucherID = table.Column<int>(type: "int", nullable: true),
                    UserID = table.Column<int>(type: "int", nullable: true),
                    UsedAt = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    BookingID = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__VoucherU__4264F82BCCE06F4C", x => x.VoucherUsageID);
                    table.ForeignKey(
                        name: "FK__VoucherUs__UserI__2B0A656D",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "user_id");
                    table.ForeignKey(
                        name: "FK__VoucherUs__Vouch__2BFE89A6",
                        column: x => x.VoucherID,
                        principalTable: "Voucher",
                        principalColumn: "VoucherID");
                });

            migrationBuilder.CreateTable(
                name: "CinemaHall",
                columns: table => new
                {
                    HallID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CinemaID = table.Column<int>(type: "int", nullable: true),
                    HallName = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    TotalSeats = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__CinemaHa__7E60E2748CC49DFC", x => x.HallID);
                    table.ForeignKey(
                        name: "FK__CinemaHal__Cinem__1DB06A4F",
                        column: x => x.CinemaID,
                        principalTable: "Cinema",
                        principalColumn: "CinemaID");
                });

            migrationBuilder.CreateTable(
                name: "CinemaHallSeat",
                columns: table => new
                {
                    SeatID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    HallID = table.Column<int>(type: "int", nullable: true),
                    SeatNumber = table.Column<string>(type: "varchar(10)", unicode: false, maxLength: 10, nullable: true),
                    SeatType = table.Column<int>(type: "int", maxLength: 20, nullable: true),
                    SeatPrice = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    PairID = table.Column<int>(type: "int", nullable: true),
                    Status = table.Column<int>(type: "int", maxLength: 20, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__CinemaHa__311713D347655F51", x => x.SeatID);
                    table.ForeignKey(
                        name: "FK__CinemaHal__HallI__1EA48E88",
                        column: x => x.HallID,
                        principalTable: "CinemaHall",
                        principalColumn: "HallID");
                });

            migrationBuilder.CreateTable(
                name: "Show",
                columns: table => new
                {
                    ShowID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MovieID = table.Column<int>(type: "int", nullable: true),
                    HallID = table.Column<int>(type: "int", nullable: true),
                    ShowTime = table.Column<TimeOnly>(type: "time", nullable: true),
                    ShowDate = table.Column<DateOnly>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Show__6DE3E0D22611764A", x => x.ShowID);
                    table.ForeignKey(
                        name: "FK__Show__HallID__282DF8C2",
                        column: x => x.HallID,
                        principalTable: "CinemaHall",
                        principalColumn: "HallID");
                    table.ForeignKey(
                        name: "FK__Show__MovieID__29221CFB",
                        column: x => x.MovieID,
                        principalTable: "Movie",
                        principalColumn: "MovieID");
                });

            migrationBuilder.CreateTable(
                name: "Booking",
                columns: table => new
                {
                    BookingID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserID = table.Column<int>(type: "int", nullable: true),
                    ShowID = table.Column<int>(type: "int", nullable: true),
                    TotalSeats = table.Column<int>(type: "int", nullable: true),
                    Status = table.Column<int>(type: "int", unicode: false, maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Booking__73951ACDEE353034", x => x.BookingID);
                    table.ForeignKey(
                        name: "FK__Booking__ShowID__17036CC0",
                        column: x => x.ShowID,
                        principalTable: "Show",
                        principalColumn: "ShowID");
                    table.ForeignKey(
                        name: "FK__Booking__UserID__17F790F9",
                        column: x => x.UserID,
                        principalTable: "Users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "BookingProduct",
                columns: table => new
                {
                    BookingProductID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BookingID = table.Column<int>(type: "int", nullable: true),
                    ProductID = table.Column<int>(type: "int", nullable: true),
                    Quantity = table.Column<int>(type: "int", nullable: true),
                    TotalPriceBookingProduct = table.Column<decimal>(type: "decimal(10,2)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__BookingP__8AFEF455DB05F0CA", x => x.BookingProductID);
                    table.ForeignKey(
                        name: "FK__BookingPr__Booki__18EBB532",
                        column: x => x.BookingID,
                        principalTable: "Booking",
                        principalColumn: "BookingID");
                    table.ForeignKey(
                        name: "FK__BookingPr__Produ__19DFD96B",
                        column: x => x.ProductID,
                        principalTable: "Product",
                        principalColumn: "ProductID");
                });

            migrationBuilder.CreateTable(
                name: "BookingSeat",
                columns: table => new
                {
                    BookingSeatID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BookingID = table.Column<int>(type: "int", nullable: true),
                    SeatID = table.Column<int>(type: "int", nullable: true),
                    Status = table.Column<int>(type: "int", unicode: false, maxLength: 20, nullable: false),
                    TicketPrice = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    HoldUntil = table.Column<DateTime>(type: "datetime", nullable: true),
                    ShowID = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__BookingS__FA4B942630564FAF", x => x.BookingSeatID);
                    table.ForeignKey(
                        name: "FK__BookingSe__Booki__1AD3FDA4",
                        column: x => x.BookingID,
                        principalTable: "Booking",
                        principalColumn: "BookingID");
                    table.ForeignKey(
                        name: "FK__BookingSe__SeatI__1BC821DD",
                        column: x => x.SeatID,
                        principalTable: "CinemaHallSeat",
                        principalColumn: "SeatID");
                });

            migrationBuilder.CreateTable(
                name: "Payment",
                columns: table => new
                {
                    PaymentID = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BookingID = table.Column<int>(type: "int", nullable: true),
                    Amount = table.Column<decimal>(type: "decimal(10,2)", nullable: true),
                    PaymentDate = table.Column<DateTime>(type: "datetime", nullable: true, defaultValueSql: "(getdate())"),
                    PaymentMethod = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__Payment__9B556A587FAC96A3", x => x.PaymentID);
                    table.ForeignKey(
                        name: "FK__Payment__Booking__245D67DE",
                        column: x => x.BookingID,
                        principalTable: "Booking",
                        principalColumn: "BookingID");
                });

            migrationBuilder.CreateIndex(
                name: "UQ__Accounts__AB6E6164EE02E64B",
                table: "Account",
                column: "email",
                unique: true,
                filter: "[email] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UQ__Accounts__B43B145F1057CB3A",
                table: "Account",
                column: "phone",
                unique: true,
                filter: "[phone] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_AccountRole_account_id",
                table: "AccountRole",
                column: "account_id");

            migrationBuilder.CreateIndex(
                name: "IX_AccountRole_role_id",
                table: "AccountRole",
                column: "role_id");

            migrationBuilder.CreateIndex(
                name: "IX_Booking_ShowID",
                table: "Booking",
                column: "ShowID");

            migrationBuilder.CreateIndex(
                name: "IX_Booking_UserID",
                table: "Booking",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_BookingProduct_BookingID",
                table: "BookingProduct",
                column: "BookingID");

            migrationBuilder.CreateIndex(
                name: "IX_BookingProduct_ProductID",
                table: "BookingProduct",
                column: "ProductID");

            migrationBuilder.CreateIndex(
                name: "IX_BookingSeat_BookingID",
                table: "BookingSeat",
                column: "BookingID");

            migrationBuilder.CreateIndex(
                name: "IX_BookingSeat_SeatID",
                table: "BookingSeat",
                column: "SeatID");

            migrationBuilder.CreateIndex(
                name: "IX_Cinema_CityID",
                table: "Cinema",
                column: "CityID");

            migrationBuilder.CreateIndex(
                name: "IX_CinemaHall_CinemaID",
                table: "CinemaHall",
                column: "CinemaID");

            migrationBuilder.CreateIndex(
                name: "IX_CinemaHallSeat_HallID",
                table: "CinemaHallSeat",
                column: "HallID");

            migrationBuilder.CreateIndex(
                name: "IX_LikeMovie_MovieID",
                table: "LikeMovie",
                column: "MovieID");

            migrationBuilder.CreateIndex(
                name: "IX_LoginHistory_account_id",
                table: "LoginHistory",
                column: "account_id");

            migrationBuilder.CreateIndex(
                name: "IX_Notification_UserID",
                table: "Notification",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_OTPs_account_id",
                table: "OTPs",
                column: "account_id");

            migrationBuilder.CreateIndex(
                name: "IX_Payment_BookingID",
                table: "Payment",
                column: "BookingID");

            migrationBuilder.CreateIndex(
                name: "IX_RefreshTokens_account_id",
                table: "RefreshTokens",
                column: "account_id");

            migrationBuilder.CreateIndex(
                name: "IX_RolePermissions_permission_id",
                table: "RolePermissions",
                column: "permission_id");

            migrationBuilder.CreateIndex(
                name: "IX_RolePermissions_role_id",
                table: "RolePermissions",
                column: "role_id");

            migrationBuilder.CreateIndex(
                name: "IX_Show_HallID",
                table: "Show",
                column: "HallID");

            migrationBuilder.CreateIndex(
                name: "IX_Show_MovieID",
                table: "Show",
                column: "MovieID");

            migrationBuilder.CreateIndex(
                name: "IX_Users_account_id",
                table: "Users",
                column: "account_id");

            migrationBuilder.CreateIndex(
                name: "UQ__Voucher__A25C5AA7A3652744",
                table: "Voucher",
                column: "Code",
                unique: true,
                filter: "[Code] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_VoucherUsage_UserID",
                table: "VoucherUsage",
                column: "UserID");

            migrationBuilder.CreateIndex(
                name: "IX_VoucherUsage_VoucherID",
                table: "VoucherUsage",
                column: "VoucherID");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AccountRole");

            migrationBuilder.DropTable(
                name: "BookingProduct");

            migrationBuilder.DropTable(
                name: "BookingSeat");

            migrationBuilder.DropTable(
                name: "LikeMovie");

            migrationBuilder.DropTable(
                name: "LoginHistory");

            migrationBuilder.DropTable(
                name: "Notification");

            migrationBuilder.DropTable(
                name: "OTPs");

            migrationBuilder.DropTable(
                name: "Payment");

            migrationBuilder.DropTable(
                name: "RefreshTokens");

            migrationBuilder.DropTable(
                name: "RolePermissions");

            migrationBuilder.DropTable(
                name: "VoucherUsage");

            migrationBuilder.DropTable(
                name: "Product");

            migrationBuilder.DropTable(
                name: "CinemaHallSeat");

            migrationBuilder.DropTable(
                name: "Booking");

            migrationBuilder.DropTable(
                name: "Permissions");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropTable(
                name: "Voucher");

            migrationBuilder.DropTable(
                name: "Show");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "CinemaHall");

            migrationBuilder.DropTable(
                name: "Movie");

            migrationBuilder.DropTable(
                name: "Account");

            migrationBuilder.DropTable(
                name: "Cinema");

            migrationBuilder.DropTable(
                name: "City");
        }
    }
}
