CREATE DATABASE IF NOT EXISTS sistema_reservas;

USE sistema_reservas;

CREATE TABLE usuarios (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    correo VARCHAR(255) NOT NULL UNIQUE,
    saldo DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE anfitriones (
    id_anfitrion INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE paises (
    id_pais INT PRIMARY KEY AUTO_INCREMENT,
    codigo_pais VARCHAR(10) NOT NULL UNIQUE,
    nombre VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE ciudades (
    id_ciudad INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(255) NOT NULL,
    id_pais INT NOT NULL,
    UNIQUE (nombre, id_pais),
    FOREIGN KEY (id_pais) REFERENCES paises(id_pais)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE lugares (
    id_lugar INT PRIMARY KEY AUTO_INCREMENT,
    id_anfitrion INT NOT NULL,
    direccion VARCHAR(255) NOT NULL,
    id_ciudad INT NOT NULL,
    FOREIGN KEY (id_anfitrion) REFERENCES anfitriones(id_anfitrion)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (id_ciudad) REFERENCES ciudades(id_ciudad)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE reservas (
    id_reserva INT PRIMARY KEY AUTO_INCREMENT,
    id_usuario INT NOT NULL,
    id_lugar INT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CHECK (fecha_inicio < fecha_fin),
    precio_por_noche DECIMAL(10, 2) NOT NULL,
    numero_noches INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (id_lugar) REFERENCES lugares(id_lugar)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE resenas (
    id_resena INT PRIMARY KEY AUTO_INCREMENT,
    id_reserva INT NOT NULL,
    calificacion TINYINT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario TEXT,
    FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- Procedimiento almacenado para realizar una reserva.
DELIMITER $$
CREATE PROCEDURE realizar_reserva(
    IN p_id_usuario INT, 
    IN p_id_lugar INT, 
    IN p_fecha_inicio DATE, 
    IN p_fecha_fin DATE, 
    IN p_precio_por_noche DECIMAL(10, 2), 
    IN p_numero_noches INT
)
BEGIN
    DECLARE v_count INT;

    -- Verificar si el usuario ya tiene una reserva activa en el mismo lugar
    SELECT COUNT(*) INTO v_count
    FROM reservas
    WHERE id_usuario = p_id_usuario
      AND id_lugar = p_id_lugar
      AND fecha_inicio <= p_fecha_fin
      AND fecha_fin >= p_fecha_inicio;

    -- Si el usuario ya tiene una reserva, lanzar un error
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario ya tiene una reserva activa para este lugar en esas fechas.';
    END IF;

    -- Realizar la reserva
    INSERT INTO reservas (id_usuario, id_lugar, fecha_inicio, fecha_fin, precio_por_noche, numero_noches)
    VALUES (p_id_usuario, p_id_lugar, p_fecha_inicio, p_fecha_fin, p_precio_por_noche, p_numero_noches);

    COMMIT;
END $$
DELIMITER ;


-- Caso correcto: Reserva exitosa
CALL realizar_reserva(3, 2, '2024-12-15', '2024-12-18', 100.00, 3);

-- Caso fallido: El usuario ya tiene una reserva activa en el mismo lugar
CALL realizar_reserva(3, 2, '2024-12-16', '2024-12-20', 100.00, 4);




-- Esta vista permite ver todas las reservas activas junto con información del usuario, el lugar, y las fechas de la reserva.
CREATE VIEW vista_reservas_activas AS
SELECT 
    r.id_reserva,
    u.correo AS usuario_correo,
    l.direccion AS lugar_direccion,
    r.fecha_inicio,
    r.fecha_fin,
    r.precio_por_noche,
    r.numero_noches,
    (r.precio_por_noche * r.numero_noches) AS precio_total
FROM reservas r
JOIN usuarios u ON r.id_usuario = u.id_usuario
JOIN lugares l ON r.id_lugar = l.id_lugar
WHERE r.fecha_inicio <= CURDATE() AND r.fecha_fin >= CURDATE();


-- Consultar reservas activas
SELECT * FROM vista_reservas_activas;





-- Creamos una tabla temporal para almacenar las reservas de un usuario específico y hacer una auditoría de las mismas.
CREATE TEMPORARY TABLE IF NOT EXISTS reservas_usuario_temp AS
SELECT 
    r.id_reserva,
    u.correo AS usuario_correo,
    l.direccion AS lugar_direccion,
    r.fecha_inicio,
    r.fecha_fin,
    r.precio_por_noche,
    r.numero_noches,
    (r.precio_por_noche * r.numero_noches) AS precio_total
FROM reservas r
JOIN usuarios u ON r.id_usuario = u.id_usuario
JOIN lugares l ON r.id_lugar = l.id_lugar
WHERE r.id_usuario = 3;  -- Por ejemplo, para el usuario con id_usuario = 3


SELECT * FROM reservas_usuario_temp;




-- Este trigger asegura que no se pueda realizar una reserva si el usuario 
-- no tiene un saldo suficiente para cubrir el costo total de la reserva. 
DELIMITER $$
CREATE TRIGGER verificar_saldo BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
    DECLARE v_saldo_usuario DECIMAL(10, 2);

    -- Obtener el saldo del usuario
    SELECT saldo INTO v_saldo_usuario
    FROM usuarios
    WHERE id_usuario = NEW.id_usuario;

    -- Verificar si el saldo es suficiente
    IF v_saldo_usuario < (NEW.precio_por_noche * NEW.numero_noches) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario no tiene saldo suficiente para realizar la reserva.';
    END IF;
END $$
DELIMITER ;


-- Configurar el saldo de los usuarios para las pruebas
UPDATE usuarios SET saldo = 500.00 WHERE id_usuario = 3;
UPDATE usuarios SET saldo = 50.00 WHERE id_usuario = 4;

-- Caso correcto: Reserva exitosa (saldo suficiente)
INSERT INTO reservas (id_usuario, id_lugar, fecha_inicio, fecha_fin, precio_por_noche, numero_noches)
VALUES (3, 1, '2024-12-20', '2024-12-22', 100.00, 2);

-- Caso fallido: Reserva fallida (saldo insuficiente)
INSERT INTO reservas (id_usuario, id_lugar, fecha_inicio, fecha_fin, precio_por_noche, numero_noches)
VALUES (4, 2, '2024-12-20', '2024-12-22', 100.00, 2);




-- Función para calcular el precio total de una reserva, con descuento si son más de 7 noches.
DELIMITER $$
CREATE FUNCTION calcular_precio_total(
    p_precio_por_noche DECIMAL(10, 2), 
    p_numero_noches INT
) 
RETURNS DECIMAL(10, 2)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_descuento DECIMAL(10, 2);
    
    -- Aplicar un descuento del 10% si la reserva es de más de 7 noches
    IF p_numero_noches > 7 THEN
        SET v_descuento = 0.1;
    ELSE
        SET v_descuento = 0;
    END IF;

    -- Calcular el precio total con descuento
    RETURN (p_precio_por_noche * p_numero_noches) * (1 - v_descuento);
END $$
DELIMITER ;


-- Caso correcto: Calcular precios totales
SELECT calcular_precio_total(100.00, 5) AS precio_corto;  -- Sin descuento
SELECT calcular_precio_total(100.00, 10) AS precio_largo; -- Con descuento

-- Caso fallido: Validar descuento en duraciones menores a 7 noches
SELECT calcular_precio_total(100.00, 6) AS precio_error;  -- No aplica descuento

