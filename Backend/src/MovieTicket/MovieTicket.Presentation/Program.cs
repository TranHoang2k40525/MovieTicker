using System.Text;
using DotNetEnv;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MovieTicket.Application.IServices;
using MovieTicket.Application.Services;
using MovieTicket.Application.Services.Implementations.Booking;
using MovieTicket.Application.Services.Implementations.Checkout;
using MovieTicket.Application.Services.Implementations.Cinema;
using MovieTicket.Application.Services.Implementations.Movie;
using MovieTicket.Application.Services.Implementations.Payment;
using MovieTicket.Application.Services.Implementations.Product;
using MovieTicket.Application.Services.Implementations.Ticket;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Application.Services.IServices.ICheckout;
using MovieTicket.Application.Services.IServices.ICinema;
using MovieTicket.Application.Services.IServices.IMovie;
using MovieTicket.Application.Services.IServices.IPayment;
using MovieTicket.Application.Services.IServices.IProduct;
using MovieTicket.Application.Services.IServices.ITicket;
using MovieTicket.Domain.IReponsitories.IMovie;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.IResponsitories.IBooking;
using MovieTicket.Domain.IResponsitories.ICheckout;
using MovieTicket.Domain.IResponsitories.ICinema;
using MovieTicket.Domain.IResponsitories.IProduct;
using MovieTicket.Domain.IResponsitories.ITicket;
using MovieTicket.Infrastructure.AppDbContext;
using MovieTicket.Infrastructure.Repositories.AuthRespository;
using MovieTicket.Infrastructure.Repositories.BookingRepository;
using MovieTicket.Infrastructure.Repositories.CheckoutRepository;
using MovieTicket.Infrastructure.Repositories.CinemaRepository;
using MovieTicket.Infrastructure.Repositories.MovieRespository;
using MovieTicket.Infrastructure.Repositories.ProductRepository;
using MovieTicket.Infrastructure.Repositories.TicketRepository;
using MovieTicket.Infrastructure.Services.Implementations;
using MovieTicket.Infrastructure.Services.IServices;
using MovieTicket.Presentation.Services;
using Serilog;

