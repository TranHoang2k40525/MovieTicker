-- =========================================================
-- SCRIPT ĐỂ SEED TÀI KHOẢN ADMIN VÀO CƠ SỞ DỮ LIỆU
-- Cập nhật mật khẩu cho Admin: "Admin@123"
-- Password thực tế được hash bằng BCrypt (Cost=10)
-- =========================================================
USE [rapphimVIP]
GO



-- 2. Thêm Account Admin
DECLARE @AdminEmail NVARCHAR(100) = 'hoangzai2k403@gmail.com';
DECLARE @AdminPhone NVARCHAR(20) = '0987654321';
-- Hash BCrypt cho 'Admin@123'
DECLARE @AdminPasswordHash NVARCHAR(255) = '$2a$12$S0/O4RsL3UMRZhLQiop3/OS681yoG05n0hjVOpHNhxie9l5Yph03W'; 

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

    PRINT N'Thêm tài khoản Admin thành công. Username: hoangzai2k403@gmail.com | Password: 123456789';
END
ELSE
BEGIN
    PRINT N'Tài khoản hoangzai2k403@gmail.com đã tồn tại.';
END
GO
