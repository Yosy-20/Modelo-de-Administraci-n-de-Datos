use MAD_PIA;

-- USUARIO

CREATE TABLE Usuario(
id INT  PRIMARY KEY IDENTITY(1,1) NOT NULL,
Nombre VARCHAR(80),
Correo VARCHAR(80),
Contrase�a VARCHAR(20),
Genero VARCHAR(15),
Estatus INT,
FechaNam DATE
);

-- Atributos agregados

ALTER TABLE Usuario
ADD NomUsuario VARCHAR(80);

ALTER TABLE Usuario
ADD FechaRegistro DATETIME DEFAULT GETDATE();

ALTER TABLE Usuario
ADD FechaBaja DATETIME DEFAULT GETDATE();

-- Funciones 

--1)
CREATE FUNCTION ValidarContrase�a
(
    @Contrase�a VARCHAR(20)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Resultado BIT = 0;

    IF LEN(@Contrase�a) >= 8 AND
       PATINDEX('%[A-Z]%', @Contrase�a) > 0 AND
       PATINDEX('%[a-z]%', @Contrase�a) > 0 AND
       PATINDEX('%[0-9]%', @Contrase�a) > 0 AND
       PATINDEX('%[^a-zA-Z0-9]%', @Contrase�a) > 0
    BEGIN
        SET @Resultado = 1;
    END

    RETURN @Resultado;
END;


--2)
CREATE FUNCTION CalcularEdadUsuario
(
    @FechaNam DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Edad INT;
    SET @Edad = DATEDIFF(YEAR, @FechaNam, GETDATE());
    RETURN @Edad;
END;


--3)

CREATE FUNCTION ValidarCorreoElectronico
(@Correo VARCHAR(100))
RETURNS BIT
AS
BEGIN
    DECLARE @EsValido BIT;

    -- Utilizamos una expresi�n regular para verificar la sintaxis del correo electr�nico
    IF @Correo LIKE '%_@__%.__%'
        AND PATINDEX('%[^a-zA-Z0-9.@]%', @Correo) = 0
        AND LEN(@Correo) <= 100
    BEGIN
        SET @EsValido = 1; -- Correo electr�nico v�lido
    END
    ELSE
    BEGIN
        SET @EsValido = 0; -- Correo electr�nico no v�lido
    END

    RETURN @EsValido;
END;


--4)

CREATE FUNCTION VerificarCorreo
(
    @Correo VARCHAR(80)
	
)
RETURNS BIT
AS
BEGIN
    DECLARE @Resultado BIT;

    IF EXISTS (SELECT 1 FROM Usuario WHERE Correo = @Correo AND Estatus = 1)
    BEGIN
        SET @Resultado = 1; -- Correo electr�nico existe
    END
    ELSE
    BEGIN
        SET @Resultado = 0; -- Correo electr�nico no existe
    END

    RETURN @Resultado;
END;


--5)


CREATE FUNCTION VerificarNombreUsuario
(
    @NombreUsuario VARCHAR(80)
	 
)
RETURNS BIT
AS
BEGIN
    DECLARE @Resultado BIT;

    IF EXISTS (SELECT 1 FROM Usuario WHERE NomUsuario = @NombreUsuario AND Estatus = 1 )
    BEGIN
        SET @Resultado = 1; -- Nombre de usuario existe
    END
    ELSE
    BEGIN
        SET @Resultado = 0; -- Nombre de usuario no existe
    END

    RETURN @Resultado;
END;


-- Triggers

-- 1)

CREATE TRIGGER trg_InsertarFechaRegistro
ON Usuario
AFTER INSERT
AS
BEGIN
    UPDATE Usuario
    SET FechaRegistro = GETDATE()
    WHERE id IN (SELECT id FROM inserted);
END;  


-- 2)

CREATE TRIGGER trg_InsertarFechaBaja
ON Usuario
AFTER UPDATE
AS
BEGIN
     
      UPDATE Usuario
      SET FechaBaja = GETDATE()
      WHERE id IN (SELECT id FROM inserted);
   
END;


-- Procedure

-- 1)

CREATE PROCEDURE InsertarUsuario
                 @Nombre VARCHAR(80), @Correo VARCHAR(80), @Contrase�a VARCHAR(20),@Genero VARCHAR(15),  @Estatus INT, @FechaNam DATE, @NomUsua VARCHAR(80)
AS
BEGIN
    DECLARE @Edad INT;
    DECLARE @EsContrase�aValida BIT;
	DECLARE @EsCorreoValido BIT;

    
    -- Llamar a la funci�n para calcular la edad
    SET @Edad = dbo.CalcularEdadUsuario(@FechaNam);

    -- Llamar a la funci�n para validar la contrase�a
    SET @EsContrase�aValida = dbo.ValidarContrase�a(@Contrase�a);

	 -- Llamar a la funci�n para validar la correo
    SET @EsCorreoValido = dbo.ValidarCorreoElectronico(@Correo);

	 -- Verificar si el nombre de usuario ya est� en uso
    IF dbo.VerificarNombreUsuario(@NomUsua) = 1
    BEGIN
        -- Manejar el caso donde el nombre de usuario ya existe
        RAISERROR ('El nombre de usuario ya est� en uso.', 16, 1);
        RETURN;
    END

    -- Verificar si el correo electr�nico ya est� en uso
    IF dbo.VerificarCorreo(@Correo) = 1
    BEGIN
        -- Manejar el caso donde el correo electr�nico ya existe
        RAISERROR ('El correo electr�nico ya est� en uso.', 16, 1);
        RETURN;
    END




    -- Verificar si la edad es mayor o igual a 12 a�os
    IF @Edad >= 12
    BEGIN
        -- Verificar si la contrase�a es v�lida
        IF @EsContrase�aValida = 1
        BEGIN

		           IF @EsCorreoValido = 1
                   BEGIN

                      -- Insertar el usuario si la edad y la contrase�a son v�lidas
                      INSERT INTO Usuario (Nombre, Correo, Contrase�a, Genero, Estatus, FechaNam, NomUsuario) 
                      VALUES (@Nombre, @Correo, @Contrase�a, @Genero, @Estatus, @FechaNam, @NomUsua );
                 END
				 ELSE
                 BEGIN
				 -- Manejar el caso donde el correo no es v�lido
                  RAISERROR ('El correo no cumple con el formato.', 16, 1);


				 END
        END
        ELSE
        BEGIN
            -- Manejar el caso donde la contrase�a no es v�lida
            RAISERROR ('La contrase�a no cumple con los requisitos de seguridad.', 16, 1);
        END
    END
    ELSE
    BEGIN
        -- Manejar el caso donde la edad es menor a 12
        RAISERROR ('El usuario debe tener al menos 12 a�os para registrarse.', 16, 1);
    END
END;



-- 2)


CREATE PROCEDURE ObtenerUsuarioPorCorreo
      @Correo VARCHAR(80)
AS
BEGIN
    SELECT 
        ID
    FROM Usuario 
    WHERE Correo = @Correo AND Estatus=1;
END;




-- 3)

CREATE PROCEDURE VerificarUsuario 
       @Correo VARCHAR(80), @Contrase�a  VARCHAR(20)
AS
BEGIN
    DECLARE @ExisteUsuario BIT = 0;
   
    IF NOT EXISTS (
        SELECT 1 
        FROM Usuario 
        WHERE Correo = @Correo AND Estatus=1 
    )
    BEGIN
        
		 RAISERROR ('El usuario no existe.', 16, 1);
        RETURN;
    END
	
    IF NOT EXISTS (
        SELECT 1 
        FROM Usuario 
        WHERE Contrase�a = @Contrase�a AND Estatus=1 
    )
    BEGIN
        RAISERROR ('Contrase�a Incorrecta.', 16, 1);
        RETURN;
    END

    -- Si se pasa ambas verificaciones, el usuario es v�lido
    SET @ExisteUsuario = 1;

    SELECT @ExisteUsuario AS UsuarioValido;
END;


-- 4)


CREATE PROCEDURE EditarUsuario 
        @id INT, @Nombre VARCHAR(80), @Correo VARCHAR(80), @Genero VARCHAR(15), @FechaNam DATE, @NomUsua VARCHAR(80)
