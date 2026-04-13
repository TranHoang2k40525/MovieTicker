
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Infrastructure.Configurations;
namespace MovieTicket.Infrastructure.AppDbContext
{
    public class AppMovieTickerDbContext : DbContext
    {
        public AppMovieTickerDbContext(DbContextOptions<AppMovieTickerDbContext> option) : base(option) { }
        public virtual DbSet<Account> Accounts { get; set; }

        public virtual DbSet<AccountRole> AccountRoles { get; set; }

        public virtual DbSet<Booking> Bookings { get; set; }

        public virtual DbSet<BookingProduct> BookingProducts { get; set; }

        public virtual DbSet<BookingSeat> BookingSeats { get; set; }

        public virtual DbSet<Cinema> Cinemas { get; set; }

        public virtual DbSet<CinemaHall> CinemaHalls { get; set; }

        public virtual DbSet<CinemaHallSeat> CinemaHallSeats { get; set; }

        public virtual DbSet<City> Cities { get; set; }

        public virtual DbSet<LikeMovie> LikeMovies { get; set; }

        public virtual DbSet<LoginHistory> LoginHistories { get; set; }

        public virtual DbSet<Movie> Movies { get; set; }

        public virtual DbSet<Notification> Notifications { get; set; }

        public virtual DbSet<Otp> Otps { get; set; }

        public virtual DbSet<Payment> Payments { get; set; }

        public virtual DbSet<Permission> Permissions { get; set; }

        public virtual DbSet<Product> Products { get; set; }

        public virtual DbSet<RefreshToken> RefreshTokens { get; set; }

        public virtual DbSet<Role> Roles { get; set; }

        public virtual DbSet<RolePermission> RolePermissions { get; set; }

        public virtual DbSet<RoomLayout> RoomLayouts { get; set; }

        public virtual DbSet<Show> Shows { get; set; }

        public virtual DbSet<User> Users { get; set; }

        public virtual DbSet<Voucher> Vouchers { get; set; }

        public virtual DbSet<VoucherUsage> VoucherUsages { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfiguration(new AccountConfiguration());
            modelBuilder.ApplyConfiguration(new AccountRoleConfiguration());
            modelBuilder.ApplyConfiguration(new BookingConfiguration());
            modelBuilder.ApplyConfiguration(new BookingProductConfiguration());
            modelBuilder.ApplyConfiguration(new BookingSeatConfiguration());
            modelBuilder.ApplyConfiguration(new CinemaConfiguration());
            modelBuilder.ApplyConfiguration(new CinemaHallConfiguration());
            modelBuilder.ApplyConfiguration(new CinemaHallSeatConfiguration());
            modelBuilder.ApplyConfiguration(new CityConfiguration());
            modelBuilder.ApplyConfiguration(new LikeMovieConfiguration());
            modelBuilder.ApplyConfiguration(new LoginHistoryConfiguration());
            modelBuilder.ApplyConfiguration(new MovieConfiguration());
            modelBuilder.ApplyConfiguration(new NotificationConfiguration());
            modelBuilder.ApplyConfiguration(new OtpConfiguration());
            modelBuilder.ApplyConfiguration(new PaymentConfiguration());
            modelBuilder.ApplyConfiguration(new PermissionConfiguration());
            modelBuilder.ApplyConfiguration(new ProductConfiguration());
            modelBuilder.ApplyConfiguration(new RefreshTokenConfiguration());
            modelBuilder.ApplyConfiguration(new RoleConfiguration());
            modelBuilder.ApplyConfiguration(new RolePermissionConfiguration());
            modelBuilder.ApplyConfiguration(new RoomLayoutConfiguration());
            modelBuilder.ApplyConfiguration(new ShowConfiguration());
            modelBuilder.ApplyConfiguration(new UserConfiguration());
            modelBuilder.ApplyConfiguration(new VoucherConfiguration());
            modelBuilder.ApplyConfiguration(new VoucherUsageConfiguration());

        }
    }
}
