USE sistema_reservas;

# 1. Obtener todos los usuarios, su correo y saldo
SELECT id_usuario, correo, saldo FROM usuarios;

# 2. Obtener todos los lugares disponibles con su dirección, ciudad, anfitrión y el saldo del usuario (anfitrión)
SELECT l.id_lugar, l.direccion, c.nombre AS ciudad, a.id_anfitrion, u.saldo
FROM lugares l
JOIN ciudades c ON l.id_ciudad = c.id_ciudad
JOIN anfitriones a ON l.id_anfitrion = a.id_anfitrion
JOIN usuarios u ON a.id_usuario = u.id_usuario;

# 3. Obtener todas las reservas con precio total (precio por noche * número de noches) y el saldo del usuario
SELECT r.id_reserva, r.fecha_inicio, r.fecha_fin, r.precio_por_noche, r.numero_noches, 
       (r.precio_por_noche * r.numero_noches) AS precio_total, u.saldo
FROM reservas r
JOIN usuarios u ON r.id_usuario = u.id_usuario;

# 4. Obtener las reservas de un usuario específico (ID 3) con el saldo del usuario
SELECT r.id_reserva, l.direccion, r.fecha_inicio, r.fecha_fin, r.precio_por_noche, u.saldo
FROM reservas r
JOIN lugares l ON r.id_lugar = l.id_lugar
JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE r.id_usuario = 3;

# 5. Obtener las reseñas de un lugar específico (ID 1) con el saldo del usuario que hizo la reserva
SELECT re.calificacion, re.comentario, u.saldo
FROM resenas re
JOIN reservas r ON re.id_reserva = r.id_reserva
JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE r.id_lugar = 1;

# 6. Obtener los lugares que tienen reseñas con una calificación de 5, junto con el saldo de los usuarios que hicieron las reservas
SELECT DISTINCT l.direccion, c.nombre AS ciudad, u.saldo
FROM lugares l
JOIN reservas r ON l.id_lugar = r.id_lugar
JOIN resenas re ON r.id_reserva = re.id_reserva
JOIN ciudades c ON l.id_ciudad = c.id_ciudad
JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE re.calificacion = 5;

# 7. Obtener los anfitriones con la cantidad de lugares registrados y el saldo de los usuarios anfitriones
SELECT a.id_anfitrion, COUNT(l.id_lugar) AS cantidad_lugares, u.saldo
FROM anfitriones a
JOIN lugares l ON a.id_anfitrion = l.id_anfitrion
JOIN usuarios u ON a.id_usuario = u.id_usuario
GROUP BY a.id_anfitrion;

# 8. Obtener todos los lugares de una ciudad específica (por ejemplo, "Nueva York") y el saldo de los usuarios anfitriones
SELECT l.direccion, u.saldo
FROM lugares l
JOIN ciudades c ON l.id_ciudad = c.id_ciudad
JOIN anfitriones a ON l.id_anfitrion = a.id_anfitrion
JOIN usuarios u ON a.id_usuario = u.id_usuario
WHERE c.nombre = 'Nueva York';

# 9. Obtener los lugares con las reservas más recientes, ordenados por fecha de inicio, con el saldo de los usuarios
SELECT l.direccion, r.fecha_inicio, u.saldo
FROM lugares l
JOIN reservas r ON l.id_lugar = r.id_lugar
JOIN usuarios u ON r.id_usuario = u.id_usuario
ORDER BY r.fecha_inicio DESC;

# 10. Obtener los anfitriones que tienen reservas este mes (diciembre 2024) con el saldo de los usuarios
SELECT DISTINCT a.id_anfitrion, a.id_usuario, u.saldo
FROM anfitriones a
JOIN lugares l ON a.id_anfitrion = l.id_anfitrion
JOIN reservas r ON l.id_lugar = r.id_lugar
JOIN usuarios u ON a.id_usuario = u.id_usuario
WHERE r.fecha_inicio BETWEEN '2024-12-01' AND '2024-12-31';

# 11. Obtener el lugar con el precio promedio más alto por noche, con el saldo de los usuarios
SELECT l.direccion, AVG(r.precio_por_noche) AS precio_promedio, 
       (SELECT u.saldo FROM usuarios u 
        JOIN reservas r2 ON r2.id_usuario = u.id_usuario 
        WHERE r2.id_lugar = l.id_lugar 
        LIMIT 1) AS saldo
FROM lugares l
JOIN reservas r ON l.id_lugar = r.id_lugar
GROUP BY l.id_lugar
ORDER BY precio_promedio DESC
LIMIT 1;

# 12. Obtener los usuarios que han hecho más de 1 reserva, junto con su saldo
SELECT u.id_usuario, COUNT(r.id_reserva) AS cantidad_reservas, u.saldo
FROM usuarios u
JOIN reservas r ON u.id_usuario = r.id_usuario
GROUP BY u.id_usuario
HAVING cantidad_reservas > 1;

# 13. Obtener los lugares con disponibilidad para una fecha específica (ejemplo: '2024-12-10') y el saldo de los usuarios
SELECT l.direccion, u.saldo
FROM lugares l
JOIN usuarios u ON l.id_anfitrion = u.id_usuario
WHERE l.id_lugar NOT IN (
    SELECT r.id_lugar
    FROM reservas r
    WHERE r.fecha_inicio <= '2024-12-10' AND r.fecha_fin >= '2024-12-10'
);

# 14. Obtener los usuarios con las reservas más caras en cuanto a precio total, junto con el saldo del usuario
SELECT r.id_usuario, r.id_reserva, 
       (r.precio_por_noche * r.numero_noches) AS precio_total, u.saldo
FROM reservas r
JOIN usuarios u ON r.id_usuario = u.id_usuario
WHERE (r.precio_por_noche * r.numero_noches) IN (
    SELECT MAX(precio_por_noche * numero_noches) 
    FROM reservas
)
ORDER BY precio_total DESC;

# 15. Obtener el lugar con el mayor número de reseñas, junto con el saldo de los usuarios que han reservado ese lugar
SELECT l.direccion, COUNT(re.id_resena) AS cantidad_resenas, 
       (SELECT u.saldo FROM usuarios u 
        JOIN reservas r2 ON r2.id_usuario = u.id_usuario 
        WHERE r2.id_lugar = l.id_lugar 
        LIMIT 1) AS saldo
FROM lugares l
JOIN reservas r ON l.id_lugar = r.id_lugar
JOIN resenas re ON r.id_reserva = re.id_reserva
GROUP BY l.id_lugar
HAVING cantidad_resenas = (
    SELECT MAX(cantidad_resenas)
    FROM (
        SELECT COUNT(re.id_resena) AS cantidad_resenas
        FROM lugares l
        JOIN reservas r ON l.id_lugar = r.id_lugar
        JOIN resenas re ON r.id_reserva = re.id_reserva
        GROUP BY l.id_lugar
    ) AS subconsulta
)
ORDER BY cantidad_resenas DESC
LIMIT 1;