AS
BEGIN
  DECLARE @Edad INT;
  DECLARE @EsCorreoValido BIT;
  
    
    -- Llamar a la funci�n para calcular la edad
    SET @Edad = dbo.CalcularEdadUsuario(@FechaNam);

	 -- Llamar a la funci�n para validar la correo
    SET @EsCorreoValido = dbo.ValidarCorreoElectronico(@Correo);


	IF dbo.VerificarNombreUsuario(@NomUsua) = 1
    BEGIN
        -- Manejar el caso donde el nombre de usuario ya existe
        RAISERROR ('El nombre de usuario ya est� en uso.', 16, 1);
        RETURN;
    END

    -- Verificar si el correo electr�nico ya est� en uso
    IF dbo.VerificarCorreo(@Correo) = 1
    BEGIN
        -- Manejar el caso donde el correo electr�nico ya existe
        RAISERROR ('El correo electr�nico ya est� en uso.', 16, 1);
        RETURN;
    END



    -- Verificar si la edad es mayor o igual a 12 a�os
    IF @Edad >= 12

    BEGIN
       IF @EsCorreoValido = 1
                   BEGIN

                      -- Editar el usuario si la edad y la Correo son v�lidos
                      UPDATE Usuario
                         SET Nombre  = @Nombre, 
                            Correo  = @Correo,
		                    Genero  = @Genero,
			                FechaNam  = @FechaNam,
			                NomUsuario  =@NomUsua
                         WHERE id = @id;
	
                 END
				 ELSE
                 BEGIN
				 
                  RAISERROR ('El correo no cumple con el formato.', 16, 1);


				 END


    END
    ELSE
    BEGIN
       
        RAISERROR ('El usuario debe tener al menos 12 a�os para registrarse.', 16, 1);
    END

END;




--5)

CREATE PROCEDURE BorrarUsuario 
       @id INT, @Estatus INT
AS
BEGIN
        UPDATE Usuario
        SET Estatus = @Estatus
        WHERE id = @id;
	
END;




--6)
CREATE PROCEDURE ActualizarContrase�a 
       @id INT, @Contrase�a  INT
AS
BEGIN
        UPDATE Usuario
        SET Contrase�a  = @Contrase�a 
        WHERE id = @id;
	
END;



--CONTRASE�A PROVISIONAL


CREATE TABLE Contrase�aP(
id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
Contrase�a VARCHAR(20)
);


CREATE TABLE UsuarioContrase�aP(
idUsuario INT,
idContrase�aP INT,
PRIMARY KEY(idUsuario,idContrase�aP),
FOREIGN KEY (idUsuario) REFERENCES Usuario(id),
FOREIGN KEY (idContrase�aP) REFERENCES Contrase�aP(id)
);


--Procedure

--1)

CREATE PROCEDURE GenerarContrase�aP
 @idUsuario INT
AS
BEGIN
    DECLARE @Longitud INT
    SET @Longitud = 10

    DECLARE @Caracteres VARCHAR(100)
    DECLARE @Contrase�aProvisional VARCHAR(100)
	DECLARE @idContrase�aP INT

    SET @Caracteres = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()'
    
    DECLARE @Indice INT
    SET @Indice = 0
    
    SET @Contrase�aProvisional = ''

    WHILE @Indice < @Longitud
    BEGIN
        SET @Contrase�aProvisional = @Contrase�aProvisional + SUBSTRING(@Caracteres, CAST((RAND(CHECKSUM(NEWID())) * LEN(@Caracteres) + 1) AS INT), 1)
        SET @Indice = @Indice + 1
    END

    -- Insertar la contrase�a generada en la tabla Contrase�aP
    INSERT INTO Contrase�aP (Contrase�a)
    VALUES (@Contrase�aProvisional)

	-- Obtener el id generado para la nueva contrase�a
    SET @idContrase�aP = SCOPE_IDENTITY()

    -- Insertar en la tabla UsuarioContrase�aP
    INSERT INTO UsuarioContrase�aP (idUsuario, idContrase�aP)
    VALUES (@idUsuario, @idContrase�aP)


END;



--2)

CREATE PROCEDURE ObtenerContrase�aPporIdUsuario
    @idUsuario INT
AS
BEGIN
    SELECT 
        Contrase�aP.Contrase�a
    FROM 
        Contrase�aP
    INNER JOIN 
        UsuarioContrase�aP ON Contrase�aP.id = UsuarioContrase�aP.idContrase�aP
    WHERE 
        UsuarioContrase�aP.idUsuario = @idUsuario;
END;


--3)

CREATE PROCEDURE VerificarIngreso
    @Correo VARCHAR(80),
    @Contrase�aProvisional VARCHAR(20)
    
AS
BEGIN
    DECLARE  @EsValido BIT 
    DECLARE @idUsuario INT;
    DECLARE @idContrase�aP INT;

    -- Inicializar el valor de salida
    SET @EsValido = 0;

    -- Verificar si el correo existe en la tabla Usuario
    SELECT @idUsuario = id
    FROM Usuario
    WHERE Correo = @Correo;

    -- Si el usuario no existe, salir
    IF @idUsuario IS NULL
    BEGIN
	    RAISERROR ('Usuario Incorrecto .', 16, 1);
        RETURN;
    END

    -- Obtener el id de la contrase�a provisional
    SELECT @idContrase�aP = Contrase�aP.id
    FROM Contrase�aP
    INNER JOIN UsuarioContrase�aP ON Contrase�aP.id = UsuarioContrase�aP.idContrase�aP
    WHERE UsuarioContrase�aP.idUsuario = @idUsuario
    AND Contrase�aP.Contrase�a = @Contrase�aProvisional;

    -- Si la contrase�a provisional es v�lida, establecer @EsValido a 1
    IF @idContrase�aP IS NOT NULL
    BEGIN
	    
        SET @EsValido = 1;
    END
	ELSE
	BEGIN
	RAISERROR ('Contrase�a Incorrecta .', 16, 1);
	END
END;


--BIBLIA INFORMACION

--TESTAMENTO
CREATE TABLE Testamento(
Nombre  VARCHAR(30) PRIMARY KEY
);

INSERT INTO Testamento(Nombre) 
             VALUES ('NuevoTestamento');

INSERT INTO Testamento(Nombre) 
             VALUES ('Antiguo testamento');


CREATE TABLE UsuarioTestamento(
idTestamento VARCHAR(30),
idUsuario INT,
PRIMARY KEY(idTestamento, idUsuario),
FOREIGN KEY (idUsuario) REFERENCES Usuario(id),
FOREIGN KEY (idTestamento) REFERENCES Testamento(Nombre),
idioma VARCHAR(20)
);

SELECT*FROM UsuarioTestamento
TRUNCATE TABLE UsuarioTestamento

CREATE TABLE Testament(
Name  VARCHAR(30) PRIMARY KEY
);


INSERT INTO Testament(Name) 
             VALUES ('New Testament');

INSERT INTO Testament(Name) 
             VALUES ('The Pentateucho');


CREATE TABLE UserTestament(
idTestament VARCHAR(30),
idUser INT,
PRIMARY KEY(idTestament, idUser),
FOREIGN KEY (idUser) REFERENCES Usuario(id),
FOREIGN KEY (idTestament) REFERENCES Testament(Name),
languaje VARCHAR(20)
);



--Procedure

--1)

CREATE PROCEDURE DefinirIdioma
    @idTestamento VARCHAR(30),
    @idUsuario INT,
    @idioma VARCHAR(20)
AS
BEGIN

    IF @idioma = 'Espa�ol' 
	BEGIN

	 INSERT INTO UsuarioTestamento (idTestamento, idUsuario, idioma)
            VALUES (@idTestamento, @idUsuario, @idioma);
	END
	ELSE IF @idioma = 'Ingles' 
	BEGIN

	INSERT INTO UserTestament (idTestament, idUser, languaje)
            VALUES (@idTestamento, @idUsuario, @idioma);

	END


END;

--View

CREATE VIEW VistaTestamento AS
SELECT 
    Nombre
FROM 
    Testamento;



--LIBRO


CREATE TABLE Libro(
Numero INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
idTestamento VARCHAR(30),
nombre VARCHAR(60),
FOREIGN KEY (idTestamento) REFERENCES Testamento(Nombre)
);

INSERT INTO Libro( idTestamento, nombre) 
             VALUES ('NuevoTestamento','Apocalipsis');

INSERT INTO Libro( idTestamento,nombre) 
             VALUES ('NuevoTestamento','Evangelio segun San Juan');

INSERT INTO Libro( idTestamento,nombre) 
             VALUES ('NuevoTestamento','Hecho de los Apostoles');

INSERT INTO Libro( idTestamento,nombre) 
             VALUES ('Antiguo testamento','Eclesiastico');

INSERT INTO Libro( idTestamento,nombre) 
             VALUES ('Antiguo testamento','Genesis');

INSERT INTO Libro( idTestamento,nombre) 
             VALUES ('Antiguo testamento','Isaias');



--View



