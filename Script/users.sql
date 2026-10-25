use WideWorldImporters;
go
if db_name() <> N'WideWorldImporters' throw 50000, N'Base incorrecta', 1;
go

-- ======================================================================================
-- USUARIOS
-- ======================================================================================

/*
    Crea la tabla de usuarios de la aplicación si todavía no existe.
    Define un identificador autoincremental, nombres de usuario y correos únicos,
    y establece que los usuarios estén activos por defecto.
    Si la tabla ya existe, conserva su estructura y sus datos.
*/
if object_id(N'dbo.Users', N'U') is null
    begin
        create table dbo.Users (
            UserID int identity(1, 1) not null,
            UserName nvarchar(50) not null,
            [Password] nvarchar(255) not null,
            FullName nvarchar(150) not null,
            Active bit not null constraint DF_Users_Active default (1),
            Rol nvarchar(50) not null,
            Email nvarchar(254) not null,
            HireDate date not null,
            constraint PK_Users primary key (UserID),
            constraint UQ_Users_UserName unique (UserName),
            constraint UQ_Users_Email unique (Email)
        )
    end
go

/*
    Comprueba que exista un usuario activo con el nombre de usuario y la contraseña indicados.
    Compara directamente la contraseña con el valor almacenado
    Devuelve: 1 si las credenciales coinciden y el usuario está activo; 0 en caso contrario.
*/
create or alter function dbo.ValidateUser (
    @UserName nvarchar(50), 
    @Password nvarchar(255)
)
returns bit
as
    begin
        declare @isValidUser bit = 0
        if exists (
            select 1
            from dbo.Users
            where 
                UserName = @UserName 
                and [Password] = @Password 
                and Active = 1
        )
        begin
            set @isValidUser = 1
        end
        return @isValidUser 
    end
go
