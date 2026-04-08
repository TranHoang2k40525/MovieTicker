using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class LoginHistory
    {
        public int HistoryId { get; set; }

        public int? AccountId { get; set; }

        public string? IpAddress { get; set; }

        public string? DeviceInfo { get; set; }

        public DateTime? LoginTime { get; set; }

        public virtual Account? Account { get; set; }
    }
}