CREATE VIEW VistaLibro AS
SELECT 
    Libro.Numero AS NumeroLibro,
    Libro.nombre AS NombreLibro,
    Libro.idTestamento,
    Testamento.Nombre AS NombreTestamento
FROM 
    Libro
INNER JOIN 
    Testamento ON Libro.idTestamento = Testamento.Nombre;




--CAPITULO

CREATE TABLE Capitulo(
Numero INT PRIMARY KEY,
idLibro INT,
nombre VARCHAR(60),
FOREIGN KEY (idLibro) REFERENCES Libro(Numero)
);

--View

CREATE VIEW VistaCapitulo AS
SELECT 
    Capitulo.Numero AS NumeroCapitulo,
    Capitulo.nombre AS NombreCapitulo,
    Capitulo.idLibro,
    Libro.Nombre AS NombreLibro
FROM 
    Capitulo
INNER JOIN 
    Libro ON Capitulo.idLibro = Libro.Numero;




--Procedure
CREATE PROCEDURE InsertarCapitulos @Nom VARCHAR(60)
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @totalCapitulos INT = 60; 
    
    WHILE @i <= @totalCapitulos
    BEGIN
        DECLARE @j INT = @i; 
        DECLARE @idLibro INT = (@i - 1) / 10 + 1; 
        
       INSERT INTO Capitulo(Numero, idLibro,nombre) VALUES (@i, @idLibro,@Nom);
        
        SET @i = @i + 1;
    END
END;


EXEC InsertarCapitulos @Nom='Capitulo 1';

CREATE PROCEDURE Insernombrecapitulo
       @Numero INT,@Nom VARCHAR(200)
AS
BEGIN
        UPDATE Capitulo
        SET Nombre  = @Nom 
        WHERE Numero = @Numero;
	
END;


--apocalipsis 1-10
EXEC Insernombrecapitulo @Nom='Capitulo 1', @Numero = 1;
EXEC Insernombrecapitulo @Nom='Capitulo 2', @Numero = 2;
EXEC Insernombrecapitulo @Nom='Capitulo 3',@Numero = 3;
EXEC Insernombrecapitulo @Nom='Capitulo 4',@Numero = 4;
EXEC Insernombrecapitulo @Nom='Capitulo 5',@Numero = 5;
EXEC Insernombrecapitulo @Nom='Capitulo 6',@Numero = 6;
EXEC Insernombrecapitulo @Nom='Capitulo 7',@Numero = 7;
EXEC Insernombrecapitulo @Nom='Capitulo 8',@Numero = 8;
EXEC Insernombrecapitulo @Nom='Capitulo 9',@Numero = 9;
EXEC Insernombrecapitulo @Nom='Capitulo 10',@Numero = 10;
--segun san juan11-20
EXEC Insernombrecapitulo @Nom='Capitulo 11',@Numero = 11;
EXEC Insernombrecapitulo @Nom='Capitulo 12',@Numero = 12;
EXEC Insernombrecapitulo @Nom='Capitulo 13',@Numero = 13;
EXEC Insernombrecapitulo @Nom='Capitulo 14',@Numero = 14;
EXEC Insernombrecapitulo @Nom='Capitulo 15',@Numero = 15;
EXEC Insernombrecapitulo @Nom='Capitulo 16',@Numero = 16;
EXEC Insernombrecapitulo @Nom='Capitulo 17',@Numero = 17;
EXEC Insernombrecapitulo @Nom='Capitulo 18',@Numero = 18;
EXEC Insernombrecapitulo @Nom='Capitulo 19',@Numero = 19;
EXEC Insernombrecapitulo @Nom='Capitulo 20',@Numero = 20;
--apostoles 21-30
EXEC Insernombrecapitulo @Nom='Capitulo 21',@Numero = 21;
EXEC Insernombrecapitulo @Nom='Capitulo 22',@Numero = 22;
EXEC Insernombrecapitulo @Nom='Capitulo 23',@Numero = 23;
EXEC Insernombrecapitulo @Nom='Capitulo 24',@Numero = 24;
EXEC Insernombrecapitulo @Nom='Capitulo 25',@Numero = 25;
EXEC Insernombrecapitulo @Nom='Capitulo 26',@Numero = 26;
EXEC Insernombrecapitulo @Nom='Capitulo 27',@Numero = 27;
EXEC Insernombrecapitulo @Nom='Capitulo 28',@Numero = 28;
EXEC Insernombrecapitulo @Nom='Capitulo 29',@Numero = 29;
EXEC Insernombrecapitulo @Nom='Capitulo 30',@Numero = 30;
--ecesiastico 31-40
EXEC Insernombrecapitulo @Nom='Capitulo 31',@Numero = 31;
EXEC Insernombrecapitulo @Nom='Capitulo 32',@Numero = 32;
EXEC Insernombrecapitulo @Nom='Capitulo 33',@Numero = 33;
EXEC Insernombrecapitulo @Nom='Capitulo 34',@Numero = 34;
EXEC Insernombrecapitulo @Nom='Capitulo 35',@Numero = 35;
EXEC Insernombrecapitulo @Nom='Capitulo 36',@Numero = 36;
EXEC Insernombrecapitulo @Nom='Capitulo 37',@Numero = 37;
EXEC Insernombrecapitulo @Nom='Capitulo 38',@Numero = 38;
EXEC Insernombrecapitulo @Nom='Capitulo 39',@Numero = 39;
EXEC Insernombrecapitulo @Nom='Capitulo 40',@Numero = 40;
--genesis 41-50
EXEC Insernombrecapitulo @Nom='Los sue�os del Fara�n',@Numero = 41;
EXEC Insernombrecapitulo @Nom='El primer viaje de los hermanos de Jos� a Egipto',@Numero = 42;
EXEC Insernombrecapitulo @Nom='El segundo viaje de los hermanos de Jos� a Egipto',@Numero = 43;
EXEC Insernombrecapitulo @Nom='La �ltima prueba de Jos� a sus hermanos',@Numero = 44;
EXEC Insernombrecapitulo @Nom='El desenlace de la historia de Jos�',@Numero = 45;
EXEC Insernombrecapitulo @Nom='Jacob y su familia en Egipto',@Numero = 46;
EXEC Insernombrecapitulo @Nom='La entrevista de los hijos de Jacob con el Fara�n',@Numero = 47;
EXEC Insernombrecapitulo @Nom='La bendici�n de Efra�m y Manas�s',@Numero = 48;
EXEC Insernombrecapitulo @Nom='El testamento de Jacob',@Numero = 49;
EXEC Insernombrecapitulo @Nom='Los funerales de Jacob',@Numero = 50;
--isaias 51-60
EXEC Insernombrecapitulo @Nom='Capitulo 51',@Numero = 51;
EXEC Insernombrecapitulo @Nom='Capitulo 52',@Numero = 52;
EXEC Insernombrecapitulo @Nom='Capitulo 53',@Numero = 53;
EXEC Insernombrecapitulo @Nom='Capitulo 54',@Numero = 54;
EXEC Insernombrecapitulo @Nom='Capitulo 55',@Numero = 55;
EXEC Insernombrecapitulo @Nom='Capitulo 56',@Numero = 56;
EXEC Insernombrecapitulo @Nom='Capitulo 57',@Numero = 57;
EXEC Insernombrecapitulo @Nom='Capitulo 58',@Numero = 58;
EXEC Insernombrecapitulo @Nom='Capitulo 59',@Numero = 59;
EXEC Insernombrecapitulo @Nom='Capitulo 60',@Numero = 60;


--VERSICULO

CREATE TABLE Versiculo(
Numero INT PRIMARY KEY,
idCapitulo INT,
cita VARCHAR (80),
Contenido VARCHAR(200),
FOREIGN KEY (idCapitulo) REFERENCES Capitulo(Numero)
);

--view

CREATE VIEW VistaVersiculo AS
SELECT 
    Versiculo.Numero AS NumeroVersiculo,
    Versiculo.cita AS CitaVersiculo,
    Versiculo.Contenido AS ContenidoVersiculo,
    Versiculo.idCapitulo,
    Capitulo.nombre AS NombreCapitulo
FROM 
    Versiculo
INNER JOIN 
    Capitulo ON Versiculo.idCapitulo = Capitulo.Numero;


--Procedure

CREATE PROCEDURE CrearVersiculos
@Contenido VARCHAR(200), @Cita varchar(50)
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @totalVersiculos INT = 180; 
    
    WHILE @i <= @totalVersiculos
    BEGIN
        DECLARE @j INT = @i; 
        DECLARE @idCapitulo INT = (@i - 1) / 3 + 1; 
        
        INSERT INTO Versiculo(Numero, idCapitulo,Contenido,cita) VALUES (@j, @idCapitulo,@Contenido,@cita);
        SET @i = @i + 1;
    END
