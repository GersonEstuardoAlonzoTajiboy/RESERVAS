USE sistema_reservas;

INSERT INTO usuarios (correo, saldo) VALUES 
('usuario1@correo.com', 1000.00),
('usuario2@correo.com', 2000.00),
('usuario3@correo.com', 3000.00),
('usuario4@correo.com', 4000.00);

INSERT INTO anfitriones (id_usuario) VALUES 
(1), 
(2);

INSERT INTO paises (codigo_pais, nombre) VALUES 
('US', 'Estados Unidos'),
('MX', 'México'),
('ES', 'España'),
('FR', 'Francia');

INSERT INTO ciudades (nombre, id_pais) VALUES 
('Nueva York', 1), 
('Los Ángeles', 1),
('Ciudad de México', 2),
('Guadalajara', 2),
('Madrid', 3),
('Barcelona', 3),
('París', 4),
('Lyon', 4);

INSERT INTO lugares (id_anfitrion, direccion, id_ciudad) VALUES 
(1, '123 Main St', 1), 
(1, '456 Broadway', 2), 
(2, 'Av. Reforma 100', 3), 
(2, 'Av. Chapultepec 200', 4);

INSERT INTO reservas (id_usuario, id_lugar, fecha_inicio, fecha_fin, precio_por_noche, numero_noches) VALUES 
(3, 1, '2024-12-01', '2024-12-05', 150.00, 4),
(3, 2, '2024-12-10', '2024-12-12', 200.00, 2),
(4, 3, '2024-12-15', '2024-12-18', 100.00, 3),
(4, 4, '2024-12-20', '2024-12-25', 80.00, 5);

INSERT INTO resenas (id_reserva, calificacion, comentario) VALUES 
(1, 5, '¡Excelente lugar! Muy recomendado.'),
(2, 4, 'Muy bueno, aunque algo caro.'),
(3, 3, 'Aceptable, pero podría mejorar.'),
(4, 5, 'Increíble experiencia, volvería sin dudar.');
