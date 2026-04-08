using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MovieTicket.Infrastructure.Services.IServices;
using System.Net;
using System.Net.Mail;

namespace MovieTicket.Infrastructure.Services.Implementations
{
    /// <summary>
    /// EmailService: Gửi email qua Gmail SMTP
    /// </summary>
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        private EmailConfig GetEmailConfig()
        {
            return new EmailConfig
            {
                SmtpHost = _configuration["Email:SmtpHost"] ?? "",
                SmtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587"),
                SmtpUser = _configuration["Email:SmtpUser"] ?? "",
                SmtpPass = _configuration["Email:SmtpPass"] ?? "",
                From = _configuration["Email:From"] ?? ""
            };
        }

        /// <summary>
        /// Gửi email tới một người
        /// </summary>
        public async Task<bool> SendEmailAsync(string to, string subject, string body)
        {
            try
            {
                var config = GetEmailConfig();

                if (string.IsNullOrEmpty(config.SmtpHost))
                {
                    _logger.LogError("Email SMTP Host không được cấu hình");
                    return false;
                }

                using (var smtpClient = new SmtpClient(config.SmtpHost, config.SmtpPort))
                {
                    smtpClient.EnableSsl = true;
                    smtpClient.Timeout = 10000;
                    smtpClient.Credentials = new NetworkCredential(config.SmtpUser, config.SmtpPass);

                    using (var mailMessage = new MailMessage(config.From, to))
                    {
                        mailMessage.Subject = subject;
                        mailMessage.Body = body;
                        mailMessage.IsBodyHtml = true;

                        await smtpClient.SendMailAsync(mailMessage);
                        _logger.LogInformation($"Email gửi thành công tới {to}");
                        return true;
                    }
                }
            }
            catch (SmtpException ex)
            {
                _logger.LogError($"Lỗi SMTP: {ex.Message}");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi gửi email: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Gửi email tới nhiều người
        /// </summary>
        public async Task<bool> SendEmailToMultipleAsync(List<string> recipients, string subject, string body)
        {
            try
            {
                var config = GetEmailConfig();

                using (var smtpClient = new SmtpClient(config.SmtpHost, config.SmtpPort))
                {
                    smtpClient.EnableSsl = true;
                    smtpClient.Timeout = 10000;
                    smtpClient.Credentials = new NetworkCredential(config.SmtpUser, config.SmtpPass);

                    using (var mailMessage = new MailMessage(config.From, string.Empty))
                    {
                        mailMessage.Subject = subject;
                        mailMessage.Body = body;
                        mailMessage.IsBodyHtml = true;

                        foreach (var recipient in recipients)
                            mailMessage.To.Add(recipient);

                        await smtpClient.SendMailAsync(mailMessage);
                        _logger.LogInformation($"Email gửi thành công tới {recipients.Count} người");
                        return true;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi gửi email tới nhiều người: {ex.Message}");
                return false;
            }
        }
    }

    public class EmailConfig
    {
        public string SmtpHost { get; set; } = "";
        public int SmtpPort { get; set; } = 587;
        public string SmtpUser { get; set; } = "";
        public string SmtpPass { get; set; } = "";
        public string From { get; set; } = "";
    }
}