END;
GO

EXEC CrearVersiculos @Contenido = contenido, @Cita = cita;

-- Insertar Versiculo

CREATE PROCEDURE InsertarVersiculos
       @Numero INT,@Contenido VARCHAR(200), @cita VARCHAR(80)
AS
BEGIN
        UPDATE Versiculo
        SET Contenido  = @Contenido, Cita = @cita
        WHERE Numero = @Numero;
	
END;

EXEC InsertarVersiculos @Numero=1,@Contenido='Este atestigua que todo lo que vio es Palabra de Dios y testimonio de Jesucristo.', @cita='Apocalipsis 1:2'
EXEC InsertarVersiculos @Numero=2,@Contenido='Yo soy el Alfa y la Omega, dice el Se�or Dios, el que es, el que era y el que vendr�, el Todopoderoso.', @cita='Apocalipsis 1:8'
EXEC InsertarVersiculos @Numero=3,@Contenido='Estuve muerto, pero ahora vivo para siempre y tengo la llave de la Muerte y del Abismo.', @cita='Apocalipsis 1:18'
EXEC InsertarVersiculos @Numero=4,@Contenido='S� que tienes constancia y que has sufrido mucho por mi Nombre sin desfallecer.', @cita='Apocalipsis 2:3'
EXEC InsertarVersiculos @Numero=5,@Contenido='Sin embargo, tienes esto a tu favor: que detestas la conducta de los nicola�tas, lo mismo que yo�.', @cita='Apocalipsis 2:6'
EXEC InsertarVersiculos @Numero=6,@Contenido='�Conozco tus obras, tu amor, tu fe, tu servicio y tu constancia. S� tambi�n que tus �ltimas obras son m�s abundantes que las primeras.', @cita='Apocalipsis 2:19'
EXEC InsertarVersiculos @Numero=7,@Contenido='El que pueda entender, que entienda lo que el Esp�ritu dice a las Iglesias.', @cita='Apocalipsis 3:6'
EXEC InsertarVersiculos @Numero=8,@Contenido='El que pueda entender, que entienda lo que el Esp�ritu dice a las Iglesias�.', @cita='Apocalipsis 3:13'
EXEC InsertarVersiculos @Numero=9,@Contenido='Por eso, porque eres tibio, te vomitar� de mi boca.', @cita='Apocalipsis 3:16'
EXEC InsertarVersiculos @Numero=10,@Contenido='En ese mismo momento, fui arrebatado por el Esp�ritu y vi en el cielo un trono, en el cual alguien estaba sentado.', @cita='Apocalipsis 4:2'
EXEC InsertarVersiculos @Numero=11,@Contenido='Del trono sal�an rel�mpagos, voces y truenos, y delante de �l ard�an siete l�mparas de fuego, que son los siete Esp�ritus de Dios.', @cita='Apocalipsis 4:5'
EXEC InsertarVersiculos @Numero=12,@Contenido='los veinticuatro Ancianos se postraban ante �l para adorarlo, y pon�an sus coronas delante del trono, diciendo:', @cita='Apocalipsis 4:10'
EXEC InsertarVersiculos @Numero=13,@Contenido='Y yo me puse a llorar porque nadie era digno de abrir el libro ni de leerlo.', @cita='Apocalipsis 5:4'
EXEC InsertarVersiculos @Numero=14,@Contenido='El Cordero vino y tom� el libro de la mano derecha de aquel que estaba sentado en el trono.', @cita='Apocalipsis 5:7'
EXEC InsertarVersiculos @Numero=15,@Contenido='Los cuatro Seres Vivientes dec�an: ��Am�n!�, y los Ancianos se postraron en actitud de adoraci�n.', @cita='Apocalipsis 5:14'
EXEC InsertarVersiculos @Numero=16,@Contenido='Y vi aparecer un caballo blanco. Su jinete ten�a un arco, recibi� una corona y sali� triunfante, para seguir venciendo.', @cita='Apocalipsis 6:2'
EXEC InsertarVersiculos @Numero=17,@Contenido='Cuando el Cordero abri� el cuarto sello, o� al cuarto de los Seres Vivientes que dec�a: �Ven�.', @cita='Apocalipsis 6:7'
EXEC InsertarVersiculos @Numero=18,@Contenido='los astros del cielo cayeron sobre la tierra, como caen los higos verdes cuando la higuera es sacudida por un fuerte viento.', @cita='Apocalipsis 6:13'
EXEC InsertarVersiculos @Numero=19,@Contenido='O� entonces el n�mero de los que hab�an sido marcados: eran 144.000 pertenecientes a todas las tribus de Israel.', @cita='Apocalipsis 7:4'
EXEC InsertarVersiculos @Numero=20,@Contenido='doce mil de la tribu de Aser, doce mil de la tribu de Neftal�, doce mil de la tribu de Manas�s,', @cita='Apocalipsis 7:6'
EXEC InsertarVersiculos @Numero=21,@Contenido='��La salvaci�n viene de nuestro Dios que est� sentado en el trono, y del Cordero!�.', @cita='Apocalipsis 7:10'
EXEC InsertarVersiculos @Numero=22,@Contenido='Y cuando el Cordero abri� el s�ptimo sello, se produjo en el cielo un silencio, que dur� alrededor de media hora.', @cita='Apocalipsis 8:1'
EXEC InsertarVersiculos @Numero=23,@Contenido='Y los siete Angeles que ten�an las siete trompetas se dispusieron a tocarlas.', @cita='Apocalipsis 8:6'
EXEC InsertarVersiculos @Numero=24,@Contenido='muri� la tercera parte de los seres vivientes que habitan en sus aguas, y fue destruida la tercera parte de las naves.', @cita='Apocalipsis 8:9'
EXEC InsertarVersiculos @Numero=25,@Contenido='Su cabello era como el de las mujeres y sus dientes como dientes de leones.', @cita='Apocalipsis 9:8'
EXEC InsertarVersiculos @Numero=26,@Contenido='La primera calamidad ha pasado, pero sepan que todav�a faltan dos m�s.', @cita='Apocalipsis 9:12'
EXEC InsertarVersiculos @Numero=27,@Contenido='No, ellos no se arrepintieron de sus homicidios, ni de sus maleficios, ni de sus fornicaciones, ni de sus robos', @cita='Apocalipsis 9:21'
EXEC InsertarVersiculos @Numero=28,@Contenido='y en su mano ten�a abierto un libro peque�o. Puso su pie derecho sobre el mar y el izquierdo sobre la tierra,', @cita='Apocalipsis 10:2'
EXEC InsertarVersiculos @Numero=29,@Contenido='Y el Angel que yo hab�a visto de pie sobre el mar y sobre la tierra, levant� su mano derecha hacia el cielo,', @cita='Apocalipsis 10:5'
EXEC InsertarVersiculos @Numero=30,@Contenido='Entonces se me dijo: �Es necesario que profetices nuevamente acerca de una multitud de pueblos, de naciones, de lenguas y de reyes�.', @cita='Apocalipsis 10:11'