// Load .env file
Env.Load();

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .WriteTo.File("Logs/MovieTicketLog-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);
    builder.Host.UseSerilog();

    // Override configuration with environment variables
    var config = builder.Configuration;
    config.AddEnvironmentVariables();

    // Build connection string: prefer .env parts, fallback to appsettings connection string
    var envDbServer = Environment.GetEnvironmentVariable("DB_SERVER");
    var envDbName = Environment.GetEnvironmentVariable("DB_NAME");
    var envDbUser = Environment.GetEnvironmentVariable("DB_USER");
    var envDbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD");
    var envDbEncrypt = Environment.GetEnvironmentVariable("DB_ENCRYPT") ?? "false";
    var envTrustedConnection = Environment.GetEnvironmentVariable("DB_TRUSTED_CONNECTION") ?? "false";

    var hasEnvDbConfig = !string.IsNullOrWhiteSpace(envDbServer)
        && !string.IsNullOrWhiteSpace(envDbName);

    var connectionString = hasEnvDbConfig
        ? $"Server={envDbServer};Database={envDbName};User Id={envDbUser ?? "sa"};Password={envDbPassword ?? string.Empty};TrustServerCertificate=True;Encrypt={envDbEncrypt};Trusted_Connection={envTrustedConnection};"
        : (config.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Thiáº¿u cáº¥u hÃ¬nh ConnectionStrings:DefaultConnection hoáº·c biáº¿n DB_* trong .env"));

    // =====================================================
    // DEPENDENCY INJECTION
    // =====================================================

    // Repositories
    builder.Services.AddScoped<IAccountRepository, AccountRepository>();
    builder.Services.AddScoped<IOtpRepository, OtpRepository>();
    builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();
    builder.Services.AddScoped<ILoginHistoryRepository, LoginHistoryRepository>();
    builder.Services.AddScoped<IUserRepository, UserRepository>();
    builder.Services.AddScoped<IAccountRoleRepository, AccountRoleRepository>();
    builder.Services.AddScoped<IRoleRepository, RoleRepository>();
    builder.Services.AddScoped<IProductRepository, ProductRepository>();
    builder.Services.AddScoped<ISeatMapRepository, SeatMapRepository>();
    builder.Services.AddScoped<IBookingRepository, BookingRepository>();
    builder.Services.AddScoped<ICheckoutRepository, CheckoutRepository>();
    builder.Services.AddScoped<ITicketRepository, TicketRepository>();


    // Services
    builder.Services.AddScoped<IPasswordHashService, PasswordHashService>();
    builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
    builder.Services.AddScoped<IOtpService, OtpService>();
    builder.Services.AddScoped<IEmailService, EmailService>();
    builder.Services.AddScoped<IAuthService, AuthService>();
    builder.Services.AddScoped<IUserService, UserService>();

    builder.Services.AddScoped<IMovieRepository, MovieRepository>();
    builder.Services.AddScoped<IMoviePubService, MoviePubService>();

    builder.Services.AddScoped<ICinemaRepository, CinemaRepository>();
    builder.Services.AddScoped<ICinemaShowtimeRepository, CinemaShowtimeRepository>();
    builder.Services.AddScoped<ICinemaPubService, CinemaPubService>();
    builder.Services.AddScoped<IProductService, ProductService>();
    builder.Services.AddScoped<ISeatMapService, SeatMapService>();
    builder.Services.AddScoped<IBookingFlowService, BookingFlowService>();
    builder.Services.AddScoped<ICheckoutService, CheckoutService>();
    builder.Services.AddScoped<ICheckoutEmailService, CheckoutEmailService>();
    builder.Services.AddScoped<IPaymentService, PaymentService>();
    builder.Services.AddScoped<IMyTicketService, MyTicketService>();
    // Background Tasks
    builder.Services.AddHostedService<AccountCleanupService>();
    builder.Services.AddHostedService<BookingHoldCleanupService>();

    // DbContext
    builder.Services.AddDbContext<AppMovieTickerDbContext>(options =>
        options.UseSqlServer(connectionString));

    // =====================================================
    // AUTHENTICATION - JWT
    // =====================================================
    var jwtSecretKey = Environment.GetEnvironmentVariable("JWT_SECRET_KEY") ??
                       builder.Configuration["Jwt:SecretKey"] ??
                       "MyVeryLongSecretKeyForJwtTokenThatIsAtLeast32Characters!@#";

    var jwtIssuer = Environment.GetEnvironmentVariable("JWT_ISSUER") ??
                    builder.Configuration["Jwt:Issuer"] ??
                    "MovieTicketApp";

    var jwtAudience = Environment.GetEnvironmentVariable("JWT_AUDIENCE") ??
                      builder.Configuration["Jwt:Audience"] ??
                      "MovieTicketUsers";

    if (string.IsNullOrEmpty(jwtSecretKey))
        throw new InvalidOperationException("JWT SecretKey khÃ´ng Ä‘Æ°á»£c cáº¥u hÃ¬nh");

    var key = Encoding.ASCII.GetBytes(jwtSecretKey);

    builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

    // =====================================================
    // CORS
    // =====================================================
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("AllowAll", builder =>
        {
            builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
    });

    // =====================================================
    // CONTROLLERS & SWAGGER
    // =====================================================
    builder.Services.AddControllers();
    builder.Services.AddMemoryCache();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen(options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo { Title = "MovieTicket API", Version = "v1" });

        // Add JWT Authorization to Swagger
        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            In = ParameterLocation.Header,
            Description = "Please enter token",
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            BearerFormat = "JWT",
            Scheme = "bearer"
        });

        options.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] { }
        }
        });
    });

    // =====================================================
    // BUILD
    // =====================================================
    var app = builder.Build();

    // Apply EF Core migrations automatically at startup
    using (var scope = app.Services.CreateScope())
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<AppMovieTickerDbContext>();
        dbContext.Database.Migrate();
    }

    // =====================================================
    // MIDDLEWARE
    // =====================================================
    app.UseStaticFiles();

    // Map /assets to the real Backend/Assets folder.
    var contentRoot = builder.Environment.ContentRootPath;
    var assetsCandidates = new[]
    {
    Path.GetFullPath(Path.Combine(contentRoot, "..", "..", "..", "Assets")),
    Path.GetFullPath(Path.Combine(contentRoot, "..", "Assets"))
};

    var assetsPath = assetsCandidates.FirstOrDefault(Directory.Exists) ?? assetsCandidates[0];
    if (!Directory.Exists(assetsPath))
    {
        Directory.CreateDirectory(assetsPath);
    }

    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(assetsPath),
        RequestPath = "/assets"
    });

    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.ConfigObject.PersistAuthorization = true;
    });

    if (!app.Environment.IsDevelopment())
    {
        app.UseHttpsRedirection();
    }

    app.UseCors("AllowAll");

    app.UseAuthentication();
    app.UseAuthorization();

    app.MapControllers();

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

