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
    Comprueba las credenciales de un usuario activo mediante SHA2_256.
    No devuelve filas si las credenciales no coinciden o el usuario está inactivo.
    Devuelve: UserID, UserName, FullName, Rol, Active
*/
create or alter procedure dbo.LoginUser
    @UserName nvarchar(50),
    @Password nvarchar(255)
as
begin
    set nocount on;

    select
        UserID,
        UserName,
        FullName,
        Rol,
        Active
    from dbo.Users
    where UserName = @UserName
      and [Password] = convert(varchar(64), hashbytes('SHA2_256', @Password), 2)
      and Active = 1;
end
go