EXEC InsertarVersiculos @Numero=31,@Contenido='Hab�a un hombre enfermo, L�zaro de Betania, del pueblo de Mar�a y de su hermana Marta.', @cita='Evangelio segun San Juan 11:1'
EXEC InsertarVersiculos @Numero=32,@Contenido='Jes�s quer�a mucho a Marta, a su hermana y a L�zaro.', @cita='Evangelio segun San Juan 11:5'
EXEC InsertarVersiculos @Numero=33,@Contenido='en cambio, el que camina de noche tropieza, porque la luz no est� en �l�.', @cita='Evangelio segun San Juan 11:10'
EXEC InsertarVersiculos @Numero=34,@Contenido='All� le prepararon una cena: Marta serv�a y L�zaro era uno de los comensales.', @cita='Evangelio segun San Juan 12:2'
EXEC InsertarVersiculos @Numero=35,@Contenido='Jes�s le respondi�: �D�jala. Ella ten�a reservado este perfume para el d�a de mi sepultura.', @cita='Evangelio segun San Juan 12:7'
EXEC InsertarVersiculos @Numero=36,@Contenido='Entonces los sumos sacerdotes resolvieron matar tambi�n a L�zaro,', @cita='Evangelio segun San Juan 12:10'
EXEC InsertarVersiculos @Numero=37,@Contenido='se levant� de la mesa, se sac� el manto y tomando una toalla se la at� a la cintura.', @cita='Evangelio segun San Juan 13:4'
EXEC InsertarVersiculos @Numero=38,@Contenido='Cuando se acerc� a Sim�n Pedro, este le dijo: ��T�, Se�or, me vas a lavar los pies a m�?�.', @cita='Evangelio segun San Juan 13:6'
EXEC InsertarVersiculos @Numero=39,@Contenido='�Entonces, Se�or, le dijo Sim�n Pedro, �no s�lo los pies, sino tambi�n las manos y la cabeza!�', @cita='Evangelio segun San Juan 13:9'
EXEC InsertarVersiculos @Numero=40,@Contenido='�No se inquieten. Crean en Dios y crean tambi�n en m�.', @cita='Evangelio segun San Juan 14:1'
EXEC InsertarVersiculos @Numero=41,@Contenido='Ya conocen el camino del lugar adonde voy�.', @cita='Evangelio segun San Juan 14:4'
EXEC InsertarVersiculos @Numero=42,@Contenido='Jes�s le respondi�: �Yo soy el Camino, la Verdad y la Vida. Nadie va al Padre, sino por m�.', @cita='Evangelio segun San Juan 14:6'
EXEC InsertarVersiculos @Numero=43,@Contenido='Ustedes ya est�n limpios por la palabra que yo les anunci�.', @cita='Evangelio segun San Juan 15:3'
EXEC InsertarVersiculos @Numero=44,@Contenido='La gloria de mi Padre consiste en que ustedes den fruto abundante, y as� sean mis disc�pulos.', @cita='Evangelio segun San Juan 15:8'
EXEC InsertarVersiculos @Numero=45,@Contenido='No hay amor m�s grande que dar la vida por los amigos.', @cita='Evangelio segun San Juan 15:13'
EXEC InsertarVersiculos @Numero=46,@Contenido='Les he dicho esto para que no se escandalicen.', @cita='Evangelio segun San Juan 16:1'
EXEC InsertarVersiculos @Numero=47,@Contenido='Pero al decirles esto, ustedes se han entristecido.', @cita='Evangelio segun San Juan 16:6'
EXEC InsertarVersiculos @Numero=48,@Contenido='La justicia, en que yo me voy al Padre y ustedes ya no me ver�n.', @cita='Evangelio segun San Juan 16:10'
EXEC InsertarVersiculos @Numero=49,@Contenido='Yo te he glorificado en la tierra, llevando a cabo la obra que me encomendaste.', @cita='Evangelio segun San Juan 17:4'
EXEC InsertarVersiculos @Numero=50,@Contenido='Ahora saben que todo lo que me has dado viene de ti,', @cita='Evangelio segun San Juan 17:7'
EXEC InsertarVersiculos @Numero=51,@Contenido='Todo lo m�o es tuyo y todo lo tuyo es m�o, y en ellos he sido glorificado.', @cita='Evangelio segun San Juan 17:10'
EXEC InsertarVersiculos @Numero=52,@Contenido='A Jes�s, el Nazareno. El les dijo: �Soy yo�. Judas el que lo entregaba estaba con ellos.', @cita='Evangelio segun San Juan 18:5'
EXEC InsertarVersiculos @Numero=53,@Contenido='Jes�s repiti�: �Ya les dije que soy yo. Si es a m� a quien buscan, dejan que estos se vayan�.', @cita='Evangelio segun San Juan 18:8'
EXEC InsertarVersiculos @Numero=54,@Contenido=' Jes�s dijo a Sim�n Pedro: �Envaina tu espada. �Acaso no beber� el c�liz que me ha dado el Padre?', @cita='Evangelio segun San Juan 18:11'
EXEC InsertarVersiculos @Numero=55,@Contenido='Pilato mand� entonces azotar a Jes�s.', @cita='Evangelio segun San Juan 19:1'
EXEC InsertarVersiculos @Numero=56,@Contenido='Jes�s sali�, llevando la corona de espinas y el manto rojo. Pilato les dijo: ��Aqu� tienen al hombre!�.', @cita='Evangelio segun San Juan 19:5'
EXEC InsertarVersiculos @Numero=57,@Contenido='Al o�r estas palabras, Pilato se alarm� m�s todav�a.', @cita='Evangelio segun San Juan 19:8'
EXEC InsertarVersiculos @Numero=58,@Contenido='Pedro y el otro disc�pulo salieron y fueron al sepulcro.', @cita='Evangelio segun San Juan 20:3'
EXEC InsertarVersiculos @Numero=59,@Contenido=' Los disc�pulos regresaron entonces a su casa.', @cita='Evangelio segun San Juan 20:10'
EXEC InsertarVersiculos @Numero=60,@Contenido='Al decir esto se dio vuelta y vio a Jes�s, que estaba all�, pero no lo reconoci�.', @cita='Evangelio segun San Juan 20:14'


EXEC InsertarVersiculos @Numero=61,@Contenido='Como encontramos un barco que iba a Fenicia, subimos a bordo y partimos.', @cita='Hechos de los Apostoles 21:2'
EXEC InsertarVersiculos @Numero=62,@Contenido='y habi�ndonos despedido, nosotros subimos al barco y ellos se volvieron a sus casas.', @cita='Hechos de los Apostoles 21:6'
EXEC InsertarVersiculos @Numero=63,@Contenido='El ten�a cuatro hijas solteras que profetizaban.', @cita='Hechos de los Apostoles 21:9'
EXEC InsertarVersiculos @Numero=64,@Contenido='Al o�r que hablaba en hebreo, el silencio se hizo a�n m�s profundo. Pablo prosigui�:', @cita='Hechos de los Apostoles 22:2'
EXEC InsertarVersiculos @Numero=65,@Contenido='Persegu� a muerte a los que segu�an este Camino, llevando encadenados a la prisi�n a hombres y mujeres;', @cita='Hechos de los Apostoles 22:4'
EXEC InsertarVersiculos @Numero=66,@Contenido='Ca� en tierra y o� una voz que me dec�a: �Saulo, Saulo, �por qu� me persigues?�.', @cita='Hechos de los Apostoles 22:7'
EXEC InsertarVersiculos @Numero=67,@Contenido=' Pero el Sumo Sacerdote Anan�as orden� a sus asistentes que le pegaran en la boca', @cita='Hechos de los Apostoles 23:2'
EXEC InsertarVersiculos @Numero=68,@Contenido='Los asistentes le advirtieron: �Est�s insultando al Sumo Sacerdote de Dios�.', @cita='Hechos de los Apostoles 23:4'
EXEC InsertarVersiculos @Numero=69,@Contenido=' Los comprometidos en la conjuraci�n eran m�s de cuarenta.', @cita='Hechos de los Apostoles 23:13'
EXEC InsertarVersiculos @Numero=70,@Contenido='pero intervino el tribuno Lisias, que lo arranc� violentamente de nuestras manos', @cita='Hechos de los Apostoles 24:7'
EXEC InsertarVersiculos @Numero=71,@Contenido='Los jud�os ratificaron esto, asegurando que era verdad.', @cita='Hechos de los Apostoles 24:9'
EXEC InsertarVersiculos @Numero=72,@Contenido='Ellos tampoco pueden probarte aquello de lo que me acusan ahora.', @cita='Hechos de los Apostoles 24:13'
EXEC InsertarVersiculos @Numero=73,@Contenido=' Tres d�as despu�s de haberse hecho cargo de su provincia, Festo subi� de Cesarea a Jerusal�n.', @cita='Hechos de los Apostoles 25:1'
EXEC InsertarVersiculos @Numero=74,@Contenido='�Que los de m�s autoridad entre ustedes, a�adi�, vengan conmigo y presenten su acusaci�n, si tienen algo contra �l�.', @cita='Hechos de los Apostoles 25:5'
EXEC InsertarVersiculos @Numero=75,@Contenido='Festo, despu�s de haber consultado con su Consejo, respondi�: �Ya que apelaste al Emperador, comparecer�s ante �l�.', @cita='Hechos de los Apostoles 25:12'
EXEC InsertarVersiculos @Numero=76,@Contenido='porque t� conoces todas las costumbres y controversias de los jud�os. Por eso te ruego que me escuches con paciencia.', @cita='Hechos de los Apostoles 26:3'
EXEC InsertarVersiculos @Numero=77,@Contenido='�Por qu� les parece incre�ble que Dios resucite a los muertos?', @cita='Hechos de los Apostoles 26:8'
EXEC InsertarVersiculos @Numero=78,@Contenido='Yo respond�: ��Qui�n eres, Se�or?�. Y me dijo: �Soy Jes�s, a quien t� persigues.', @cita='Hechos de los Apostoles 26:15'
EXEC InsertarVersiculos @Numero=79,@Contenido='despu�s, atravesando el mar de Cilicia y de Panfilia, llegamos a Mira de Licia.', @cita='Hechos de los Apostoles 27:5'
EXEC InsertarVersiculos @Numero=80,@Contenido='Los dem�s se animaron y tambi�n comenzaron a comer.', @cita='Hechos de los Apostoles 27:36'
EXEC InsertarVersiculos @Numero=81,@Contenido='Una vez satisfechos, comenzaron a aligerar el barco tirando el trigo al mar.', @cita='Hechos de los Apostoles 27:38'
EXEC InsertarVersiculos @Numero=82,@Contenido='Pero �l tir� la serpiente al fuego y no sufri� ning�n mal.', @cita='Hechos de los Apostoles 28:5'
EXEC InsertarVersiculos @Numero=83,@Contenido='A ra�z de esto, se presentaron los otros enfermos de la isla y fueron curados.', @cita='Hechos de los Apostoles 28:9'
EXEC InsertarVersiculos @Numero=84,@Contenido='Despu�s de interrogarme, quisieron dejarme en libertad, porque no encontraban en m� nada que mereciera la muerte;', @cita='Hechos de los Apostoles 28:18'
EXEC InsertarVersiculos @Numero=85,@Contenido='Apenas pronunci� estas palabras, surgi� una disputa entre fariseos y saduceos, y la asamblea se dividi�.', @cita='Hechos de los Apostoles 29:7'
EXEC InsertarVersiculos @Numero=86,@Contenido='Los que me acompa�aban vieron la luz, pero no oyeron la voz del que me hablaba.', @cita='Hechos de los Apostoles 29:9'
EXEC InsertarVersiculos @Numero=87,@Contenido='Cuando llegamos a Jerusal�n, los hermanos nos recibieron con alegr�a.', @cita='Hechos de los Apostoles 29:17'
EXEC InsertarVersiculos @Numero=88,@Contenido='Pero el centuri�n confiaba m�s en el capital y en el patr�n del barbo que en las palabras de Pablo;', @cita='Hechos de los Apostoles 30:11'
EXEC InsertarVersiculos @Numero=89,@Contenido='Por todo esto, los jud�os me detuvieron en el Templo y trataron de matarme.', @cita='Hechos de los Apostoles 30:21'
EXEC InsertarVersiculos @Numero=90,@Contenido='Porque me parece absurdo enviar a un prisionero, sin indicar al mismo tiempo los cargos que se le imputan�.', @cita='Hechos de los Apostoles 30:27'

