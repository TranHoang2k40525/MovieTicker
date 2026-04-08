-- =========================================================
-- SCRIPT ĐỂ SEED TÀI KHOẢN ADMIN VÀO CƠ SỞ DỮ LIỆU
-- Cập nhật mật khẩu cho Admin: "Admin@123"
-- Password thực tế được hash bằng BCrypt (Cost=10)
-- =========================================================
USE [rapphimVIP]
GO

-- 1. Thêm Roles nếu chưa có
IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [role_name] = 'Admin')
BEGIN
    INSERT INTO [dbo].[Roles] ([role_name], [role_type]) VALUES ('Admin', 'Admin')
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [role_name] = 'Manager')
BEGIN
    INSERT INTO [dbo].[Roles] ([role_name], [role_type]) VALUES ('Manager', 'Manager')
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [role_name] = 'Staff')
BEGIN
    INSERT INTO [dbo].[Roles] ([role_name], [role_type]) VALUES ('Staff', 'Staff')
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [role_name] = 'User')
BEGIN
    INSERT INTO [dbo].[Roles] ([role_name], [role_type]) VALUES ('User', 'User')
END

-- 2. Thêm Account Admin
DECLARE @AdminEmail NVARCHAR(100) = 'admin@demo.com';
DECLARE @AdminPhone NVARCHAR(20) = '0999999999';
-- Hash BCrypt cho 'Admin@123'
DECLARE @AdminPasswordHash NVARCHAR(255) = '$2a$10$vI8aWBnW3fID.ZQ4/zo1G.q1lRps.9cGLcZEiGDIbvMBh3/g0z5X2'; 

IF NOT EXISTS (SELECT 1 FROM [dbo].[Account] WHERE [email] = @AdminEmail)
BEGIN
    INSERT INTO [dbo].[Account] ([email], [phone], [password_hash], [status], [created_at], [updated_at])
    VALUES (@AdminEmail, @AdminPhone, @AdminPasswordHash, 'active', GETDATE(), GETDATE());

    DECLARE @NewAccountId INT = SCOPE_IDENTITY();

    -- Thêm Role Admin cho account này
    DECLARE @AdminRoleId INT = (SELECT [role_id] FROM [dbo].[Roles] WHERE [role_name] = 'Admin');
    INSERT INTO [dbo].[AccountRole] ([account_id], [role_id]) VALUES (@NewAccountId, @AdminRoleId);

    -- Thêm User Profile tương ứng
    INSERT INTO [dbo].[Users] ([account_id], [full_name], [email], [phone], [gender], [address])
    VALUES (@NewAccountId, N'Hệ Thống Admin', @AdminEmail, @AdminPhone, N'Nam', N'Trụ sở chính');

    PRINT N'Thêm tài khoản Admin thành công. Username: admin@demo.com | Password: Admin@123';
END
ELSE
BEGIN
    PRINT N'Tài khoản admin@demo.com đã tồn tại.';
END
GO
