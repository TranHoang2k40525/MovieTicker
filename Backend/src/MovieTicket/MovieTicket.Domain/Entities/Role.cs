using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class Role
    {
        public int RoleId { get; set; }

        public string? RoleName { get; set; }

        public RoleType? Type { get; set; }

        public virtual ICollection<AccountRole> AccountRoles { get; set; } = new List<AccountRole>();

        public virtual ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
    }

    public enum RoleType
    {
        User,
        Staff,
        Manager,
        Admin
    }
}