EXEC InsertarVersiculos @Numero=91,@Contenido='Los desvelos del rico terminan por consumirlo y el af�n de riquezas hace perder el sue�o.', @cita='Eclesiastico 31:1'
EXEC InsertarVersiculos @Numero=92,@Contenido='El rico se fatiga por amontonar una fortuna, y si descansa, es para hartarse de placeres;', @cita='Eclesiastico 31:3'
EXEC InsertarVersiculos @Numero=93,@Contenido=' Muchos acabaron en la ruina por culpa del oro y se enfrentaron con su propia perdici�n,', @cita='Eclesiastico 31:6'
EXEC InsertarVersiculos @Numero=94,@Contenido='Habla, anciano, porque te corresponde hacerlo, pero con discreci�n y sin interrumpir la m�sica.', @cita='Eclesiastico 32:3'
EXEC InsertarVersiculos @Numero=95,@Contenido='Sello de rub� en una alhaja de oro es un concierto musical mientras se bebe vino;', @cita='Eclesiastico 32:5'
EXEC InsertarVersiculos @Numero=96,@Contenido='Habla, joven, cuando sea necesario, pero dos veces a lo m�s, y si te preguntan.', @cita='Eclesiastico 32:7'
EXEC InsertarVersiculos @Numero=97,@Contenido=' Prepara lo que vas a decir, y as� ser�s escuchado, resume lo que sabes, y luego responde.', @cita='Eclesiastico 33:4'
EXEC InsertarVersiculos @Numero=98,@Contenido='Un amigo burl�n es como un caballo en celo: relincha bajo cualquier jinete', @cita='Eclesiastico 33:6'
EXEC InsertarVersiculos @Numero=99,@Contenido='Un amigo burl�n es como un caballo en celo: relincha bajo cualquier jinete', @cita='Eclesiastico 33:10'
EXEC InsertarVersiculos @Numero=100,@Contenido='A no ser que los env�e el Alt�simo en una visita, no les prestes ninguna atenci�n.', @cita='Eclesiastico 34:6'
EXEC InsertarVersiculos @Numero=101,@Contenido=' El que no ha sido probado sabe pocas cosas, pero el que ha andado mucho adquiere gran habilidad.', @cita='Eclesiastico 34:10'
EXEC InsertarVersiculos @Numero=102,@Contenido='Muchas veces estuve en peligro de muerte, y gracias a todo eso escap� sano y salvo', @cita='Eclesiastico 34:12'
EXEC InsertarVersiculos @Numero=103,@Contenido='El sacrificio del justo es aceptado y su memorial no caer� en el olvido.', @cita='Eclesiastico 35:6'
EXEC InsertarVersiculos @Numero=104,@Contenido='Da siempre con el rostro radiante y consagra el diezmo con alegr�a', @cita='Eclesiastico 35:8'
EXEC InsertarVersiculos @Numero=105,@Contenido='porque el Se�or sabe retribuir y te dar� siete veces m�s', @cita='Eclesiastico 35:10'
EXEC InsertarVersiculos @Numero=106,@Contenido='Levanta tu mano contra las naciones extranjeras y que ellas vean tu dominio.', @cita='Eclesiastico 36:2'
EXEC InsertarVersiculos @Numero=107,@Contenido='Despierta tu furor y derrama tu ira, suprime al adversario y extermina al enemigo.', @cita='Eclesiastico 36:6'
EXEC InsertarVersiculos @Numero=108,@Contenido='Aplasta la cabeza de los jefes enemigos, que dicen: ��No hay nadie fuera de nosotros!�.', @cita='Eclesiastico 36:9'
EXEC InsertarVersiculos @Numero=109,@Contenido='Todo amigo dice: �Tambi�n yo soy tu amigo�, pero hay amigos que lo son s�lo de nombre.', @cita='Eclesiastico 37:1'
EXEC InsertarVersiculos @Numero=110,@Contenido='Nunca te olvides de un buen amigo, y acu�rdate de �l cuando tengas riquezas.', @cita='Eclesiastico 37:6'
EXEC InsertarVersiculos @Numero=111,@Contenido='No consultes al que te subestima, y al que tiene celos de ti, oc�ltale tus designios.', @cita='Eclesiastico 37:10'
EXEC InsertarVersiculos @Numero=112,@Contenido='El Se�or dio a los hombres la ciencia, para ser glorificado por sus maravillas.', @cita='Eclesiastico 38:6'
EXEC InsertarVersiculos @Numero=113,@Contenido='Ofrece el suave aroma y el memorial de harina, presenta una rica ofrenda, como si fuera la �ltima.', @cita='Eclesiastico 38:11'
EXEC InsertarVersiculos @Numero=114,@Contenido='En algunos casos, tu mejor�a est� en sus manos,', @cita='Eclesiastico 38:13'
EXEC InsertarVersiculos @Numero=115,@Contenido='indaga el sentido oculto de los proverbios y estudia sin cesar las sentencias enigm�ticas.', @cita='Eclesiastico 39:3'
EXEC InsertarVersiculos @Numero=116,@Contenido='Las naciones hablar�n de su sabidur�a y la asamblea proclamar� su alabanza.', @cita='Eclesiastico 39:10'
EXEC InsertarVersiculos @Numero=117,@Contenido='Su bendici�n desborda como un r�o y como un diluvio, empapa la tierra.', @cita='Eclesiastico 39:22'
EXEC InsertarVersiculos @Numero=118,@Contenido=' La generosidad es como un vergel exuberante y la limosna permanece para siempre.', @cita='Eclesiastico 40:17'
EXEC InsertarVersiculos @Numero=119,@Contenido='El vino y la m�sica alegran el coraz�n, pero m�s todav�a el amor a la sabidur�a.', @cita='Eclesiastico 40:20'
EXEC InsertarVersiculos @Numero=120,@Contenido='El oro y la plata hacen marchar con paso firme, pero m�s todav�a se aprecia un consejo.', @cita='Eclesiastico 40:25'


