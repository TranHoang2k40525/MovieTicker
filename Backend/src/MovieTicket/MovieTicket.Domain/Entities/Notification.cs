using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class Notification
    {
        public int NotificationId { get; set; }

        public int? UserId { get; set; }

        public string? Message { get; set; }

        public DateTime? DateSent { get; set; }

        public bool? IsRead { get; set; }

        public string? DeviceInfo { get; set; }

        public string? Ipaddress { get; set; }

        public virtual User? User { get; set; }
    }
}