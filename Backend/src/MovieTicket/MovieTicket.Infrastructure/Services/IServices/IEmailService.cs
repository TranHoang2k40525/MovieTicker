namespace MovieTicket.Infrastructure.Services.IServices
{
    /// <summary>
    /// Interface for email service
    /// </summary>
    public interface IEmailService
    {
        /// <summary>
        /// Send email to a single recipient
        /// </summary>
        Task<bool> SendEmailAsync(string to, string subject, string body);

        /// <summary>
        /// Send email to multiple recipients
        /// </summary>
        Task<bool> SendEmailToMultipleAsync(List<string> recipients, string subject, string body);
    }

    /// <summary>
    /// Email configuration class
    /// </summary>
    public class EmailConfig
    {
        public string SmtpHost { get; set; } = string.Empty;
        public int SmtpPort { get; set; }
        public string SmtpUser { get; set; } = string.Empty;
        public string SmtpPass { get; set; } = string.Empty;
        public string From { get; set; } = string.Empty;
    }
}