EXEC InsertarVersiculos @Numero=121,@Contenido='Dos a�os despu�s, el Fara�n tuvo un sue�o: �l estaba de pie junto al Nilo,', @cita='Genesis 41:1'
EXEC InsertarVersiculos @Numero=122,@Contenido='Luego volvi� a dormirse y tuvo otro sue�o: siete espigas grandes y lozanas sal�an de un mismo tallo.', @cita='Genesis 41:5'
EXEC InsertarVersiculos @Numero=123,@Contenido=' Entonces el copero mayor se dirigi� al Fara�n y le dijo: �Ahora reconozco mi negligencia.', @cita='Genesis 41:9'
EXEC InsertarVersiculos @Numero=124,@Contenido='Entonces, diez de los hermanos de Jos� bajaron a Egipto para abastecerse de cereales;', @cita='Genesis 42:3'
EXEC InsertarVersiculos @Numero=125,@Contenido='Y al reconocer a sus hermanos, sin que ellos lo reconocieran a �l,', @cita='Genesis 42:8'
EXEC InsertarVersiculos @Numero=126,@Contenido='�No, se�or�, le respondieron. �Es verdad que tus servidores han venido a comprar v�veres.', @cita='Genesis 42:10'
EXEC InsertarVersiculos @Numero=127,@Contenido='El hambre continuaba asolando el pa�s.', @cita='Genesis 43:1'
EXEC InsertarVersiculos @Numero=128,@Contenido='Si t� dejas partir a nuestro hermano con nosotros, bajaremos a comprarte comida;', @cita='Genesis 43:4'
EXEC InsertarVersiculos @Numero=129,@Contenido='Entonces Israel dijo: ��Por qu� me han causado este dolor, diciendo a este hombre que ten�an otro hermano?�', @cita='Genesis 43:6'
EXEC InsertarVersiculos @Numero=130,@Contenido='y al d�a siguiente, apenas amaneci�, hicieron salir a los hombres con sus asnos.', @cita='Genesis 44:3'
EXEC InsertarVersiculos @Numero=131,@Contenido='Apenas los alcanz�, el mayordomo les repiti� estas palabras.', @cita='Genesis 44:6'
EXEC InsertarVersiculos @Numero=132,@Contenido=' Entonces ellos se apresuraron a bajar sus bolsas, y cada uno abri� la suya.', @cita='Genesis 44:11'
EXEC InsertarVersiculos @Numero=133,@Contenido=' Y cuando despidi� a sus hermanos antes que partieran, les recomend�: �Vayan tranquilos�.', @cita='Genesis 45:24'
EXEC InsertarVersiculos @Numero=134,@Contenido='Ellos salieron de Egipto y llegaron a la tierra de Cana�n, donde se encontraba su padre Jacob.', @cita='Genesis 45:25'
EXEC InsertarVersiculos @Numero=135,@Contenido=' Israel exclam�: �Ya es suficiente. �Mi hijo Jos� vive todav�a! Tengo que ir a verlo antes de morir�.', @cita='Genesis 45:28'
EXEC InsertarVersiculos @Numero=136,@Contenido='sus hijos y sus nietos, sus hijas y sus nietas� porque �l hab�a llevado consigo a todos sus descendientes.', @cita='Genesis 46:7'
EXEC InsertarVersiculos @Numero=137,@Contenido='Los hijos de Lev�: Gers�n, Quehat y Merar�.', @cita='Genesis 46:11'
EXEC InsertarVersiculos @Numero=138,@Contenido='Los hijos de Isacar: Tol�, Puv�, Iasub y Simr�n.', @cita='Genesis 46:13'
EXEC InsertarVersiculos @Numero=139,@Contenido='Adem�s, �l se hab�a hecho acompa�ar por algunos de sus hermanos y se los present� al Fara�n.', @cita='Genesis 47:2'
EXEC InsertarVersiculos @Numero=140,@Contenido='Jos� hizo venir a su padre Jacob y se lo present� al Fara�n. Jacob salud� respetuosamente al Fara�n,', @cita='Genesis 47:7'
EXEC InsertarVersiculos @Numero=141,@Contenido='Luego Jacob volvi� a saludar al Fara�n y sali� de all�.', @cita='Genesis 47:10'
EXEC InsertarVersiculos @Numero=142,@Contenido=' y dijo a Jos�: �El Dios Todopoderoso se me apareci�, en Luz, en la tierra de Cana�n, y me bendijo,', @cita='Genesis 48:3'
EXEC InsertarVersiculos @Numero=143,@Contenido='Al ver a los hijos de Jos�, Israel pregunt�: �Y estos, �qui�nes son?�.', @cita='Genesis 48:8'
EXEC InsertarVersiculos @Numero=144,@Contenido='Jos� los retir� de las rodillas de Israel y se inclin� profundamente;', @cita='Genesis 48:12'
EXEC InsertarVersiculos @Numero=145,@Contenido='Sime�n y Lev� son hermanos, sus cuchillos son instrumentos de violencia.', @cita='Genesis 49:5'
EXEC InsertarVersiculos @Numero=146,@Contenido='Maldita sea su ira tan violenta y su furor tan feroz. Yo los repartir� en el pa�s de Jacob y los dispersar� en Israel.', @cita='Genesis 49:7'
EXEC InsertarVersiculos @Numero=147,@Contenido='Sus ojos est�n oscurecidos por el vino, y sus dientes blanqueados por la leche.', @cita='Genesis 49:12'
EXEC InsertarVersiculos @Numero=148,@Contenido='Pero Jos� les respondi�: �No tengan miedo. �Acaso yo puedo hacer las veces de Dios?', @cita='Genesis 50:19'
EXEC InsertarVersiculos @Numero=149,@Contenido='Jos� permaneci� en Egipto junto con la familia de su padre, y vivi� ciento diez a�os.', @cita='Genesis 50:22'
EXEC InsertarVersiculos @Numero=150,@Contenido='Jos� muri� a la edad de ciento diez a�os. Fue embalsamado y colocado en un sarc�fago, en Egipto.', @cita='Genesis 50:26'


