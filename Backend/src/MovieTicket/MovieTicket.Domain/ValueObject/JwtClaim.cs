using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Domain.ValueObject
{
    public class JwtClaim
    {
        public int AccountId { get; set; }
        public string ? Email { get; set; }
        public List<string> Role { get; set; } = new List<string>();
        public List<string> Permissions { get; set; } = new List<string>();
        // thoi gian token duoc tao ra
        public DateTime IssuedAt { get; set; } = DateTime.Now;
        // thoi gian token het han  
        public DateTime ExpiresAt { get; set; }

    }
}