EXEC InsertarVersiculos @Numero=151,@Contenido='Porque yo soy el Se�or, tu Dios, que agito el mar, y rugen las olas: mi nombre es Se�or de los ej�rcitos.', @cita='Isaias 51:15'
EXEC InsertarVersiculos @Numero=152,@Contenido='Te han sucedido dos males: �qui�n te consolar�?', @cita='Isaias 51:19'
EXEC InsertarVersiculos @Numero=153,@Contenido='Por eso, �escucha esto, pobre desdichada, ebria, pero no de vino!', @cita='Isaias 51:21'
EXEC InsertarVersiculos @Numero=154,@Contenido='�Sac�dete el polvo, lev�ntate, Jerusal�n cautiva! �Desata las ataduras de tu cuello, hija de Si�n cautiva!', @cita='Isaias 52:2'
EXEC InsertarVersiculos @Numero=155,@Contenido='Porque as� habla el Se�or: Ustedes fueron vendidos por nada, y tambi�n sin dinero ser�n redimidos.', @cita='Isaias 52:3'
EXEC InsertarVersiculos @Numero=156,@Contenido='Por eso mi Pueblo conocer� mi Nombre en ese d�a, porque yo soy aquel que dice: ��Aqu� estoy!�.', @cita='Isaias 52:6'
EXEC InsertarVersiculos @Numero=157,@Contenido='�Qui�n crey� lo que nosotros hemos o�do y a qui�n se le revel� el brazo del Se�or?', @cita='Isaias 53:1'
EXEC InsertarVersiculos @Numero=158,@Contenido='Pero �l soportaba nuestros sufrimientos y cargaba con nuestras dolencias, y nosotros lo consider�bamos golpeado, herido por Dios y humillado.', @cita='Isaias 53:4'
EXEC InsertarVersiculos @Numero=159,@Contenido='Todos and�bamos errantes como ovejas, siguiendo cada uno su propio camino, y el Se�or hizo recaer sobre �l las iniquidades de todos nosotros.', @cita='Isaias 53:6'
EXEC InsertarVersiculos @Numero=160,@Contenido='�Ensancha el espacio de tu carpa, despliega tus lonas sin mezquinar, alarga tus cuerdas, afirma tus estacas!', @cita='Isaias 54:2'
EXEC InsertarVersiculos @Numero=161,@Contenido='Por un breve instante te dej� abandonada, pero con gran ternura te unir� conmigo;', @cita='Isaias 54:7'
EXEC InsertarVersiculos @Numero=162,@Contenido='har� tus almenas de rub�es, tus puertas de cristal y todo tu contorno de piedras preciosas.', @cita='Isaias 54:12'
EXEC InsertarVersiculos @Numero=163,@Contenido='Yo lo he puesto como testigo para los pueblos, jefe y soberano de naciones', @cita='Isaias 55:4'
EXEC InsertarVersiculos @Numero=164,@Contenido='�Busquen al Se�or mientras se deja encontrar, ll�menlo mientras est� cerca!', @cita='Isaias 55:6'
EXEC InsertarVersiculos @Numero=165,@Contenido='Porque los pensamientos de ustedes no son los m�os, ni los caminos de ustedes son mis caminos �or�culo del Se�or�.', @cita='Isaias 55:8'
EXEC InsertarVersiculos @Numero=166,@Contenido='Porque as� habla el Se�or: A los eunucos que observen mis s�bados, que elijan lo que a m� me agrada y se mantengan firmes en mi alianza,', @cita='Isaias 56:4'
EXEC InsertarVersiculos @Numero=167,@Contenido='Or�culo del Se�or, que re�ne a los desterrados de Israel: Todav�a reunir� a otros junto a �l, adem�s de los que ya se han reunido.', @cita='Isaias 56:8'
EXEC InsertarVersiculos @Numero=168,@Contenido='�Bestias del campo, fieras de la selva, vengan todas a devorar!', @cita='Isaias 56:9'
EXEC InsertarVersiculos @Numero=169,@Contenido='Pero llegar� la paz: los que van por el camino recto descansar�n en sus lechos.', @cita='Isaias 57:2'
EXEC InsertarVersiculos @Numero=170,@Contenido=' �Y ustedes, ac�rquense aqu�, hijos de una hechicera, raza de un ad�ltero y una prostituta!', @cita='Isaias 57:3'
EXEC InsertarVersiculos @Numero=171,@Contenido='�De qui�n se burlan? �Contra qui�n abren la boca y sacan la lengua? �No son ustedes hijos de la rebeld�a, una raza bastarda?', @cita='Isaias 57:4'
EXEC InsertarVersiculos @Numero=172,@Contenido=' �Grita a voz en cuello, no te contengas, alza tu voz como una trompeta: den�nciale a mi pueblo su rebeld�a y sus pecados a la casa de Jacob!', @cita='Isaias 58:1'
EXEC InsertarVersiculos @Numero=173,@Contenido='Ayunan para entregarse a pleitos y querellas y para golpear perversamente con el pu�o. No ayunen como en esos d�as, si quieren hacer o�r su voz en las alturas,', @cita='Isaias 58:4'
EXEC InsertarVersiculos @Numero=174,@Contenido='compartir tu pan con el hambriento y albergar a los pobres sin techo; cubrir al que veas desnudo y no despreocuparte de tu propia carne.', @cita='Isaias 58:7'
EXEC InsertarVersiculos @Numero=175,@Contenido='Ellos incuban huevos de v�boras y tejen telas de ara�a; el que come de esos huevos, muere, y se los rompe, alta una culebra.', @cita='Isaias 59:5'
EXEC InsertarVersiculos @Numero=176,@Contenido=' sus pies corren hacia el mal, se apresuran para derramar sangre inocente; sus planes son planes perversos, a su paso hay devastaci�n y ruina.', @cita='Isaias 59:7'
EXEC InsertarVersiculos @Numero=177,@Contenido=' Conforme a las obras, ser� la retribuci�n: furor para sus adversarios, represalia para sus enemigos.', @cita='Isaias 59:18'
EXEC InsertarVersiculos @Numero=178,@Contenido='�Lev�ntate, resplandece, porque llega tu luz y la gloria del Se�or brilla sobre ti!', @cita='Isaias 60:1'
EXEC InsertarVersiculos @Numero=179,@Contenido='Las naciones caminar�n a tu luz y los reyes, al esplendor de tu aurora.', @cita='Isaias 60:3'
EXEC InsertarVersiculos @Numero=180,@Contenido=' �Qui�nes son esos que vuelan como una nube, como palomas a su palomar?', @cita='Isaias 60:8'


CREATE PROCEDURE BuscarVersiculo
    @PalabraClave VARCHAR(200)
AS
BEGIN
    SELECT 
        v.Numero AS NumeroVersiculo,
        v.cita AS CitaVersiculo,
        v.Contenido AS ContenidoVersiculo,
        v.idCapitulo,
        c.nombre AS NombreCapitulo
    FROM 
        Versiculo v
    INNER JOIN 
        Capitulo c ON v.idCapitulo = c.Numero
    WHERE 
        v.Contenido LIKE '%' + @PalabraClave + '%';
END;


-- Triggers

-- 1)

CREATE TRIGGER trg_GuardarHistorial
ON Historial
AFTER INSERT
AS
BEGIN
    UPDATE Historial
    SET Fecha = GETDATE()
    WHERE id IN (SELECT id FROM inserted);
END;  

DROP TRIGGER trg_GuardarHistorial
--HISTORIAL


CREATE TABLE Historial(
id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
idUsuario INT, 
palabra VARCHAR(200),
FOREIGN KEY (idUsuario) REFERENCES Usuario(id),
Fecha DATETIME
);

SELECT *FROM Historial

CREATE PROCEDURE RegistrarHistorial
    @idUsuario INT,@palabra VARCHAR(200)
AS
BEGIN
   
        
        INSERT INTO Historial (idUsuario, palabra)
        VALUES (@idUsuario,@palabra);

    END;


CREATE VIEW VistaHistorial AS
SELECT 
    h.id AS ID,
    u.Nombre AS NombreUsuario,
    h.palabra AS PalabraBuscada,
    h.Fecha AS FechaBusqueda
FROM 
    Historial h
INNER JOIN 
    Usuario u ON h.idUsuario = u.id;



CREATE PROCEDURE OrdenarHistorial
AS
BEGIN

SELECT 
    
    palabra,
    Fecha
FROM 
    Historial
ORDER BY 
    Fecha DESC;
END


CREATE PROCEDURE OrdenarHistorialMes
AS
BEGIN
    SELECT 
        palabra,
        Fecha,
        DATEPART(YEAR, Fecha) AS An,
        DATEPART(MONTH, Fecha) AS Mes
    FROM 
        Historial
    ORDER BY 
        DATEPART(YEAR, Fecha), 
        DATEPART(MONTH, Fecha);
END;


CREATE PROCEDURE OrdenarHistorialAn
AS
BEGIN
    SELECT 
        palabra,
        Fecha,
        DATEPART(YEAR, Fecha) AS An
    FROM 
        Historial
    ORDER BY 
        DATEPART(YEAR, Fecha);
END;



CREATE PROCEDURE EliminarHistorial
    @palabra VARCHAR(100)
AS
BEGIN
    -- Verificar si existen registros con la palabra proporcionada antes de intentar eliminarlos
    IF EXISTS (SELECT 1 FROM Historial WHERE palabra = @palabra)
    BEGIN
        DELETE FROM Historial
        WHERE palabra = @palabra;

    END
    ELSE
    BEGIN
	RAISERROR ('No existen registros con la palabra especificada.', 16, 1);
       
    END
END;



--FAVORITOS


CREATE TABLE Favorito(
id INT  PRIMARY KEY IDENTITY(1,1) NOT NULL,
idUsuario INT,
Nombre VARCHAR(100),
Pasaje VARCHAR(120),
FOREIGN KEY (idUsuario) REFERENCES Usuario(id)
);



CREATE PROCEDURE InsertarFavorito
    @idUsuario INT,
    @Nombre VARCHAR(100),
    @Pasaje VARCHAR(120)
AS
BEGIN
   
        -- Insertar el nuevo favorito
        INSERT INTO Favorito (idUsuario, Nombre, Pasaje)
        VALUES (@idUsuario, @Nombre, @Pasaje);
   
END;



CREATE VIEW VistaFavoritos
AS
SELECT Nombre, Pasaje
FROM Favorito;



CREATE PROCEDURE EliminarFavoritos
    @Pasaje VARCHAR(120)
AS
BEGIN
    
        DELETE FROM Favorito
        WHERE Pasaje = @Pasaje;
        
        
END;



CREATE PROCEDURE EditarNombreFavorito
    @Pasaje VARCHAR(120),
    @NuevoNombre VARCHAR(100)
AS
BEGIN
 
        UPDATE Favorito
        SET Nombre = @NuevoNombre
        WHERE Pasaje = @Pasaje;
        
    
END;




CREATE PROCEDURE ObtenerFavoritos
AS
BEGIN
    -- Seleccionar todos los favoritos ordenados por nombre en orden alfab�tico
    SELECT Nombre, Pasaje
    FROM Favorito
    ORDER BY Nombre ASC;
END;