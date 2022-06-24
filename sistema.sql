-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 24-06-2022 a las 15:26:13
-- Versión del servidor: 10.4.24-MariaDB
-- Versión de PHP: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `sistema`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `aa` ()   BEGIN
/*-------Variables para la fecha para abrir el pedido--------*/
DECLARE fecha_solicitud INT;
DECLARE fecha_abrir_solicitud DATE;
/*-------Obtener la fecha para abrir el pedido-------*/
SELECT id,open_request INTO fecha_solicitud, fecha_abrir_solicitud FROM order_dates r WHERE r.state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
IF(fecha_abrir_solicitud <= NOW()) THEN
BEGIN
/*--------variables para detener el ciclo-----------*/
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final  INT DEFAULT 0;
/*-------------------------------------------------*/
/*---------variables para almacenar variables del componente----------*/
DECLARE pedido INT;  #order_request_id
DECLARE implemento INT;
DECLARE componente INT;
DECLARE responsable INT;
DECLARE item INT;
DECLARE tiempo_vida DECIMAL(8,2);
DECLARE horas DECIMAL(8,2);
DECLARE cantidad DECIMAL(8,2);
DECLARE precio_estimado DECIMAL(8,2);
/*------------------------------------------------------------------------*/
/*--------------variables para la pieza------------------------------------*/
DECLARE pieza INT;
DECLARE item_pieza INT;
DECLARE horas_pieza DECIMAL(8,2);
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza DECIMAL(8,2);
DECLARE precio_estimado_pieza DECIMAL(8,2);
/*------------------------------------------------------------------------------*/
/*---------Declarando cursores para iterar por cada componente y pieza-----------*/
DECLARE cur_comp CURSOR FOR SELECT i.id, c.id, c.item_id, c.lifespan, i.user_id, it.estimated_price FROM component_implement_model cim INNER JOIN implements i ON i.implement_model_id = cim.implement_model_id INNER JOIN components c ON c.id = cim.component_id INNER JOIN items it ON it.id = c.item_id;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
/*-----------------------------------------------------------------------------------*/
OPEN cur_comp;
	bucle:LOOP
    IF componente_final = 1 THEN
    	LEAVE bucle;
    END IF;
    FETCH cur_comp INTO implemento,componente,item,tiempo_vida,responsable,precio_estimado;
    /*--------------Obtener horas del componente-----------------------------------*/
    IF EXISTS(SELECT * FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE") THEN
    	SELECT hours INTO horas FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE" LIMIT 1;
    ELSE
    	SELECT 0 INTO horas;
    END IF;
    /*-----------------------------------------------------------*/
    /*-------Calcular la cantidad del pedido-------------------*/
    SELECT ROUND((336+horas)/tiempo_vida) INTO cantidad;
    /*-----------Verificar si se requiere el componente----------*/
    IF(cantidad > 0) THEN
    /*------------Verificar si existe la cabecera de la solicitud------*/
    	IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE") THEN
        	INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
        END IF;
    /*-----------Obteniendo la cabecera de la solicitud-------------------------*/
        SELECT id INTO pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" LIMIT 1;
    /*------Creando la solicitud del componente--------*/
    	INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (pedido,item,cantidad,precio_estimado);
    END IF;
    BEGIN
    /*-------Declarando cursor para piezas---------------------*/
    	DECLARE cur_part CURSOR FOR SELECT cpm.part,c.lifespan,c.item_id,it.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items it ON it.id = c.item_id WHERE cpm.component = componente;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
    /*--------------------------------------------------*/
    	OPEN cur_part;
        	bucle2:LOOP
            IF pieza_final = 1 THEN
            	LEAVE bucle2;
            END IF;
            FETCH cur_part INTO pieza,tiempo_vida_pieza,item_pieza,precio_estimado_pieza;
            /*--------------Obtener horas de la pieza-------------------------------*/
            IF EXISTS(SELECT * FROM component_part cp INNER JOIN component_implement ci ON ci.id = cp.component_implement_id WHERE ci.component_id = componente AND cp.part = pieza AND cp.state = "PENDIENTE") THEN
    			SELECT cp.hours INTO horas_pieza FROM component_part cp INNER JOIN component_implement ci ON ci.id = cp.component_implement_id WHERE ci.component_id = componente AND cp.part = pieza AND cp.state = "PENDIENTE" LIMIT 1;
    		ELSE
    			SELECT 0 INTO horas_pieza;
    		END IF;
            /*------------------------------------------------------------*/
            /*-------------Calcular la cantidad del pedido---------------------*/
            SELECT ROUND((336+horas_pieza)/tiempo_vida_pieza) INTO cantidad_pieza;
            /*----------Verificar si se requiere la pieza----------------------------*/
            IF(cantidad_pieza > 0) THEN
            /*----------Verificar si existe la cabecera de la solicitud-------------------------------*/
            IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE") THEN
        		INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
        	END IF;
            /*-------------Obteniendo la cabecera de la solicitud--------------------------------------------------*/
            SELECT id INTO pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" LIMIT 1;
            /*-------------Creando la solicitud de la pieza---------------------------------------------*/
            IF EXISTS(SELECT * FROM order_request_details r WHERE r.order_request_id = pedido AND r.item_id = item_pieza) THEN
            	UPDATE order_request_details r SET r.quantity = r.quantity + cantidad_pieza, r.estimated_price = r.estimated_price + precio_estimado_pieza WHERE r.order_request_id = pedido AND r.item_id = item_pieza;
            ELSE
            	INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (pedido,item_pieza,cantidad_pieza,precio_estimado_pieza);
            END IF;

            END IF;
            END LOOP bucle2;
            SELECT 0 INTO pieza_final;
        CLOSE cur_part;
    /*----------------------*/
    END;
    END LOOP bucle;
CLOSE cur_comp;
UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
END;
END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `affected_movement`
--

CREATE TABLE `affected_movement` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `operator_stock_id` bigint(20) UNSIGNED DEFAULT NULL,
  `operator_stock_detail_id` bigint(20) UNSIGNED DEFAULT NULL,
  `operator_assigned_stock_id` bigint(20) UNSIGNED DEFAULT NULL,
  `stock_id` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `brands`
--

CREATE TABLE `brands` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `brand` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `brands`
--

INSERT INTO `brands` (`id`, `brand`, `created_at`, `updated_at`) VALUES
(1, 'similique', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(2, 'fugit', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(3, 'repellat', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(4, 'et', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(5, 'eum', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(6, 'voluptatem', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(7, 'odio', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(8, 'saepe', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(9, 'eaque', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(10, 'iusto', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(11, 'omnis', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(12, 'ipsum', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(13, 'aut', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(14, 'voluptas', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(15, 'quo', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(16, 'sequi', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(17, 'repudiandae', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(18, 'molestiae', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(19, 'eos', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(20, 'deleniti', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(21, 'veritatis', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(22, 'ut', '2022-06-20 21:21:42', '2022-06-20 21:21:42'),
(23, 'ratione', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(24, 'atque', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(25, 'enim', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(26, 'non', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(27, 'quas', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(28, 'optio', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(29, 'alias', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(30, 'ad', '2022-06-20 21:21:43', '2022-06-20 21:21:43');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cecos`
--

CREATE TABLE `cecos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(8,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cecos`
--

INSERT INTO `cecos` (`id`, `code`, `description`, `location_id`, `amount`, `created_at`, `updated_at`) VALUES
(1, '584070', 'magni', 1, '0.00', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '297800', 'distinctio', 1, '0.00', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '421733', 'maxime', 2, '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '771845', 'quasi', 2, '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '057182', 'inventore', 3, '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '797793', 'neque', 3, '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '931896', 'exercitationem', 4, '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '647952', 'recusandae', 4, '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '182653', 'quam', 5, '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(10, '983918', 'voluptas', 5, '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(11, '690932', 'id', 6, '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '066884', 'ut', 6, '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '952893', 'quae', 7, '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '579950', 'consequatur', 7, '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(15, '790388', 'modi', 8, '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '236075', 'corrupti', 8, '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ceco_allocation_amounts`
--

CREATE TABLE `ceco_allocation_amounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `allocation_amount` decimal(8,2) NOT NULL,
  `is_allocated` tinyint(1) NOT NULL DEFAULT 0,
  `date` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `ceco_allocation_amounts`
--

INSERT INTO `ceco_allocation_amounts` (`id`, `ceco_id`, `allocation_amount`, `is_allocated`, `date`, `created_at`, `updated_at`) VALUES
(1, 1, '2533.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(2, 2, '2086.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(3, 3, '2139.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(4, 4, '1028.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(5, 5, '1134.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(6, 6, '2024.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(7, 7, '1545.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(8, 8, '2440.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(9, 9, '2046.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(10, 10, '1508.00', 0, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(11, 1, '2765.00', 0, '2022-08-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(12, 2, '2979.00', 0, '2022-08-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(13, 3, '2703.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(14, 4, '2682.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(15, 5, '1223.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(16, 6, '1616.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(17, 7, '2531.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(18, 8, '2916.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(19, 9, '2746.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(20, 10, '2726.00', 0, '2022-08-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(21, 1, '2980.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(22, 2, '2591.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(23, 3, '2971.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(24, 4, '2518.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(25, 5, '2270.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(26, 6, '1600.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(27, 7, '2981.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(28, 8, '2202.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(29, 9, '1152.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(30, 10, '1773.00', 0, '2022-09-01', '2022-06-20 21:21:52', '2022-06-20 21:21:52'),
(31, 1, '1802.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(32, 2, '2244.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(33, 3, '1268.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(34, 4, '1539.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(35, 5, '1911.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(36, 6, '1155.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(37, 7, '2474.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(38, 8, '1317.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(39, 9, '2097.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(40, 10, '1464.00', 0, '2022-10-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(41, 1, '1519.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(42, 2, '1708.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(43, 3, '1763.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(44, 4, '2178.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(45, 5, '2797.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(46, 6, '2519.00', 0, '2022-11-01', '2022-06-20 21:21:53', '2022-06-20 21:21:53'),
(47, 7, '1137.00', 0, '2022-11-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(48, 8, '1259.00', 0, '2022-11-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(49, 9, '1376.00', 0, '2022-11-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(50, 10, '2503.00', 0, '2022-11-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(51, 1, '2917.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(52, 2, '2056.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(53, 3, '1987.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(54, 4, '2216.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(55, 5, '2222.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(56, 6, '1328.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(57, 7, '1155.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(58, 8, '2591.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(59, 9, '2861.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54'),
(60, 10, '1772.00', 0, '2022-12-01', '2022-06-20 21:21:54', '2022-06-20 21:21:54');

--
-- Disparadores `ceco_allocation_amounts`
--
DELIMITER $$
CREATE TRIGGER `aumentar_monto_ceco` BEFORE UPDATE ON `ceco_allocation_amounts` FOR EACH ROW IF(old.is_allocated = false AND new.is_allocated = true) THEN
UPDATE cecos SET amount = amount + old.allocation_amount WHERE id = old.ceco_id;
END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `ceco_details`
--

CREATE TABLE `ceco_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `stockpile_detail_id` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `ceco_details`
--
DELIMITER $$
CREATE TRIGGER `cancelar_disminucion_ceco` AFTER UPDATE ON `ceco_details` FOR EACH ROW IF(new.is_canceled) THEN
UPDATE cecos SET amount = amount + old.price WHERE id = old.ceco_id;
ELSE
UPDATE cecos SET amount = amount + (old.price-new.price) WHERE id = old.ceco_id;
END IF
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `disminuir_monto_ceco` AFTER INSERT ON `ceco_details` FOR EACH ROW UPDATE cecos SET amount = amount - new.price WHERE ceco_id = id
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `componentes_del_implemento`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `componentes_del_implemento` (
`component_id` bigint(20) unsigned
,`item_id` bigint(20) unsigned
,`item` varchar(255)
,`implement_id` bigint(20) unsigned
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `components`
--

CREATE TABLE `components` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `component` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_part` tinyint(1) NOT NULL,
  `lifespan` decimal(8,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `components`
--

INSERT INTO `components` (`id`, `item_id`, `component`, `is_part`, `lifespan`, `created_at`, `updated_at`) VALUES
(1, 2, 'fenphxjv', 0, '4829.00', NULL, NULL),
(2, 3, 'uodoiizm', 1, '258.00', NULL, NULL),
(3, 4, 'inqxlhvr', 1, '344.00', NULL, NULL),
(4, 9, 'ynxsloty', 1, '443.00', NULL, NULL),
(5, 10, 'vdmjztzo', 0, '1844.00', NULL, NULL),
(6, 13, 'xazvmvok', 0, '929.00', NULL, NULL),
(7, 15, 'malgbbvu', 1, '411.00', NULL, NULL),
(8, 17, 'iinqimeg', 0, '2765.00', NULL, NULL),
(9, 18, 'jrnuwort', 0, '1495.00', NULL, NULL),
(10, 19, 'glqsvril', 0, '4180.00', NULL, NULL),
(11, 21, 'qrrmsgax', 1, '142.00', NULL, NULL),
(12, 23, 'tqgvkyjd', 0, '4542.00', NULL, NULL),
(13, 24, 'hnvixqmu', 1, '346.00', NULL, NULL),
(14, 25, 'nnxqjpih', 1, '367.00', NULL, NULL),
(15, 26, 'ztypliaa', 1, '297.00', NULL, NULL),
(16, 27, 'uufgzlwz', 0, '3841.00', NULL, NULL),
(17, 29, 'sjepvnhk', 1, '30.00', NULL, NULL),
(18, 32, 'vzjkkcej', 1, '496.00', NULL, NULL),
(19, 33, 'qyltgffe', 0, '3903.00', NULL, NULL),
(20, 34, 'oozarwvm', 0, '4639.00', NULL, NULL),
(21, 39, 'uydbihgf', 0, '1485.00', NULL, NULL),
(22, 43, 'pvphmrrt', 0, '3510.00', NULL, NULL),
(23, 44, 'odzxmwyq', 1, '310.00', NULL, NULL),
(24, 45, 'spnpzerr', 0, '4948.00', NULL, NULL),
(25, 46, 'abqkzfka', 0, '452.00', NULL, NULL),
(26, 47, 'tdtlgqur', 0, '2414.00', NULL, NULL),
(27, 48, 'omzaqrnd', 0, '717.00', NULL, NULL),
(28, 51, 'igkjtofr', 0, '1342.00', NULL, NULL),
(29, 52, 'lxlrfbxf', 1, '456.00', NULL, NULL),
(30, 53, 'tjhhvizw', 1, '377.00', NULL, NULL),
(31, 54, 'fubvgxmw', 1, '18.00', NULL, NULL),
(32, 55, 'upvgdrsm', 0, '4575.00', NULL, NULL),
(33, 57, 'peorviek', 1, '234.00', NULL, NULL),
(34, 59, 'qvjzldtw', 0, '2974.00', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_implement`
--

CREATE TABLE `component_implement` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `hours` decimal(8,2) NOT NULL DEFAULT 0.00,
  `state` enum('PENDIENTE','ORDENADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_implement`
--

INSERT INTO `component_implement` (`id`, `component_id`, `implement_id`, `hours`, `state`, `created_at`, `updated_at`) VALUES
(1, 28, 1, '12.75', 'PENDIENTE', NULL, NULL),
(2, 8, 1, '12.75', 'PENDIENTE', NULL, NULL),
(3, 20, 1, '12.75', 'PENDIENTE', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_implement_model`
--

CREATE TABLE `component_implement_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `implement_model_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_implement_model`
--

INSERT INTO `component_implement_model` (`id`, `component_id`, `implement_model_id`, `created_at`, `updated_at`) VALUES
(1, 28, 1, NULL, NULL),
(2, 8, 1, NULL, NULL),
(3, 20, 1, NULL, NULL),
(4, 20, 2, NULL, NULL),
(5, 19, 2, NULL, NULL),
(6, 22, 2, NULL, NULL),
(7, 10, 3, NULL, NULL),
(8, 5, 3, NULL, NULL),
(9, 21, 3, NULL, NULL),
(10, 28, 4, NULL, NULL),
(11, 27, 4, NULL, NULL),
(12, 22, 4, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_part`
--

CREATE TABLE `component_part` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_implement_id` bigint(20) UNSIGNED NOT NULL,
  `part` bigint(20) UNSIGNED NOT NULL,
  `hours` decimal(8,2) NOT NULL,
  `state` enum('PENDIENTE','ORDENADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_part`
--

INSERT INTO `component_part` (`id`, `component_implement_id`, `part`, `hours`, `state`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '12.75', 'PENDIENTE', NULL, NULL),
(2, 1, 13, '12.75', 'PENDIENTE', NULL, NULL),
(3, 1, 33, '12.75', 'PENDIENTE', NULL, NULL),
(4, 2, 4, '12.75', 'PENDIENTE', NULL, NULL),
(5, 2, 11, '12.75', 'PENDIENTE', NULL, NULL),
(6, 2, 23, '12.75', 'PENDIENTE', NULL, NULL),
(7, 3, 4, '12.75', 'PENDIENTE', NULL, NULL),
(8, 3, 29, '12.75', 'PENDIENTE', NULL, NULL),
(9, 3, 33, '12.75', 'PENDIENTE', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_part_model`
--

CREATE TABLE `component_part_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component` bigint(20) UNSIGNED NOT NULL,
  `part` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_part_model`
--

INSERT INTO `component_part_model` (`id`, `component`, `part`, `created_at`, `updated_at`) VALUES
(1, 1, 13, NULL, NULL),
(2, 1, 31, NULL, NULL),
(3, 1, 2, NULL, NULL),
(4, 5, 2, NULL, NULL),
(5, 5, 7, NULL, NULL),
(6, 5, 13, NULL, NULL),
(7, 6, 30, NULL, NULL),
(8, 6, 15, NULL, NULL),
(9, 6, 7, NULL, NULL),
(10, 8, 11, NULL, NULL),
(11, 8, 4, NULL, NULL),
(12, 8, 23, NULL, NULL),
(13, 9, 11, NULL, NULL),
(14, 9, 29, NULL, NULL),
(15, 9, 3, NULL, NULL),
(16, 10, 33, NULL, NULL),
(17, 10, 7, NULL, NULL),
(18, 10, 29, NULL, NULL),
(19, 12, 2, NULL, NULL),
(20, 12, 13, NULL, NULL),
(21, 12, 23, NULL, NULL),
(22, 16, 29, NULL, NULL),
(23, 16, 23, NULL, NULL),
(24, 16, 18, NULL, NULL),
(25, 19, 4, NULL, NULL),
(26, 19, 3, NULL, NULL),
(27, 19, 13, NULL, NULL),
(28, 20, 4, NULL, NULL),
(29, 20, 29, NULL, NULL),
(30, 20, 33, NULL, NULL),
(31, 21, 3, NULL, NULL),
(32, 21, 33, NULL, NULL),
(33, 21, 17, NULL, NULL),
(34, 22, 2, NULL, NULL),
(35, 22, 23, NULL, NULL),
(36, 22, 29, NULL, NULL),
(37, 24, 14, NULL, NULL),
(38, 24, 3, NULL, NULL),
(39, 24, 13, NULL, NULL),
(40, 25, 30, NULL, NULL),
(41, 25, 15, NULL, NULL),
(42, 25, 2, NULL, NULL),
(43, 26, 30, NULL, NULL),
(44, 26, 33, NULL, NULL),
(45, 26, 2, NULL, NULL),
(46, 27, 11, NULL, NULL),
(47, 27, 30, NULL, NULL),
(48, 27, 33, NULL, NULL),
(49, 28, 13, NULL, NULL),
(50, 28, 2, NULL, NULL),
(51, 28, 33, NULL, NULL),
(52, 32, 23, NULL, NULL),
(53, 32, 4, NULL, NULL),
(54, 32, 2, NULL, NULL),
(55, 34, 33, NULL, NULL),
(56, 34, 3, NULL, NULL),
(57, 34, 31, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_system`
--

CREATE TABLE `component_system` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `system_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `crops`
--

CREATE TABLE `crops` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `crop` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `crops`
--

INSERT INTO `crops` (`id`, `crop`, `created_at`, `updated_at`) VALUES
(1, 'quidem', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(2, 'illo', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(3, 'laboriosam', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(4, 'tempora', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(5, 'magni', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(6, 'hic', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(7, 'dolores', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(8, 'dicta', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(9, 'porro', '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(10, 'architecto', '2022-06-20 21:21:47', '2022-06-20 21:21:47');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epps`
--

CREATE TABLE `epps` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `epps`
--

INSERT INTO `epps` (`id`, `epp`, `created_at`, `updated_at`) VALUES
(1, 'debitis', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(2, 'eligendi', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(3, 'deserunt', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(4, 'corrupti', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(5, 'inventore', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(6, 'reiciendis', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(7, 'id', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(8, 'a', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(9, 'nemo', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(10, 'esse', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(11, 'at', '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(12, 'itaque', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(13, 'animi', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(14, 'vero', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(15, 'praesentium', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(16, 'reprehenderit', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(17, 'tempore', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(18, 'cupiditate', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(19, 'officiis', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(20, 'quaerat', '2022-06-20 21:21:49', '2022-06-20 21:21:49');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epp_risk`
--

CREATE TABLE `epp_risk` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED NOT NULL,
  `risk_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epp_work_order`
--

CREATE TABLE `epp_work_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED NOT NULL,
  `work_order` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `implements`
--

CREATE TABLE `implements` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `implement_model_id` bigint(20) UNSIGNED NOT NULL,
  `implement_number` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hours` decimal(8,2) NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `implements`
--

INSERT INTO `implements` (`id`, `implement_model_id`, `implement_number`, `hours`, `user_id`, `location_id`, `ceco_id`, `created_at`, `updated_at`) VALUES
(1, 1, '5243', '79.70', 1, 1, 1, '2022-06-20 21:21:59', '2022-06-24 13:00:49'),
(2, 1, '2399', '24.94', 2, 1, 2, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(3, 1, '6977', '52.51', 3, 2, 3, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(4, 1, '9149', '81.06', 4, 2, 4, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(5, 2, '3513', '43.59', 5, 3, 5, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(6, 2, '6295', '21.92', 6, 3, 6, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(7, 2, '4375', '91.21', 7, 4, 7, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(8, 2, '6477', '28.34', 8, 4, 8, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(9, 3, '0082', '69.10', 9, 5, 9, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(10, 3, '4653', '29.19', 10, 5, 10, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(11, 3, '9503', '41.07', 11, 6, 11, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(12, 3, '0022', '91.73', 12, 6, 12, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(13, 4, '4470', '23.98', 13, 7, 13, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(14, 4, '2101', '80.32', 14, 7, 14, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(15, 4, '7047', '76.49', 15, 8, 15, '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(16, 4, '5378', '20.66', 16, 8, 16, '2022-06-20 21:22:00', '2022-06-20 21:22:00');

--
-- Disparadores `implements`
--
DELIMITER $$
CREATE TRIGGER `aumentar_horas_imp_comp` AFTER UPDATE ON `implements` FOR EACH ROW IF(new.hours<>old.hours) THEN
BEGIN
DECLARE part_final INT DEFAULT 0;
DECLARE comp_final INT DEFAULT 0;
DECLARE componente INT;
DECLARE pieza INT;
DECLARE comp_imp INT;
DECLARE cursor_componente CURSOR FOR SELECT cim.component_id FROM component_implement_model cim INNER JOIN implements i ON i.implement_model_id = cim.implement_model_id WHERE i.id = old.id;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET comp_final = 1;
/*-------Actualizar horas de los componentes--------*/
OPEN cursor_componente;
	bucle: LOOP
    FETCH cursor_componente INTO componente;
    IF comp_final = 1 THEN
    	LEAVE bucle;
    END IF;
    IF EXISTS(SELECT * FROM component_implement ci WHERE ci.component_id = componente AND ci.implement_id = new.id AND ci.state = "PENDIENTE") THEN
    UPDATE component_implement ci SET ci.hours = ci.hours+(new.hours-old.hours) WHERE ci.component_id = componente AND ci.implement_id = new.id AND ci.state = 'PENDIENTE';
    ELSE
    INSERT INTO component_implement (component_id,implement_id,hours) VALUES(componente,new.id,(new.hours-old.hours));
    END IF;
    SELECT id INTO comp_imp FROM component_implement ci WHERE ci.component_id = componente AND ci.implement_id = new.id AND ci.state = "PENDIENTE";
/*-------Actualizar componentes-----------------*/
BEGIN
	DECLARE cursor_part CURSOR FOR SELECT cpm.part FROM component_part_model cpm WHERE cpm.component = componente;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET part_final = 1;
    OPEN cursor_part;
    bucle2: LOOP
    FETCH cursor_part INTO pieza;
    IF part_final = 1 THEN
    	LEAVE bucle2;
    END IF;
    IF EXISTS(SELECT * FROM component_part cp WHERE cp.component_implement_id = comp_imp AND cp.part = pieza AND cp.state = 'PENDIENTE') THEN
    UPDATE component_part cp SET cp.hours = cp.hours + (new.hours-old.hours) WHERE cp.component_implement_id = comp_imp AND cp.part = pieza AND cp.state = 'PENDIENTE';
    ELSE
    INSERT INTO component_part (component_implement_id,part,hours) VALUES (comp_imp,pieza,(new.hours-old.hours));
    END IF;
    END LOOP bucle2;
    CLOSE cursor_part;
    SELECT 0 INTO part_final;
END;
	END LOOP bucle;
CLOSE cursor_componente;
END;
END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `implement_models`
--

CREATE TABLE `implement_models` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `implement_model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `implement_models`
--

INSERT INTO `implement_models` (`id`, `implement_model`, `created_at`, `updated_at`) VALUES
(1, 'pxwuxakalx', '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(2, 'kcxjtxlcjk', '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(3, 'brjzqzjwps', '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(4, 'kohilrnrky', '2022-06-20 21:22:00', '2022-06-20 21:22:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `items`
--

CREATE TABLE `items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `sku` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `brand_id` bigint(20) UNSIGNED NOT NULL,
  `measurement_unit_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_price` decimal(8,2) NOT NULL,
  `type` enum('FUNGIBLE','COMPONENTE','PIEZA','HERRAMIENTA') COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `items`
--

INSERT INTO `items` (`id`, `sku`, `item`, `brand_id`, `measurement_unit_id`, `estimated_price`, `type`, `is_active`, `created_at`, `updated_at`) VALUES
(1, '55268423', 'emibwyfg', 8, 1, '272.91', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(2, '93430686', 'fenphxjv', 30, 8, '328.66', 'COMPONENTE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(3, '80410193', 'uodoiizm', 9, 15, '692.98', 'PIEZA', 1, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(4, '32172961', 'inqxlhvr', 17, 25, '459.05', 'PIEZA', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(5, '24557228', 'ajshyciq', 4, 35, '317.70', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(6, '54017263', 'lsbacktu', 3, 6, '353.62', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(7, '88284457', 'kuvozafk', 30, 12, '521.02', 'HERRAMIENTA', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(8, '44888932', 'hlfqhqzs', 11, 36, '563.25', 'HERRAMIENTA', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(9, '63566827', 'ynxsloty', 19, 13, '362.42', 'PIEZA', 1, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(10, '76748747', 'vdmjztzo', 29, 46, '255.15', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(11, '56684879', 'exitexcs', 17, 7, '405.08', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(12, '79831941', 'vgldtuea', 16, 1, '289.01', 'HERRAMIENTA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(13, '33326523', 'xazvmvok', 22, 2, '892.36', 'COMPONENTE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(14, '80675228', 'nsknjzug', 26, 16, '861.84', 'FUNGIBLE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(15, '26685018', 'malgbbvu', 23, 34, '958.75', 'PIEZA', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(16, '60201284', 'mfduollm', 1, 31, '934.97', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(17, '09000210', 'iinqimeg', 12, 1, '906.47', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(18, '06619500', 'jrnuwort', 6, 2, '276.26', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(19, '21102998', 'glqsvril', 14, 7, '488.01', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(20, '47215073', 'avpaglsu', 16, 24, '642.75', 'HERRAMIENTA', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(21, '81323780', 'qrrmsgax', 12, 15, '785.44', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(22, '39157590', 'ybyvnshl', 28, 2, '391.84', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(23, '98004376', 'tqgvkyjd', 30, 12, '973.03', 'COMPONENTE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(24, '36059421', 'hnvixqmu', 7, 47, '577.05', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(25, '95868526', 'nnxqjpih', 25, 25, '289.79', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(26, '48468841', 'ztypliaa', 8, 13, '228.07', 'PIEZA', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(27, '42247040', 'uufgzlwz', 29, 29, '888.74', 'COMPONENTE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(28, '86544233', 'boemtgom', 19, 31, '515.10', 'HERRAMIENTA', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(29, '89960915', 'sjepvnhk', 22, 18, '378.24', 'PIEZA', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(30, '33672732', 'gjsfgooc', 2, 32, '630.61', 'FUNGIBLE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(31, '86587497', 'xldizthx', 12, 23, '315.89', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(32, '27197936', 'vzjkkcej', 16, 27, '307.03', 'PIEZA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(33, '67302155', 'qyltgffe', 8, 37, '819.03', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(34, '74638099', 'oozarwvm', 18, 22, '797.90', 'COMPONENTE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(35, '42255844', 'ppqwbfqs', 22, 24, '340.23', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(36, '51228546', 'jmgoppan', 18, 48, '772.61', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(37, '98829047', 'gunhazga', 12, 29, '364.29', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(38, '85574668', 'emdbfexa', 7, 49, '920.70', 'FUNGIBLE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(39, '04366084', 'uydbihgf', 26, 46, '305.84', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(40, '30753700', 'kcikmfjy', 4, 2, '247.13', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(41, '55132606', 'sxuwykmm', 2, 40, '803.68', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(42, '19702921', 'ytqwfjkt', 12, 13, '497.07', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(43, '91153538', 'pvphmrrt', 21, 13, '984.46', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(44, '88209620', 'odzxmwyq', 3, 3, '954.65', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(45, '23261667', 'spnpzerr', 7, 22, '894.30', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(46, '01253032', 'abqkzfka', 24, 14, '697.98', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(47, '10226033', 'tdtlgqur', 6, 32, '245.22', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(48, '54714028', 'omzaqrnd', 25, 47, '521.61', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(49, '42080919', 'tkszkird', 21, 34, '945.11', 'HERRAMIENTA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(50, '20962715', 'sncjkzkm', 17, 10, '846.80', 'FUNGIBLE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(51, '35177831', 'igkjtofr', 30, 11, '368.41', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(52, '13254575', 'lxlrfbxf', 22, 2, '216.64', 'PIEZA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(53, '34323256', 'tjhhvizw', 5, 13, '952.16', 'PIEZA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(54, '36718680', 'fubvgxmw', 9, 16, '675.23', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(55, '01411861', 'upvgdrsm', 7, 29, '586.61', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(56, '63768263', 'uezoavoy', 17, 1, '918.22', 'HERRAMIENTA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(57, '66196453', 'peorviek', 26, 46, '502.17', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(58, '85923667', 'qwieldov', 25, 1, '483.13', 'HERRAMIENTA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(59, '55183394', 'qvjzldtw', 19, 50, '375.49', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(60, '88387187', 'ouenaesm', 19, 25, '473.77', 'FUNGIBLE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58');

--
-- Disparadores `items`
--
DELIMITER $$
CREATE TRIGGER `agregar_componentes` AFTER INSERT ON `items` FOR EACH ROW IF(new.type="COMPONENTE") THEN
INSERT INTO components (item_id,component,is_part,lifespan) VALUES (new.id,new.item,0,ROUND(RAND()*5000));
ELSEIF(new.type="PIEZA") THEN
INSERT INTO components(item_id,component,is_part,lifespan) VALUES (new.id,new.item,1,ROUND(RAND()*500));
END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `labors`
--

CREATE TABLE `labors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `labor` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `labors`
--

INSERT INTO `labors` (`id`, `labor`, `created_at`, `updated_at`) VALUES
(1, 'qppdth', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(2, 'fuduvx', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(3, 'etskea', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(4, 'gvsjig', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(5, 'mjnonx', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(6, 'lnmizx', '2022-06-20 21:22:03', '2022-06-20 21:22:03');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `loans`
--

CREATE TABLE `loans` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `lender_stock_id` bigint(20) UNSIGNED NOT NULL,
  `borrower_stock_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `locations`
--

CREATE TABLE `locations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sede_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `locations`
--

INSERT INTO `locations` (`id`, `code`, `location`, `sede_id`, `created_at`, `updated_at`) VALUES
(1, '461330', 'molestias', 1, '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '857147', 'omnis', 1, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '639678', 'distinctio', 2, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '719304', 'non', 2, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(5, '063994', 'ad', 3, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(6, '979452', 'occaecati', 3, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(7, '378233', 'in', 4, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(8, '412730', 'assumenda', 4, '2022-06-20 21:21:41', '2022-06-20 21:21:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lotes`
--

CREATE TABLE `lotes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lote` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `lotes`
--

INSERT INTO `lotes` (`id`, `code`, `lote`, `location_id`, `created_at`, `updated_at`) VALUES
(1, '454473', 'sed', 1, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '095839', 'similique', 1, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '560420', 'hic', 2, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '264812', 'temporibus', 2, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '570752', 'deserunt', 3, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '490323', 'ut', 3, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '709012', 'molestiae', 4, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '760744', 'nulla', 4, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '604187', 'quibusdam', 5, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(10, '368871', 'et', 5, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(11, '393367', 'repellendus', 6, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '827344', 'ullam', 6, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '352267', 'architecto', 7, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '464700', 'veniam', 7, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(15, '366008', 'earum', 8, '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '930657', 'incidunt', 8, '2022-06-20 21:21:41', '2022-06-20 21:21:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `measurement_units`
--

CREATE TABLE `measurement_units` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `measurement_unit` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abbreviation` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `measurement_units`
--

INSERT INTO `measurement_units` (`id`, `measurement_unit`, `abbreviation`, `created_at`, `updated_at`) VALUES
(1, 'sunt', 'jhs', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(2, 'rerum', 'pfb', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(3, 'corporis', 'kbs', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(4, 'temporibus', 'xyd', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(5, 'dolore', 'xpl', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(6, 'numquam', 'vav', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(7, 'iure', 'qtq', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(8, 'ea', 'gge', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(9, 'autem', 'krv', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(10, 'quod', 'iqs', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(11, 'asperiores', 'tcd', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(12, 'aliquid', 'nvi', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(13, 'minima', 'zoa', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(14, 'est', 'sdy', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(15, 'explicabo', 'djg', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(16, 'dolorem', 'kns', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(17, 'blanditiis', 'jqp', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(18, 'dolor', 'okh', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(19, 'vel', 'kju', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(20, 'expedita', 'eng', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(21, 'qui', 'qfr', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(22, 'recusandae', 'zyu', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(23, 'fugiat', 'ubb', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(24, 'doloribus', 'pvr', '2022-06-20 21:21:44', '2022-06-20 21:21:44'),
(25, 'voluptatibus', 'cdv', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(26, 'excepturi', 'vnv', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(27, 'maiores', 'mki', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(28, 'sint', 'tvf', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(29, 'quam', 'weu', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(30, 'quia', 'ala', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(31, 'laudantium', 'dud', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(32, 'nisi', 'hak', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(33, 'suscipit', 'dxi', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(34, 'ducimus', 'ifs', '2022-06-20 21:21:45', '2022-06-20 21:21:45'),
(35, 'aspernatur', 'xiw', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(36, 'consequatur', 'nvb', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(37, 'natus', 'iow', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(38, 'eius', 'xpv', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(39, 'quis', 'hgg', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(40, 'occaecati', 'nlf', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(41, 'error', 'uez', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(42, 'neque', 'obo', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(43, 'ipsa', 'cjb', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(44, 'soluta', 'geb', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(45, 'amet', 'ham', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(46, 'totam', 'sep', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(47, 'facere', 'zvy', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(48, 'distinctio', 'dmm', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(49, 'beatae', 'mgn', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(50, 'possimus', 'qsc', '2022-06-20 21:21:46', '2022-06-20 21:21:46');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '2014_10_12_000000_create_users_table', 1),
(2, '2014_10_12_100000_create_password_resets_table', 1),
(3, '2014_10_12_200000_add_two_factor_columns_to_users_table', 1),
(4, '2019_08_19_000000_create_failed_jobs_table', 1),
(5, '2019_12_14_000001_create_personal_access_tokens_table', 1),
(6, '2022_05_08_191437_create_sessions_table', 1),
(7, '2022_05_08_233948_create_zones_table', 1),
(8, '2022_05_08_235530_create_sedes_table', 1),
(9, '2022_05_09_011406_create_locations_table', 1),
(10, '2022_05_09_011408_create_lotes_table', 1),
(11, '2022_05_09_012519_create_cecos_table', 1),
(12, '2022_05_24_025316_create_brands_table', 1),
(13, '2022_05_24_025535_create_measurement_units_table', 1),
(14, '2022_05_24_030120_create_ceco_allocation_amounts_table', 1),
(15, '2022_05_24_030122_create_items_table', 1),
(16, '2022_05_24_035453_create_implement_models_table', 1),
(17, '2022_05_24_035625_create_implements_table', 1),
(18, '2022_05_24_131152_create_components_table', 1),
(19, '2022_05_24_141108_create_crops_table', 1),
(20, '2022_05_24_141431_create_epps_table', 1),
(21, '2022_05_24_161915_create_labors_table', 1),
(22, '2022_05_24_162236_create_order_dates_table', 1),
(23, '2022_05_24_162237_create_order_requests_table', 1),
(24, '2022_05_24_162907_create_order_request_details_table', 1),
(25, '2022_05_24_165729_create_order_request_new_items_table', 1),
(26, '2022_05_24_170204_create_risks_table', 1),
(27, '2022_05_24_170500_create_systems_table', 1),
(28, '2022_05_24_170809_create_tasks_table', 1),
(29, '2022_05_24_172039_create_tractor_models_table', 1),
(30, '2022_05_24_172051_create_tractors_table', 1),
(31, '2022_05_24_183952_create_tractor_schedulings_table', 1),
(32, '2022_05_25_125203_create_tractor_reports_table', 1),
(33, '2022_05_25_130111_create_work_orders_table', 1),
(34, '2022_05_25_130534_create_work_order_details_table', 1),
(35, '2022_05_25_130602_create_work_order_epps_table', 1),
(36, '2022_05_25_145541_create_warehouses_table', 1),
(37, '2022_05_25_151228_create_operator_stocks_table', 1),
(38, '2022_05_25_151514_create_operator_stock_details_table', 1),
(39, '2022_05_25_191029_create_operator_assigned_stocks_table', 1),
(40, '2022_05_25_191626_create_released_stocks_table', 1),
(41, '2022_05_25_191802_create_released_stock_details_table', 1),
(42, '2022_05_28_171740_create_min_stocks_table', 1),
(43, '2022_05_28_171753_create_min_stock_details_table', 1),
(44, '2022_05_28_171851_create_pre_stockpiles_table', 1),
(45, '2022_05_28_171905_create_pre_stockpile_details_table', 1),
(46, '2022_05_28_172051_create_stockpiles_table', 1),
(47, '2022_05_28_172103_create_stockpile_details_table', 1),
(48, '2022_05_28_172105_create_ceco_details_table', 1),
(49, '2022_05_28_172136_create_stocks_table', 1),
(50, '2022_05_28_172152_create_loans_table', 1),
(51, '2022_05_31_020651_create_component_implement_model_table', 1),
(52, '2022_05_31_023405_create_component_system_table', 1),
(53, '2022_05_31_023508_create_epp_risk_table', 1),
(54, '2022_05_31_023549_create_epp_work_order_table', 1),
(55, '2022_05_31_023640_create_risk_task_order_table', 1),
(56, '2022_06_03_000153_create_component_implement_table', 1),
(57, '2022_06_06_131457_create_component_part_table', 1),
(58, '2022_06_08_143231_component_part_model', 1),
(59, '2022_06_08_184844_create_affected_movement_table', 1),
(60, '2022_06_20_052727_create_permission_tables', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `min_stocks`
--

CREATE TABLE `min_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `required_quantity` decimal(8,2) NOT NULL,
  `current_quantity` decimal(8,2) NOT NULL,
  `price` double NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `min_stock_details`
--

CREATE TABLE `min_stock_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `movement` enum('INGRESO','SALIDA') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `implement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `min_stock_details`
--
DELIMITER $$
CREATE TRIGGER `actualizar_stock_minimo` AFTER UPDATE ON `min_stock_details` FOR EACH ROW IF(new.movement="INGRESO") THEN
IF(new.is_canceled) THEN
UPDATE min_stocks SET current_quantity = current_quantity - old.quantity, price = price - old.price WHERE item_id = old.item_id AND warehouse_id = old.warehouse_id;
ELSE
UPDATE min_stocks SET current_quantity = current_quantity - old.quantity+new.quantity, price = price - old.price + new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
END IF;
ELSE
IF(new.is_canceled) THEN
UPDATE min_stocks SET current_quantity = current_quantity + new.quantity, price = price + new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
ELSE
UPDATE min_stocks SET current_quantity = current_quantity + old.quantity-new.quantity, price = price + old.price - new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
END IF;
END IF
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `aumentar_stock_minimo` AFTER INSERT ON `min_stock_details` FOR EACH ROW IF(new.movement="INGRESO") THEN
UPDATE min_stocks SET current_quantity = current_quantity + new.quantity, price = price + new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
ELSE
UPDATE min_stocks SET current_quantity = current_quantity - new.quantity, price = price - new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `model_has_permissions`
--

CREATE TABLE `model_has_permissions` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `model_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `model_has_roles`
--

CREATE TABLE `model_has_roles` (
  `role_id` bigint(20) UNSIGNED NOT NULL,
  `model_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `model_has_roles`
--

INSERT INTO `model_has_roles` (`role_id`, `model_type`, `model_id`) VALUES
(1, 'App\\Models\\User', 1),
(2, 'App\\Models\\User', 2),
(3, 'App\\Models\\User', 3),
(3, 'App\\Models\\User', 6),
(3, 'App\\Models\\User', 7),
(3, 'App\\Models\\User', 8),
(4, 'App\\Models\\User', 4),
(5, 'App\\Models\\User', 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `operator_assigned_stocks`
--

CREATE TABLE `operator_assigned_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('ASIGNADO','LIBERADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `operator_assigned_stocks`
--
DELIMITER $$
CREATE TRIGGER `liberar_material` AFTER UPDATE ON `operator_assigned_stocks` FOR EACH ROW IF new.state = "LIBERADO" THEN
INSERT INTO released_stock_details (user_id, item_id, movement, quantity, price, warehouse_id, operator_assigned_stock_id) VALUES (old.user_id, old.item_id, 'INGRESO', old.quantity, old.price, old.warehouse_id,old.id);
END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `operator_stocks`
--

CREATE TABLE `operator_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `operator_stock_details`
--

CREATE TABLE `operator_stock_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `movement` enum('INGRESO','SALIDA') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('CONFIRMADO','ANULADO','LIBERADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_request_detail_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `operator_stock_details`
--
DELIMITER $$
CREATE TRIGGER `anulacion_movimientos` AFTER UPDATE ON `operator_stock_details` FOR EACH ROW BEGIN
DECLARE op_stock INT;
DECLARE op_assigned INT;
DECLARE stock INT;
/*---Obteniendo filas afectadas------*/
SELECT operator_stock_id, operator_assigned_stock_id, stock_id INTO op_stock,op_assigned,stock FROM affected_movement WHERE operator_stock_details_id = old.id;
IF new.movement = "INGRESO" THEN
/*----------ANULAR INGRESO------*/
/*-----Anular en operator_stocks--------*/
UPDATE operator_stocks SET quantity = quantity - old.quantity, price = price - new.price WHERE id = op_stock;
/*----Anular en operator_assigned_stocks--*/
UPDATE operator_assigned_stocks SET quantity = quantity - old.quantity, price = price - old.price WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity - old.quantity, price = price - old.price WHERE id = stock;
ELSE
/*----------ANULAR SALIDA-------*/
/*---------Anular en op_stock---------*/
UPDATE operator_stocks SET quantity = quantity + old.quantity, price = price + old.price WHERE id = op_stock;
/*----Anular en operator_assigned_stocks--*/
UPDATE operator_assigned_stocks SET quantity = quantity + old.quantity, price = price + old.price WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity + old.quantity, price = price + old.price WHERE id = stock;
END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `operator_stocks_input` AFTER INSERT ON `operator_stock_details` FOR EACH ROW BEGIN
DECLARE op_stock INT;
DECLARE op_assigned INT;
DECLARE stock_general INT;
DECLARE cantidad double;
DECLARE cantidad_sobrante double;
DECLARE precio double;
DECLARE precio_sobrante double;
IF new.movement = "INGRESO" THEN
/*-----------INGRESO DEL MATERIAL--------------------*/
/*--Insertar material acumulado del operador--*/
IF EXISTS (SELECT * FROM operator_stocks WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id) THEN
UPDATE operator_stocks
SET quantity = quantity+new.quantity, price = price+new.price WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO op_stock FROM operator_stocks ORDER BY updated_at DESC LIMIT 1;
ELSE
INSERT INTO operator_stocks(user_id, item_id, quantity, price, warehouse_id) VALUES (new.user_id, new.item_id, new.quantity, new.price, new.warehouse_id);
SELECT MAX(id) INTO op_stock FROM operator_stocks;
END IF;
/*--Insertar material al acumulado general del almacen--*/
IF EXISTS (SELECT * FROM stocks WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id) THEN
UPDATE stocks SET quantity = quantity + new.quantity, price = price + new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO stock_general FROM stocks ORDER BY updated_at DESC LIMIT 1;
ELSE
INSERT INTO stocks (item_id, quantity, price, warehouse_id) VALUES (new.item_id, new.quantity, new.price, new.warehouse_id);
SELECT MAX(id) INTO stock_general FROM stocks;
END IF;
/*-------Material asignado al operador por fecha para descontar--------*/
INSERT INTO operator_assigned_stocks(user_id, item_id, quantity, unit_price,price, warehouse_id) VALUES (new.user_id, new.item_id, new.quantity,(new.price/new.quantity), new.price, new.warehouse_id);
SELECT MAX(id) INTO op_assigned FROM operator_assigned_stocks;
ELSEIF new.movement = "SALIDA" THEN
/*-------SALIDA DEL MATERIAL-----------*/
/*-----Acumulado del operador-----*/
UPDATE operator_stocks SET quantity = quantity - new.quantity, price = price-new.price WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO op_stock FROM operator_stocks ORDER BY updated_at DESC LIMIT 1;
IF new.state = "CONFIRMADO" THEN
/*---Descontar items por antiguedad----*/
SELECT quantity,price INTO cantidad,precio FROM operator_assigned_stocks WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id AND quantity <> 0 ORDER BY created_at ASC LIMIT 1;
SELECT new.quantity,new.price INTO cantidad_sobrante,precio_sobrante;
WHILE cantidad_sobrante > cantidad DO
UPDATE operator_assigned_stocks SET quantity = 0, price = 0 WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id AND quantity <> 0 ORDER BY created_at ASC LIMIT 1;
SELECT (cantidad_sobrante-cantidad),(precio_sobrante-precio) INTO cantidad_sobrante,precio_sobrante;
SELECT quantity,price INTO cantidad,precio FROM operator_assigned_stocks WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id AND quantity <> 0 ORDER BY created_at ASC LIMIT 1;
END WHILE;
IF cantidad >= cantidad_sobrante THEN
UPDATE operator_assigned_stocks SET quantity = quantity - cantidad_sobrante, price = price - precio_sobrante WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id AND quantity <> 0 ORDER BY created_at ASC LIMIT 1;
END IF;
SELECT id INTO op_assigned FROM operator_assigned_stocks ORDER BY updated_at DESC LIMIT 1;
/*--------Descontar el stock general---*/
UPDATE stocks SET quantity = quantity - new.quantity, price = price - new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO stock_general FROM stocks ORDER BY updated_at DESC LIMIT 1;
ELSE
SELECT id INTO op_assigned FROM operator_assigned_stocks WHERE state = "LIBERADO" ORDER BY updated_at DESC LIMIT 1;
END IF;
/*----------END SALIDA----------*/
END IF;
INSERT INTO affected_movement (operator_stock_id, operator_stock_detail_id, operator_assigned_stock_id, stock_id) VALUES (op_stock, new.id, op_assigned, stock_general);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_dates`
--

CREATE TABLE `order_dates` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `open_request` date NOT NULL,
  `close_request` date NOT NULL,
  `order_date` date NOT NULL,
  `arrival_date` date NOT NULL,
  `state` enum('PENDIENTE','ABIERTO','CERRADO','VALIDADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_dates`
--

INSERT INTO `order_dates` (`id`, `open_request`, `close_request`, `order_date`, `arrival_date`, `state`, `created_at`, `updated_at`) VALUES
(1, '2022-04-25', '2022-04-28', '2022-05-02', '2022-07-01', 'ABIERTO', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(2, '2022-06-27', '2022-06-30', '2022-07-04', '2022-09-01', 'PENDIENTE', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(3, '2022-08-29', '2022-09-01', '2022-09-05', '2022-11-01', 'PENDIENTE', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(4, '2022-12-26', '2022-12-29', '2022-01-02', '2022-02-01', 'PENDIENTE', '2022-06-20 22:22:56', '2022-06-20 22:22:56');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_requests`
--

CREATE TABLE `order_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','CERRADO','VALIDADO','RECHAZADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `estimated_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `validate_by` bigint(20) UNSIGNED DEFAULT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `order_date_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_requests`
--

INSERT INTO `order_requests` (`id`, `user_id`, `implement_id`, `state`, `estimated_price`, `validate_by`, `is_canceled`, `order_date_id`, `created_at`, `updated_at`) VALUES
(33, 1, 1, 'PENDIENTE', '16360.55', NULL, 0, 1, NULL, NULL),
(34, 2, 2, 'PENDIENTE', '16360.55', NULL, 0, 1, NULL, NULL),
(35, 3, 3, 'PENDIENTE', '16360.55', NULL, 0, 1, NULL, NULL),
(36, 4, 4, 'PENDIENTE', '16360.55', NULL, 0, 1, NULL, NULL),
(37, 5, 5, 'PENDIENTE', '9823.00', NULL, 0, 1, NULL, NULL),
(38, 6, 6, 'PENDIENTE', '9823.00', NULL, 0, 1, NULL, NULL),
(39, 7, 7, 'PENDIENTE', '9823.00', NULL, 0, 1, NULL, NULL),
(40, 8, 8, 'PENDIENTE', '9823.00', NULL, 0, 1, NULL, NULL),
(41, 9, 9, 'PENDIENTE', '19707.23', NULL, 0, 1, NULL, NULL),
(42, 10, 10, 'PENDIENTE', '19707.23', NULL, 0, 1, NULL, NULL),
(43, 11, 11, 'PENDIENTE', '19707.23', NULL, 0, 1, NULL, NULL),
(44, 12, 12, 'PENDIENTE', '19707.23', NULL, 0, 1, NULL, NULL),
(45, 13, 13, 'PENDIENTE', '15727.94', NULL, 0, 1, NULL, NULL),
(46, 14, 14, 'PENDIENTE', '15727.94', NULL, 0, 1, NULL, NULL),
(47, 15, 15, 'PENDIENTE', '15727.94', NULL, 0, 1, NULL, NULL),
(48, 16, 16, 'PENDIENTE', '30967.39', NULL, 0, 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_request_details`
--

CREATE TABLE `order_request_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_request_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `estimated_price` decimal(8,2) NOT NULL,
  `state` enum('PENDIENTE','ACEPTADO','MODIFICADO','RECHAZADO','VALIDADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `observation` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_details`
--

INSERT INTO `order_request_details` (`id`, `order_request_id`, `item_id`, `quantity`, `estimated_price`, `state`, `observation`, `created_at`, `updated_at`) VALUES
(402, 33, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(403, 33, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(404, 33, 44, '2.00', '1909.30', 'PENDIENTE', NULL, NULL, NULL),
(405, 33, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(406, 33, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(407, 33, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(408, 33, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(409, 34, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(410, 34, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(411, 34, 44, '2.00', '1909.30', 'PENDIENTE', NULL, NULL, NULL),
(412, 34, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(413, 34, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(414, 34, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(415, 34, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(416, 35, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(417, 35, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(418, 35, 44, '2.00', '1909.30', 'PENDIENTE', NULL, NULL, NULL),
(419, 35, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(420, 35, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(421, 35, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(422, 35, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(423, 36, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(424, 36, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(425, 36, 44, '2.00', '1909.30', 'PENDIENTE', NULL, NULL, NULL),
(426, 36, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(427, 36, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(428, 36, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(429, 36, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(430, 37, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(431, 37, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(432, 37, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(433, 37, 52, '3.00', '649.92', 'PENDIENTE', NULL, NULL, NULL),
(434, 37, 57, '2.00', '1004.34', 'PENDIENTE', NULL, NULL, NULL),
(435, 37, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(436, 37, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(437, 38, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(438, 38, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(439, 38, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(440, 38, 52, '3.00', '649.92', 'PENDIENTE', NULL, NULL, NULL),
(441, 38, 57, '2.00', '1004.34', 'PENDIENTE', NULL, NULL, NULL),
(442, 38, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(443, 38, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(444, 39, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(445, 39, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(446, 39, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(447, 39, 52, '3.00', '649.92', 'PENDIENTE', NULL, NULL, NULL),
(448, 39, 57, '2.00', '1004.34', 'PENDIENTE', NULL, NULL, NULL),
(449, 39, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(450, 39, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(451, 40, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(452, 40, 9, '2.00', '724.84', 'PENDIENTE', NULL, NULL, NULL),
(453, 40, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(454, 40, 52, '3.00', '649.92', 'PENDIENTE', NULL, NULL, NULL),
(455, 40, 57, '2.00', '1004.34', 'PENDIENTE', NULL, NULL, NULL),
(456, 40, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(457, 40, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(458, 41, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(459, 41, 15, '2.00', '1917.50', 'PENDIENTE', NULL, NULL, NULL),
(460, 41, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(461, 41, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(462, 41, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(463, 41, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(464, 41, 29, '11.00', '378.24', 'PENDIENTE', NULL, NULL, NULL),
(465, 42, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(466, 42, 15, '2.00', '1917.50', 'PENDIENTE', NULL, NULL, NULL),
(467, 42, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(468, 42, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(469, 42, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(470, 42, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(471, 42, 29, '11.00', '378.24', 'PENDIENTE', NULL, NULL, NULL),
(472, 43, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(473, 43, 15, '2.00', '1917.50', 'PENDIENTE', NULL, NULL, NULL),
(474, 43, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(475, 43, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(476, 43, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(477, 43, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(478, 43, 29, '11.00', '378.24', 'PENDIENTE', NULL, NULL, NULL),
(479, 44, 3, '1.00', '692.98', 'PENDIENTE', NULL, NULL, NULL),
(480, 44, 15, '2.00', '1917.50', 'PENDIENTE', NULL, NULL, NULL),
(481, 44, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL),
(482, 44, 52, '1.00', '216.64', 'PENDIENTE', NULL, NULL, NULL),
(483, 44, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(484, 44, 4, '1.00', '459.05', 'PENDIENTE', NULL, NULL, NULL),
(485, 44, 29, '11.00', '378.24', 'PENDIENTE', NULL, NULL, NULL),
(486, 45, 3, '2.00', '1385.96', 'PENDIENTE', NULL, NULL, NULL),
(487, 45, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(488, 45, 52, '2.00', '433.28', 'PENDIENTE', NULL, NULL, NULL),
(489, 45, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(490, 45, 53, '1.00', '952.16', 'PENDIENTE', NULL, NULL, NULL),
(491, 45, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(492, 45, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(493, 46, 3, '2.00', '1385.96', 'PENDIENTE', NULL, NULL, NULL),
(494, 46, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(495, 46, 52, '2.00', '433.28', 'PENDIENTE', NULL, NULL, NULL),
(496, 46, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(497, 46, 53, '1.00', '952.16', 'PENDIENTE', NULL, NULL, NULL),
(498, 46, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(499, 46, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(500, 47, 3, '2.00', '1385.96', 'PENDIENTE', NULL, NULL, NULL),
(501, 47, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(502, 47, 52, '2.00', '433.28', 'PENDIENTE', NULL, NULL, NULL),
(503, 47, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(504, 47, 53, '1.00', '952.16', 'PENDIENTE', NULL, NULL, NULL),
(505, 47, 57, '4.00', '2008.68', 'PENDIENTE', NULL, NULL, NULL),
(506, 47, 24, '1.00', '577.05', 'PENDIENTE', NULL, NULL, NULL),
(507, 48, 3, '3.00', '2078.94', 'PENDIENTE', NULL, NULL, NULL),
(508, 48, 44, '1.00', '954.65', 'PENDIENTE', NULL, NULL, NULL),
(509, 48, 52, '2.00', '433.28', 'PENDIENTE', NULL, NULL, NULL),
(510, 48, 21, '2.00', '785.44', 'PENDIENTE', NULL, NULL, NULL),
(511, 48, 53, '1.00', '952.16', 'PENDIENTE', NULL, NULL, NULL),
(512, 48, 57, '6.00', '3013.02', 'PENDIENTE', NULL, NULL, NULL),
(513, 48, 24, '2.00', '1154.10', 'PENDIENTE', NULL, NULL, NULL);

--
-- Disparadores `order_request_details`
--
DELIMITER $$
CREATE TRIGGER `actualizar_precio_solicitud` AFTER UPDATE ON `order_request_details` FOR EACH ROW IF(new.quantity <> old.quantity) THEN
UPDATE order_requests SET estimated_price = estimated_price + (new.estimated_price*new.quantity) - (old.estimated_price*old.quantity) WHERE id = new.order_request_id;
END IF
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `aumentar_precio_solicitud` AFTER INSERT ON `order_request_details` FOR EACH ROW UPDATE order_requests SET estimated_price = estimated_price + (new.estimated_price*new.quantity) WHERE id = new.order_request_id
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_request_new_items`
--

CREATE TABLE `order_request_new_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_request_id` bigint(20) UNSIGNED NOT NULL,
  `new_item` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `measurement_unit_id` bigint(20) UNSIGNED NOT NULL,
  `brand` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `datasheet` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `image` varchar(2048) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `observation` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `permissions`
--

CREATE TABLE `permissions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `permissions`
--

INSERT INTO `permissions` (`id`, `name`, `guard_name`, `created_at`, `updated_at`) VALUES
(1, 'overseer.tractor-scheduling', 'overseer', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(2, 'asistent.index', 'asistent', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(3, 'operator.request-materials', 'operator', '2022-06-20 21:43:36', '2022-06-20 21:43:36'),
(4, 'planner.validate-request-materials', 'planner', '2022-06-20 21:43:36', '2022-06-20 21:43:36'),
(6, 'admin.user.index', 'admin', '2022-06-20 22:22:55', '2022-06-20 22:22:55');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abilities` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `pieza_simplificada`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `pieza_simplificada` (
`item_id` bigint(20) unsigned
,`part` varchar(255)
,`component_id` bigint(20) unsigned
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpiles`
--

CREATE TABLE `pre_stockpiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpile_details`
--

CREATE TABLE `pre_stockpile_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pre_stockpile` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `precio` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `released_stocks`
--

CREATE TABLE `released_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `released_stock_details`
--

CREATE TABLE `released_stock_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `movement` enum('INGRESO','SALIDA') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `operator_assigned_stock_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `released_stock_details`
--
DELIMITER $$
CREATE TRIGGER `acumular_stock_liberado` BEFORE INSERT ON `released_stock_details` FOR EACH ROW BEGIN
IF new.movement = "INGRESO" THEN
IF EXISTS(SELECT * FROM released_stocks WHERE item_id =  new.item_id AND warehouse_id = new.warehouse_id) THEN
UPDATE released_stocks SET quantity = quantity + new.quantity, price = price + new.price WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
ELSE
INSERT INTO released_stocks (item_id,quantity,price,warehouse_id) VALUES (new.item_id,new.quantity,new.price, new.warehouse_id);
END IF;
INSERT INTO operator_stock_details(user_id, item_id, movement, quantity, price, warehouse_id,state) VALUES (new.user_id, new.item_id, 'SALIDA', new.quantity, new.price, new.warehouse_id, 'LIBERADO');
/*-----------END INGRESO-------------------*/
ELSE
/*-----------BEGIN SALIDA-----------------*/
UPDATE released_stocks SET quantity = quantity - new.quantity, price = price - new.price  WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
/*----------------END SALIDA---------------*/
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `risks`
--

CREATE TABLE `risks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `risk` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `risks`
--

INSERT INTO `risks` (`id`, `risk`, `created_at`, `updated_at`) VALUES
(1, 'Provident sint ipsa blanditiis est facilis est dolorem.', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(2, 'Molestias laborum laborum consequatur sed aperiam atque accusantium.', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(3, 'Beatae possimus maxime beatae sed porro ab voluptatem non.', '2022-06-20 21:21:49', '2022-06-20 21:21:49'),
(4, 'Eos voluptates in in aspernatur ipsam voluptatem.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(5, 'Veniam at maxime eveniet quia.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(6, 'Nisi occaecati iste aut molestiae rerum quod occaecati.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(7, 'Assumenda deleniti et ad minima libero inventore excepturi aut.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(8, 'Repudiandae sed debitis non.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(9, 'Ut ut omnis voluptate repellendus.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(10, 'Qui minus ut quos et asperiores eos.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(11, 'Reprehenderit laudantium quidem facilis et.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(12, 'Est et est libero quisquam aut.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(13, 'Suscipit tempora distinctio aut et labore velit.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(14, 'Quos sit sed aut rem vero cum natus.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(15, 'Inventore ex et tempore assumenda dolorem vel eveniet.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(16, 'Aspernatur ab dolores nihil adipisci ut.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(17, 'Delectus dolores omnis molestiae corrupti.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(18, 'Atque sit fugit quo aut voluptates.', '2022-06-20 21:21:50', '2022-06-20 21:21:50'),
(19, 'Qui corrupti quia pariatur.', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(20, 'Possimus ex aspernatur ex et.', '2022-06-20 21:21:51', '2022-06-20 21:21:51');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `risk_task_order`
--

CREATE TABLE `risk_task_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `risk_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `guard_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id`, `name`, `guard_name`, `created_at`, `updated_at`) VALUES
(1, 'administrador', 'admin', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(2, 'asistente', 'asistent', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(3, 'operador', 'operator', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(4, 'planner', 'planner', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(5, 'supervisor', 'overseer', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(6, 'jefe', 'web', '2022-06-20 21:43:35', '2022-06-20 21:43:35');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `role_has_permissions`
--

CREATE TABLE `role_has_permissions` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `role_has_permissions`
--

INSERT INTO `role_has_permissions` (`permission_id`, `role_id`) VALUES
(1, 5),
(2, 2),
(3, 3),
(4, 4),
(6, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sedes`
--

CREATE TABLE `sedes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sede` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sedes`
--

INSERT INTO `sedes` (`id`, `code`, `sede`, `zone_id`, `created_at`, `updated_at`) VALUES
(1, '443763', 'quos', 1, '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '916024', 'eum', 1, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(3, '389512', 'quod', 2, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(4, '488295', 'facilis', 2, '2022-06-20 21:21:40', '2022-06-20 21:21:40');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payload` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('eOvIcKPflhK2wkAgEoM1xZZZUBCpGGuyIA1bptJO', 7, '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.115 Safari/537.36 OPR/88.0.4412.40', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiTXRHS0tyVVl2Wld2UjB5bFd3c08zNE5WVWNoOHZHa0pqemU4djdxNCI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjAzOiJodHRwOi8vc2lzdGVtYS9saXZld2lyZS9wcmV2aWV3LWZpbGUvU2liWWY2Yng3a2JabnNTQ3plVmNadDdIMEVyMFNsLW1ldGFSa0pmU1UxSFh6RTJNRE0zTlRRNE5EWXhNRGt1YW5Cbi0uanBnP2V4cGlyZXM9MTY1NjA3ODcwNSZzaWduYXR1cmU9MDMwNmIyODdlNTQ5ZjZhNmViOGE5YmE4NTM3MzcxOTlmZTk5OGRjNzc5NzkwM2QzYWE5YTZmZTQ4YjExYmNjNSI7fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjc7fQ==', 1656076944);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stockpiles`
--

CREATE TABLE `stockpiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pre_stockpile_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','RECHAZADO','ANULADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stockpile_details`
--

CREATE TABLE `stockpile_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `stockpile_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','RECHAZADO','ANULADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stocks`
--

CREATE TABLE `stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `systems`
--

CREATE TABLE `systems` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `system` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tasks`
--

CREATE TABLE `tasks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `task` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_time` decimal(8,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tasks`
--

INSERT INTO `tasks` (`id`, `task`, `component_id`, `estimated_time`, `created_at`, `updated_at`) VALUES
(1, 'Esse reprehenderit commodi pariatur quibusdam vitae enim odio.', 8, '35.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(2, 'Minus asperiores perferendis quia sequi autem.', 25, '123.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(3, 'Iusto officia tempore id dolore quia.', 14, '71.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(4, 'Aut est odio dolorum dolor qui dolorem.', 2, '57.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(5, 'Minus fugit voluptate non sit optio placeat.', 18, '113.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(6, 'Sit et voluptatum quis ullam rem voluptate aut.', 31, '107.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(7, 'Necessitatibus ut esse adipisci.', 9, '100.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(8, 'Consequatur non aliquam aspernatur quis.', 3, '164.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(9, 'Sed eius dolorem sequi fuga nihil.', 7, '140.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(10, 'Nisi vitae dolorum modi molestiae consequatur nisi quis molestiae.', 10, '130.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(11, 'Voluptatibus id alias ad rerum sint beatae sit voluptatem.', 9, '109.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(12, 'Cumque magnam et et eligendi.', 32, '60.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(13, 'Pariatur non qui provident dolores.', 1, '46.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(14, 'Velit doloremque saepe ipsum et temporibus vitae omnis.', 22, '46.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(15, 'Id possimus et sint blanditiis fugit accusamus ducimus.', 12, '58.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(16, 'Tenetur autem recusandae nam dicta alias.', 24, '92.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(17, 'Reprehenderit pariatur repellat voluptas et qui quis dolore dignissimos.', 18, '124.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(18, 'Amet blanditiis nesciunt veniam consequatur qui harum odio.', 23, '110.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(19, 'Placeat ullam quia enim pariatur sint delectus dolor.', 32, '105.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(20, 'Aut sit sed natus.', 15, '173.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(21, 'Qui et earum voluptatum ratione aut.', 7, '122.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(22, 'Officiis quo libero ut sapiente.', 7, '67.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(23, 'Libero dolor reiciendis ullam ut enim eos.', 8, '56.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(24, 'Atque nulla fugit voluptatem reiciendis recusandae culpa.', 7, '117.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(25, 'Molestiae vitae quia iste nemo harum.', 21, '109.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(26, 'Voluptas illo quia ullam.', 24, '46.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(27, 'Iure et reprehenderit molestiae.', 19, '88.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(28, 'Aut totam unde qui voluptatem deserunt quia ipsum.', 15, '112.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(29, 'Fugit iure occaecati quas alias itaque consequuntur perspiciatis.', 10, '150.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(30, 'Maiores in laborum molestias.', 31, '40.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(31, 'Commodi molestias magni fuga aspernatur.', 8, '72.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(32, 'Eius quam et esse accusamus accusantium.', 29, '50.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(33, 'Doloremque blanditiis amet ullam aut rerum quos et.', 17, '140.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(34, 'Laudantium omnis sed laboriosam et ut.', 32, '100.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(35, 'Earum dolorum quia sit sit voluptas.', 2, '73.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(36, 'Dolores debitis esse quia et dolores modi.', 26, '116.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(37, 'Animi est necessitatibus omnis omnis est dolor.', 34, '70.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(38, 'Excepturi laborum dolore ea et autem dignissimos.', 30, '121.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(39, 'Est minus accusantium deserunt et voluptatem nulla odio.', 23, '124.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(40, 'Qui deserunt corporis id ut impedit explicabo nihil quaerat.', 9, '160.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tractors`
--

CREATE TABLE `tractors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tractor_model_id` bigint(20) UNSIGNED NOT NULL,
  `tractor_number` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hour_meter` decimal(8,2) NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractors`
--

INSERT INTO `tractors` (`id`, `tractor_model_id`, `tractor_number`, `hour_meter`, `location_id`, `created_at`, `updated_at`) VALUES
(1, 1, '72307', '268.00', 1, '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(2, 1, '76737', '450.00', 1, '2022-06-20 21:22:03', '2022-06-24 13:00:49'),
(3, 1, '65116', '390.00', 2, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(4, 1, '76977', '414.00', 2, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(5, 2, '72317', '342.00', 3, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(6, 2, '67891', '79.00', 3, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(7, 2, '72448', '452.00', 4, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(8, 2, '09607', '406.00', 4, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(9, 3, '83610', '395.00', 5, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(10, 3, '06100', '434.00', 5, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(11, 3, '13556', '270.00', 6, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(12, 3, '55383', '20.00', 6, '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(13, 4, '15511', '293.00', 7, '2022-06-20 21:22:05', '2022-06-20 21:22:05'),
(14, 4, '22051', '58.00', 7, '2022-06-20 21:22:05', '2022-06-20 21:22:05'),
(15, 4, '86314', '384.00', 8, '2022-06-20 21:22:05', '2022-06-20 21:22:05'),
(16, 4, '62702', '469.00', 8, '2022-06-20 21:22:05', '2022-06-20 21:22:05');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tractor_models`
--

CREATE TABLE `tractor_models` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractor_models`
--

INSERT INTO `tractor_models` (`id`, `model`, `created_at`, `updated_at`) VALUES
(1, 'lznvofk', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(2, 'aywvrxo', '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(3, 'clztrwk', '2022-06-20 21:22:04', '2022-06-20 21:22:04'),
(4, 'dlbqqko', '2022-06-20 21:22:04', '2022-06-20 21:22:04');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tractor_reports`
--

CREATE TABLE `tractor_reports` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `tractor_id` bigint(20) UNSIGNED NOT NULL,
  `labor_id` bigint(20) UNSIGNED NOT NULL,
  `correlative` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` date NOT NULL,
  `shift` enum('MAÑANA','NOCHE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `hour_meter_start` decimal(8,2) NOT NULL,
  `hour_meter_end` decimal(8,2) NOT NULL,
  `hours` decimal(8,2) NOT NULL,
  `observations` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lote_id` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractor_reports`
--

INSERT INTO `tractor_reports` (`id`, `user_id`, `tractor_id`, `labor_id`, `correlative`, `date`, `shift`, `implement_id`, `hour_meter_start`, `hour_meter_end`, `hours`, `observations`, `lote_id`, `is_canceled`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 1, 'sadada', '2022-06-23', 'MAÑANA', 1, '435.00', '450.00', '15.00', '', 1, 0, '2022-06-24 17:57:46', '2022-06-24 18:00:49');

--
-- Disparadores `tractor_reports`
--
DELIMITER $$
CREATE TRIGGER `actualizar_horas` AFTER UPDATE ON `tractor_reports` FOR EACH ROW BEGIN
    IF (new.is_canceled) THEN
    /*------Tractores----------*/
    UPDATE tractors SET hour_meter = hour_meter-old.hours, updated_at = CURRENT_TIMESTAMP WHERE id = new.tractor_id;
    /*--------Implementos-----------------*/
    UPDATE implements SET hours = hours-(old.hours)*0.85, updated_at = CURRENT_TIMESTAMP WHERE id = new.implement_id;
    ELSE
    /*------Tractores----------*/
    /*--Reducir al tractor antiguo---------*/
    UPDATE tractors SET hour_meter = hour_meter-old.hours, updated_at = CURRENT_TIMESTAMP WHERE id = old.tractor_id;
    /*---------Aumentar al tractor nuevo---------*/
    UPDATE tractors SET hour_meter = hour_meter+new.hours, updated_at = CURRENT_TIMESTAMP WHERE id = new.tractor_id;
    /*--------Implementos-----------------*/
    /*--Disminuir al implemento antiguo---*/
    UPDATE implements SET hours = hours-(old.hours*0.85), updated_at = CURRENT_TIMESTAMP WHERE id = old.implement_id;
    /*--Aumentar al implemento nuevo---*/
    UPDATE implements SET hours = hours+(new.hours)*0.85, updated_at = CURRENT_TIMESTAMP WHERE id = new.implement_id;
    END IF;
    END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `aumentar_horas` AFTER INSERT ON `tractor_reports` FOR EACH ROW BEGIN
    /*------Tractores----------*/
    UPDATE tractors SET hour_meter = hour_meter+new.hours, updated_at = CURRENT_TIMESTAMP WHERE id = new.tractor_id;
    /*--------Implementos-----------------*/
    UPDATE implements SET hours = hours+(new.hours)*0.85, updated_at = CURRENT_TIMESTAMP WHERE id = new.implement_id;
    END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tractor_schedulings`
--

CREATE TABLE `tractor_schedulings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `labor_id` bigint(20) UNSIGNED NOT NULL,
  `tractor_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `shift` enum('MAÑANA','NOCHE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `lote_id` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractor_schedulings`
--

INSERT INTO `tractor_schedulings` (`id`, `user_id`, `labor_id`, `tractor_id`, `implement_id`, `date`, `shift`, `lote_id`, `is_canceled`, `created_at`, `updated_at`) VALUES
(1, 7, 2, 7, 7, '2022-06-25', 'MAÑANA', 7, 1, '2022-06-24 17:07:11', '2022-06-24 17:08:20'),
(2, 8, 1, 7, 8, '2022-06-25', 'MAÑANA', 7, 0, '2022-06-24 17:07:23', '2022-06-24 17:07:23'),
(3, 5, 1, 5, 5, '2022-06-25', 'NOCHE', 5, 0, '2022-06-24 17:07:42', '2022-06-24 17:08:11'),
(4, 6, 4, 5, 6, '2022-06-25', 'NOCHE', 5, 0, '2022-06-24 17:07:51', '2022-06-24 17:07:51'),
(5, 5, 3, 5, 5, '2022-06-25', 'MAÑANA', 5, 1, '2022-06-24 17:37:42', '2022-06-24 17:40:25');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lastname` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `two_factor_secret` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `two_factor_recovery_codes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `two_factor_confirmed_at` timestamp NULL DEFAULT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `current_team_id` bigint(20) UNSIGNED DEFAULT NULL,
  `profile_photo_path` varchar(2048) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `code`, `name`, `lastname`, `location_id`, `email`, `email_verified_at`, `password`, `two_factor_secret`, `two_factor_recovery_codes`, `two_factor_confirmed_at`, `is_admin`, `remember_token`, `current_team_id`, `profile_photo_path`, `created_at`, `updated_at`) VALUES
(1, '777269', 'Mr. Ford Vandervort', 'Kunze', 1, 'roob.brianne@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '9qbcg7etDUazjid2a1WnwCiA2DAYd6bQZ0bFlxOGd6bdtq9vUzYTO0X3q59R', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '213312', 'Birdie Waelchi', 'Walker', 1, 'ernser.caden@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'zuqVwejbr3aTIFNjQbxmZay9UCXghe6TF7IaxSyPVrHckyhrRRnFQrbB4nwF', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '109931', 'Randi Leuschke', 'Cormier', 2, 'amaya.feeney@example.org', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'uq6E5hTmHTAhPCIyjWdMZmibZaDYvIDMYCli6WpEe57WJL1jtIBFEbk9R8sW', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '854140', 'Dr. Levi Feest', 'Ondricka', 2, 'woodrow.bogan@example.com', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'nRtVWucswjxIf5asU5m3CIbkkUkmy8aBlnBhLP717c83gohWPlJ3ThIVTOmA', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '912055', 'Erwin Green', 'Heidenreich', 3, 'hbeatty@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'JQIrgQxqEDHQWGQsEwTeZeBm54zyMfZXkk0IZiyecTqYXHMe6QCIFdyhy7Ij', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '502387', 'Bella Block', 'Bashirian', 3, 'sibyl08@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'SuqJiAy8in0Buwrj1x8QbyIifgeAk2ZjfBtdzIzGvU7AfmBsfji66BbmsZSU', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '981787', 'Jaylon Prosacco', 'Langosh', 4, 'pleuschke@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'NXHHGbjAGN', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '588440', 'Irving Strosin', 'Langosh', 4, 'mercedes57@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '2KTwtjcuXq', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '454006', 'Margarett Heller', 'Cruickshank', 5, 'oconner.sydnie@example.org', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'GvbEM8VRr6', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(10, '916293', 'Dr. Ryder Gutmann V', 'McLaughlin', 5, 'dprice@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'i7IJ3Zi3g6', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(11, '985395', 'Eldora Considine DVM', 'Bashirian', 6, 'dedric.herman@example.net', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'mm9bEziZrO', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '500276', 'Kali Heidenreich', 'Mills', 6, 'carrie.lebsack@example.net', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'JwmMsbBoeM', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '645058', 'Mr. Zachery Hoeger', 'Fadel', 7, 'xkoelpin@example.org', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '7IksTELjOl', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '650494', 'Chauncey Cummings III', 'Gaylord', 7, 'doug54@example.org', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '0bdjgP8SoL', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(15, '057018', 'Meda Bode', 'Lynch', 8, 'garrison42@example.com', '2022-06-20 21:21:41', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'p93dRjOOBD', NULL, NULL, '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '266459', 'Carrie Haley', 'Wolf', 8, 'kathleen72@example.net', '2022-06-20 21:21:41', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'j6TyHWP4T1', NULL, NULL, '2022-06-20 21:21:41', '2022-06-20 21:21:41');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `warehouses`
--

CREATE TABLE `warehouses` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `warehouse` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `warehouses`
--

INSERT INTO `warehouses` (`id`, `code`, `warehouse`, `location_id`, `created_at`, `updated_at`) VALUES
(1, '358812', 'delectus', 8, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(2, '518707', 'culpa', 2, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(3, '564628', 'libero', 7, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(4, '597593', 'fuga', 5, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(5, '342722', 'dignissimos', 2, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(6, '487606', 'nesciunt', 2, '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(7, '716983', 'consequuntur', 8, '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(8, '209261', 'eveniet', 7, '2022-06-20 21:21:48', '2022-06-20 21:21:48');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_orders`
--

CREATE TABLE `work_orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `maintenance` enum('1','2','3') COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_details`
--

CREATE TABLE `work_order_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `observation` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_epps`
--

CREATE TABLE `work_order_epps` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `zones`
--

CREATE TABLE `zones` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `zones`
--

INSERT INTO `zones` (`id`, `code`, `zone`, `created_at`, `updated_at`) VALUES
(1, '176445', 'rerum', '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '678751', 'minima', '2022-06-20 21:21:39', '2022-06-20 21:21:39');

-- --------------------------------------------------------

--
-- Estructura para la vista `componentes_del_implemento`
--
DROP TABLE IF EXISTS `componentes_del_implemento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `componentes_del_implemento`  AS SELECT `c`.`id` AS `component_id`, `c`.`item_id` AS `item_id`, `c`.`component` AS `item`, `i`.`id` AS `implement_id` FROM (((`components` `c` join `component_implement_model` `cim` on(`c`.`id` = `cim`.`component_id`)) join `implements` `i` on(`i`.`implement_model_id` = `cim`.`implement_model_id`)) join `items` `it` on(`it`.`id` = `c`.`item_id`))  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `pieza_simplificada`
--
DROP TABLE IF EXISTS `pieza_simplificada`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `pieza_simplificada`  AS SELECT `p`.`item_id` AS `item_id`, `p`.`component` AS `part`, `c`.`item_id` AS `component_id` FROM ((`component_part_model` `cpm` join `components` `c` on(`c`.`id` = `cpm`.`component`)) join `components` `p` on(`p`.`id` = `cpm`.`part`))  ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `affected_movement`
--
ALTER TABLE `affected_movement`
  ADD PRIMARY KEY (`id`),
  ADD KEY `affected_movement_operator_stock_id_foreign` (`operator_stock_id`),
  ADD KEY `affected_movement_operator_stock_detail_id_foreign` (`operator_stock_detail_id`),
  ADD KEY `affected_movement_operator_assigned_stock_id_foreign` (`operator_assigned_stock_id`),
  ADD KEY `affected_movement_stock_id_foreign` (`stock_id`);

--
-- Indices de la tabla `brands`
--
ALTER TABLE `brands`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `brands_brand_unique` (`brand`);

--
-- Indices de la tabla `cecos`
--
ALTER TABLE `cecos`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cecos_code_unique` (`code`),
  ADD KEY `cecos_location_id_foreign` (`location_id`);

--
-- Indices de la tabla `ceco_allocation_amounts`
--
ALTER TABLE `ceco_allocation_amounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ceco_allocation_amounts_ceco_id_foreign` (`ceco_id`);

--
-- Indices de la tabla `ceco_details`
--
ALTER TABLE `ceco_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `ceco_details_ceco_id_foreign` (`ceco_id`),
  ADD KEY `ceco_details_user_id_foreign` (`user_id`),
  ADD KEY `ceco_details_implement_id_foreign` (`implement_id`),
  ADD KEY `ceco_details_item_id_foreign` (`item_id`),
  ADD KEY `ceco_details_stockpile_detail_id_foreign` (`stockpile_detail_id`);

--
-- Indices de la tabla `components`
--
ALTER TABLE `components`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `components_item_id_unique` (`item_id`),
  ADD UNIQUE KEY `components_component_unique` (`component`);

--
-- Indices de la tabla `component_implement`
--
ALTER TABLE `component_implement`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_implement_component_id_foreign` (`component_id`),
  ADD KEY `component_implement_implement_id_foreign` (`implement_id`);

--
-- Indices de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_implement_model_implement_model_id_foreign` (`implement_model_id`),
  ADD KEY `component_implement_model_component_id_implement_model_id_index` (`component_id`,`implement_model_id`);

--
-- Indices de la tabla `component_part`
--
ALTER TABLE `component_part`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_part_component_implement_id_foreign` (`component_implement_id`),
  ADD KEY `component_part_part_foreign` (`part`);

--
-- Indices de la tabla `component_part_model`
--
ALTER TABLE `component_part_model`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_part_model_part_foreign` (`part`),
  ADD KEY `component_part_model_component_part_index` (`component`,`part`);

--
-- Indices de la tabla `component_system`
--
ALTER TABLE `component_system`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_system_system_id_foreign` (`system_id`),
  ADD KEY `component_system_component_id_system_id_index` (`component_id`,`system_id`);

--
-- Indices de la tabla `crops`
--
ALTER TABLE `crops`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `crops_crop_unique` (`crop`);

--
-- Indices de la tabla `epps`
--
ALTER TABLE `epps`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `epps_epp_unique` (`epp`);

--
-- Indices de la tabla `epp_risk`
--
ALTER TABLE `epp_risk`
  ADD PRIMARY KEY (`id`),
  ADD KEY `epp_risk_risk_id_foreign` (`risk_id`),
  ADD KEY `epp_risk_epp_id_risk_id_index` (`epp_id`,`risk_id`);

--
-- Indices de la tabla `epp_work_order`
--
ALTER TABLE `epp_work_order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `epp_work_order_work_order_foreign` (`work_order`),
  ADD KEY `epp_work_order_epp_id_work_order_index` (`epp_id`,`work_order`);

--
-- Indices de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indices de la tabla `implements`
--
ALTER TABLE `implements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `implements_user_id_foreign` (`user_id`),
  ADD KEY `implements_location_id_foreign` (`location_id`),
  ADD KEY `implements_ceco_id_foreign` (`ceco_id`),
  ADD KEY `implements_implement_model_id_implement_number_index` (`implement_model_id`,`implement_number`);

--
-- Indices de la tabla `implement_models`
--
ALTER TABLE `implement_models`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `implement_models_implement_model_unique` (`implement_model`);

--
-- Indices de la tabla `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `items_sku_unique` (`sku`),
  ADD UNIQUE KEY `items_item_unique` (`item`),
  ADD KEY `items_brand_id_foreign` (`brand_id`),
  ADD KEY `items_measurement_unit_id_foreign` (`measurement_unit_id`);

--
-- Indices de la tabla `labors`
--
ALTER TABLE `labors`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `loans`
--
ALTER TABLE `loans`
  ADD PRIMARY KEY (`id`),
  ADD KEY `loans_lender_stock_id_foreign` (`lender_stock_id`),
  ADD KEY `loans_borrower_stock_id_foreign` (`borrower_stock_id`);

--
-- Indices de la tabla `locations`
--
ALTER TABLE `locations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `locations_code_unique` (`code`),
  ADD KEY `locations_sede_id_foreign` (`sede_id`);

--
-- Indices de la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `lotes_code_unique` (`code`),
  ADD KEY `lotes_location_id_foreign` (`location_id`);

--
-- Indices de la tabla `measurement_units`
--
ALTER TABLE `measurement_units`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `measurement_units_measurement_unit_unique` (`measurement_unit`),
  ADD UNIQUE KEY `measurement_units_abbreviation_unique` (`abbreviation`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `min_stocks`
--
ALTER TABLE `min_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `min_stocks_item_id_foreign` (`item_id`),
  ADD KEY `min_stocks_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `min_stock_details`
--
ALTER TABLE `min_stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `min_stock_details_item_id_foreign` (`item_id`),
  ADD KEY `min_stock_details_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `min_stock_details_user_id_foreign` (`user_id`);

--
-- Indices de la tabla `model_has_permissions`
--
ALTER TABLE `model_has_permissions`
  ADD PRIMARY KEY (`permission_id`,`model_id`,`model_type`),
  ADD KEY `model_has_permissions_model_id_model_type_index` (`model_id`,`model_type`);

--
-- Indices de la tabla `model_has_roles`
--
ALTER TABLE `model_has_roles`
  ADD PRIMARY KEY (`role_id`,`model_id`,`model_type`),
  ADD KEY `model_has_roles_model_id_model_type_index` (`model_id`,`model_type`);

--
-- Indices de la tabla `operator_assigned_stocks`
--
ALTER TABLE `operator_assigned_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_assigned_stocks_user_id_foreign` (`user_id`),
  ADD KEY `operator_assigned_stocks_item_id_foreign` (`item_id`),
  ADD KEY `operator_assigned_stocks_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_stocks_user_id_foreign` (`user_id`),
  ADD KEY `operator_stocks_item_id_foreign` (`item_id`),
  ADD KEY `operator_stocks_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_stock_details_user_id_foreign` (`user_id`),
  ADD KEY `operator_stock_details_item_id_foreign` (`item_id`),
  ADD KEY `operator_stock_details_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `operator_stock_details_order_request_detail_id_foreign` (`order_request_detail_id`);

--
-- Indices de la tabla `order_dates`
--
ALTER TABLE `order_dates`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `order_requests`
--
ALTER TABLE `order_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_requests_user_id_foreign` (`user_id`),
  ADD KEY `order_requests_implement_id_foreign` (`implement_id`),
  ADD KEY `order_requests_validate_by_foreign` (`validate_by`),
  ADD KEY `order_requests_order_date_id_foreign` (`order_date_id`);

--
-- Indices de la tabla `order_request_details`
--
ALTER TABLE `order_request_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_request_details_order_request_id_foreign` (`order_request_id`),
  ADD KEY `order_request_details_item_id_foreign` (`item_id`);

--
-- Indices de la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_request_new_items_order_request_id_foreign` (`order_request_id`),
  ADD KEY `order_request_new_items_measurement_unit_id_foreign` (`measurement_unit_id`);

--
-- Indices de la tabla `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indices de la tabla `permissions`
--
ALTER TABLE `permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `permissions_name_guard_name_unique` (`name`,`guard_name`);

--
-- Indices de la tabla `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`);

--
-- Indices de la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pre_stockpiles_user_id_foreign` (`user_id`),
  ADD KEY `pre_stockpiles_implement_foreign` (`implement`);

--
-- Indices de la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pre_stockpile_details_pre_stockpile_foreign` (`pre_stockpile`),
  ADD KEY `pre_stockpile_details_item_id_foreign` (`item_id`),
  ADD KEY `pre_stockpile_details_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `released_stocks`
--
ALTER TABLE `released_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `released_stocks_item_id_foreign` (`item_id`),
  ADD KEY `released_stocks_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `released_stock_details`
--
ALTER TABLE `released_stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `released_stock_details_user_id_foreign` (`user_id`),
  ADD KEY `released_stock_details_item_id_foreign` (`item_id`),
  ADD KEY `released_stock_details_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `released_stock_details_operator_assigned_stock_id_foreign` (`operator_assigned_stock_id`);

--
-- Indices de la tabla `risks`
--
ALTER TABLE `risks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `risks_risk_unique` (`risk`);

--
-- Indices de la tabla `risk_task_order`
--
ALTER TABLE `risk_task_order`
  ADD PRIMARY KEY (`id`),
  ADD KEY `risk_task_order_task_id_foreign` (`task_id`),
  ADD KEY `risk_task_order_risk_id_task_id_index` (`risk_id`,`task_id`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `roles_name_guard_name_unique` (`name`,`guard_name`);

--
-- Indices de la tabla `role_has_permissions`
--
ALTER TABLE `role_has_permissions`
  ADD PRIMARY KEY (`permission_id`,`role_id`),
  ADD KEY `role_has_permissions_role_id_foreign` (`role_id`);

--
-- Indices de la tabla `sedes`
--
ALTER TABLE `sedes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `sedes_code_unique` (`code`),
  ADD KEY `sedes_zone_id_foreign` (`zone_id`);

--
-- Indices de la tabla `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indices de la tabla `stockpiles`
--
ALTER TABLE `stockpiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stockpiles_pre_stockpile_id_foreign` (`pre_stockpile_id`),
  ADD KEY `stockpiles_user_id_foreign` (`user_id`),
  ADD KEY `stockpiles_implement_id_foreign` (`implement_id`),
  ADD KEY `stockpiles_work_order_id_foreign` (`work_order_id`),
  ADD KEY `stockpiles_ceco_id_foreign` (`ceco_id`);

--
-- Indices de la tabla `stockpile_details`
--
ALTER TABLE `stockpile_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stockpile_details_stockpile_id_foreign` (`stockpile_id`),
  ADD KEY `stockpile_details_item_id_foreign` (`item_id`),
  ADD KEY `stockpile_details_warehouse_id_foreign` (`warehouse_id`);

--
-- Indices de la tabla `stocks`
--
ALTER TABLE `stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stocks_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `stocks_item_id_warehouse_id_index` (`item_id`,`warehouse_id`);

--
-- Indices de la tabla `systems`
--
ALTER TABLE `systems`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `systems_system_unique` (`system`);

--
-- Indices de la tabla `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tasks_task_unique` (`task`),
  ADD KEY `tasks_component_id_foreign` (`component_id`);

--
-- Indices de la tabla `tractors`
--
ALTER TABLE `tractors`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tractors_location_id_foreign` (`location_id`),
  ADD KEY `tractors_tractor_model_id_tractor_number_index` (`tractor_model_id`,`tractor_number`);

--
-- Indices de la tabla `tractor_models`
--
ALTER TABLE `tractor_models`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tractor_models_model_unique` (`model`);

--
-- Indices de la tabla `tractor_reports`
--
ALTER TABLE `tractor_reports`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tractor_reports_correlative_unique` (`correlative`),
  ADD KEY `tractor_reports_user_id_foreign` (`user_id`),
  ADD KEY `tractor_reports_tractor_id_foreign` (`tractor_id`),
  ADD KEY `tractor_reports_labor_id_foreign` (`labor_id`),
  ADD KEY `tractor_reports_implement_id_foreign` (`implement_id`),
  ADD KEY `tractor_reports_lote_id_foreign` (`lote_id`);

--
-- Indices de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tractor_schedulings_user_id_foreign` (`user_id`),
  ADD KEY `tractor_schedulings_labor_id_foreign` (`labor_id`),
  ADD KEY `tractor_schedulings_tractor_id_foreign` (`tractor_id`),
  ADD KEY `tractor_schedulings_implement_id_foreign` (`implement_id`),
  ADD KEY `tractor_schedulings_lote_id_foreign` (`lote_id`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_code_unique` (`code`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indices de la tabla `warehouses`
--
ALTER TABLE `warehouses`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `warehouses_code_unique` (`code`),
  ADD UNIQUE KEY `warehouses_warehouse_unique` (`warehouse`),
  ADD KEY `warehouses_location_id_foreign` (`location_id`);

--
-- Indices de la tabla `work_orders`
--
ALTER TABLE `work_orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `work_orders_implement_id_foreign` (`implement_id`),
  ADD KEY `work_orders_user_id_foreign` (`user_id`),
  ADD KEY `work_orders_location_id_foreign` (`location_id`);

--
-- Indices de la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `work_order_details_work_order_id_foreign` (`work_order_id`),
  ADD KEY `work_order_details_task_id_foreign` (`task_id`);

--
-- Indices de la tabla `work_order_epps`
--
ALTER TABLE `work_order_epps`
  ADD PRIMARY KEY (`id`),
  ADD KEY `work_order_epps_work_order_id_foreign` (`work_order_id`),
  ADD KEY `work_order_epps_epp_id_foreign` (`epp_id`);

--
-- Indices de la tabla `zones`
--
ALTER TABLE `zones`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `zones_code_unique` (`code`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `affected_movement`
--
ALTER TABLE `affected_movement`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `brands`
--
ALTER TABLE `brands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT de la tabla `cecos`
--
ALTER TABLE `cecos`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `ceco_allocation_amounts`
--
ALTER TABLE `ceco_allocation_amounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT de la tabla `ceco_details`
--
ALTER TABLE `ceco_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `components`
--
ALTER TABLE `components`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT de la tabla `component_implement`
--
ALTER TABLE `component_implement`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `component_part`
--
ALTER TABLE `component_part`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `component_part_model`
--
ALTER TABLE `component_part_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `component_system`
--
ALTER TABLE `component_system`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `crops`
--
ALTER TABLE `crops`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `epps`
--
ALTER TABLE `epps`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `epp_risk`
--
ALTER TABLE `epp_risk`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `epp_work_order`
--
ALTER TABLE `epp_work_order`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `implements`
--
ALTER TABLE `implements`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `implement_models`
--
ALTER TABLE `implement_models`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `items`
--
ALTER TABLE `items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT de la tabla `labors`
--
ALTER TABLE `labors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `loans`
--
ALTER TABLE `loans`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `locations`
--
ALTER TABLE `locations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `lotes`
--
ALTER TABLE `lotes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `measurement_units`
--
ALTER TABLE `measurement_units`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT de la tabla `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT de la tabla `min_stocks`
--
ALTER TABLE `min_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `min_stock_details`
--
ALTER TABLE `min_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `operator_assigned_stocks`
--
ALTER TABLE `operator_assigned_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `order_dates`
--
ALTER TABLE `order_dates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `order_requests`
--
ALTER TABLE `order_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=49;

--
-- AUTO_INCREMENT de la tabla `order_request_details`
--
ALTER TABLE `order_request_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=514;

--
-- AUTO_INCREMENT de la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `permissions`
--
ALTER TABLE `permissions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `released_stocks`
--
ALTER TABLE `released_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `released_stock_details`
--
ALTER TABLE `released_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `risks`
--
ALTER TABLE `risks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `risk_task_order`
--
ALTER TABLE `risk_task_order`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `sedes`
--
ALTER TABLE `sedes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `stockpiles`
--
ALTER TABLE `stockpiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `stockpile_details`
--
ALTER TABLE `stockpile_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `stocks`
--
ALTER TABLE `stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `systems`
--
ALTER TABLE `systems`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT de la tabla `tractors`
--
ALTER TABLE `tractors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `tractor_models`
--
ALTER TABLE `tractor_models`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `tractor_reports`
--
ALTER TABLE `tractor_reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `work_orders`
--
ALTER TABLE `work_orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `work_order_epps`
--
ALTER TABLE `work_order_epps`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `zones`
--
ALTER TABLE `zones`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `affected_movement`
--
ALTER TABLE `affected_movement`
  ADD CONSTRAINT `affected_movement_operator_assigned_stock_id_foreign` FOREIGN KEY (`operator_assigned_stock_id`) REFERENCES `operator_assigned_stocks` (`id`),
  ADD CONSTRAINT `affected_movement_operator_stock_detail_id_foreign` FOREIGN KEY (`operator_stock_detail_id`) REFERENCES `operator_stock_details` (`id`),
  ADD CONSTRAINT `affected_movement_operator_stock_id_foreign` FOREIGN KEY (`operator_stock_id`) REFERENCES `operator_stocks` (`id`),
  ADD CONSTRAINT `affected_movement_stock_id_foreign` FOREIGN KEY (`stock_id`) REFERENCES `stocks` (`id`);

--
-- Filtros para la tabla `cecos`
--
ALTER TABLE `cecos`
  ADD CONSTRAINT `cecos_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`);

--
-- Filtros para la tabla `ceco_allocation_amounts`
--
ALTER TABLE `ceco_allocation_amounts`
  ADD CONSTRAINT `ceco_allocation_amounts_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`);

--
-- Filtros para la tabla `ceco_details`
--
ALTER TABLE `ceco_details`
  ADD CONSTRAINT `ceco_details_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
  ADD CONSTRAINT `ceco_details_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `ceco_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `ceco_details_stockpile_detail_id_foreign` FOREIGN KEY (`stockpile_detail_id`) REFERENCES `stockpile_details` (`id`),
  ADD CONSTRAINT `ceco_details_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `components`
--
ALTER TABLE `components`
  ADD CONSTRAINT `components_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`);

--
-- Filtros para la tabla `component_implement`
--
ALTER TABLE `component_implement`
  ADD CONSTRAINT `component_implement_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  ADD CONSTRAINT `component_implement_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`);

--
-- Filtros para la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  ADD CONSTRAINT `component_implement_model_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  ADD CONSTRAINT `component_implement_model_implement_model_id_foreign` FOREIGN KEY (`implement_model_id`) REFERENCES `implement_models` (`id`);

--
-- Filtros para la tabla `component_part`
--
ALTER TABLE `component_part`
  ADD CONSTRAINT `component_part_component_implement_id_foreign` FOREIGN KEY (`component_implement_id`) REFERENCES `component_implement` (`id`),
  ADD CONSTRAINT `component_part_part_foreign` FOREIGN KEY (`part`) REFERENCES `components` (`id`);

--
-- Filtros para la tabla `component_part_model`
--
ALTER TABLE `component_part_model`
  ADD CONSTRAINT `component_part_model_component_foreign` FOREIGN KEY (`component`) REFERENCES `components` (`id`),
  ADD CONSTRAINT `component_part_model_part_foreign` FOREIGN KEY (`part`) REFERENCES `components` (`id`);

--
-- Filtros para la tabla `component_system`
--
ALTER TABLE `component_system`
  ADD CONSTRAINT `component_system_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  ADD CONSTRAINT `component_system_system_id_foreign` FOREIGN KEY (`system_id`) REFERENCES `systems` (`id`);

--
-- Filtros para la tabla `epp_risk`
--
ALTER TABLE `epp_risk`
  ADD CONSTRAINT `epp_risk_epp_id_foreign` FOREIGN KEY (`epp_id`) REFERENCES `epps` (`id`),
  ADD CONSTRAINT `epp_risk_risk_id_foreign` FOREIGN KEY (`risk_id`) REFERENCES `risks` (`id`);

--
-- Filtros para la tabla `epp_work_order`
--
ALTER TABLE `epp_work_order`
  ADD CONSTRAINT `epp_work_order_epp_id_foreign` FOREIGN KEY (`epp_id`) REFERENCES `epps` (`id`),
  ADD CONSTRAINT `epp_work_order_work_order_foreign` FOREIGN KEY (`work_order`) REFERENCES `work_orders` (`id`);

--
-- Filtros para la tabla `implements`
--
ALTER TABLE `implements`
  ADD CONSTRAINT `implements_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
  ADD CONSTRAINT `implements_implement_model_id_foreign` FOREIGN KEY (`implement_model_id`) REFERENCES `implement_models` (`id`),
  ADD CONSTRAINT `implements_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `implements_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `items`
--
ALTER TABLE `items`
  ADD CONSTRAINT `items_brand_id_foreign` FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`),
  ADD CONSTRAINT `items_measurement_unit_id_foreign` FOREIGN KEY (`measurement_unit_id`) REFERENCES `measurement_units` (`id`);

--
-- Filtros para la tabla `loans`
--
ALTER TABLE `loans`
  ADD CONSTRAINT `loans_borrower_stock_id_foreign` FOREIGN KEY (`borrower_stock_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `loans_lender_stock_id_foreign` FOREIGN KEY (`lender_stock_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `locations`
--
ALTER TABLE `locations`
  ADD CONSTRAINT `locations_sede_id_foreign` FOREIGN KEY (`sede_id`) REFERENCES `sedes` (`id`);

--
-- Filtros para la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD CONSTRAINT `lotes_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`);

--
-- Filtros para la tabla `min_stocks`
--
ALTER TABLE `min_stocks`
  ADD CONSTRAINT `min_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `min_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `min_stock_details`
--
ALTER TABLE `min_stock_details`
  ADD CONSTRAINT `min_stock_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `min_stock_details_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `min_stock_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `model_has_permissions`
--
ALTER TABLE `model_has_permissions`
  ADD CONSTRAINT `model_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `model_has_roles`
--
ALTER TABLE `model_has_roles`
  ADD CONSTRAINT `model_has_roles_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `operator_assigned_stocks`
--
ALTER TABLE `operator_assigned_stocks`
  ADD CONSTRAINT `operator_assigned_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_assigned_stocks_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `operator_assigned_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD CONSTRAINT `operator_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_stocks_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `operator_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  ADD CONSTRAINT `operator_stock_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_stock_details_order_request_detail_id_foreign` FOREIGN KEY (`order_request_detail_id`) REFERENCES `order_request_details` (`id`),
  ADD CONSTRAINT `operator_stock_details_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `operator_stock_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `order_requests`
--
ALTER TABLE `order_requests`
  ADD CONSTRAINT `order_requests_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `order_requests_order_date_id_foreign` FOREIGN KEY (`order_date_id`) REFERENCES `order_dates` (`id`),
  ADD CONSTRAINT `order_requests_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `order_requests_validate_by_foreign` FOREIGN KEY (`validate_by`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `order_request_details`
--
ALTER TABLE `order_request_details`
  ADD CONSTRAINT `order_request_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `order_request_details_order_request_id_foreign` FOREIGN KEY (`order_request_id`) REFERENCES `order_requests` (`id`);

--
-- Filtros para la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  ADD CONSTRAINT `order_request_new_items_measurement_unit_id_foreign` FOREIGN KEY (`measurement_unit_id`) REFERENCES `measurement_units` (`id`),
  ADD CONSTRAINT `order_request_new_items_order_request_id_foreign` FOREIGN KEY (`order_request_id`) REFERENCES `order_requests` (`id`);

--
-- Filtros para la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  ADD CONSTRAINT `pre_stockpiles_implement_foreign` FOREIGN KEY (`implement`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `pre_stockpiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  ADD CONSTRAINT `pre_stockpile_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `pre_stockpile_details_pre_stockpile_foreign` FOREIGN KEY (`pre_stockpile`) REFERENCES `pre_stockpiles` (`id`),
  ADD CONSTRAINT `pre_stockpile_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `released_stocks`
--
ALTER TABLE `released_stocks`
  ADD CONSTRAINT `released_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `released_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `released_stock_details`
--
ALTER TABLE `released_stock_details`
  ADD CONSTRAINT `released_stock_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `released_stock_details_operator_assigned_stock_id_foreign` FOREIGN KEY (`operator_assigned_stock_id`) REFERENCES `operator_assigned_stocks` (`id`),
  ADD CONSTRAINT `released_stock_details_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `released_stock_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `risk_task_order`
--
ALTER TABLE `risk_task_order`
  ADD CONSTRAINT `risk_task_order_risk_id_foreign` FOREIGN KEY (`risk_id`) REFERENCES `risks` (`id`),
  ADD CONSTRAINT `risk_task_order_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`);

--
-- Filtros para la tabla `role_has_permissions`
--
ALTER TABLE `role_has_permissions`
  ADD CONSTRAINT `role_has_permissions_permission_id_foreign` FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_has_permissions_role_id_foreign` FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `sedes`
--
ALTER TABLE `sedes`
  ADD CONSTRAINT `sedes_zone_id_foreign` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`);

--
-- Filtros para la tabla `stockpiles`
--
ALTER TABLE `stockpiles`
  ADD CONSTRAINT `stockpiles_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
  ADD CONSTRAINT `stockpiles_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `stockpiles_pre_stockpile_id_foreign` FOREIGN KEY (`pre_stockpile_id`) REFERENCES `pre_stockpiles` (`id`),
  ADD CONSTRAINT `stockpiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `stockpiles_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

--
-- Filtros para la tabla `stockpile_details`
--
ALTER TABLE `stockpile_details`
  ADD CONSTRAINT `stockpile_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `stockpile_details_stockpile_id_foreign` FOREIGN KEY (`stockpile_id`) REFERENCES `stockpiles` (`id`),
  ADD CONSTRAINT `stockpile_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `stocks`
--
ALTER TABLE `stocks`
  ADD CONSTRAINT `stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `tasks`
--
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`);

--
-- Filtros para la tabla `tractors`
--
ALTER TABLE `tractors`
  ADD CONSTRAINT `tractors_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `tractors_tractor_model_id_foreign` FOREIGN KEY (`tractor_model_id`) REFERENCES `tractor_models` (`id`);

--
-- Filtros para la tabla `tractor_reports`
--
ALTER TABLE `tractor_reports`
  ADD CONSTRAINT `tractor_reports_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `tractor_reports_labor_id_foreign` FOREIGN KEY (`labor_id`) REFERENCES `labors` (`id`),
  ADD CONSTRAINT `tractor_reports_lote_id_foreign` FOREIGN KEY (`lote_id`) REFERENCES `lotes` (`id`),
  ADD CONSTRAINT `tractor_reports_tractor_id_foreign` FOREIGN KEY (`tractor_id`) REFERENCES `tractors` (`id`),
  ADD CONSTRAINT `tractor_reports_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  ADD CONSTRAINT `tractor_schedulings_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `tractor_schedulings_labor_id_foreign` FOREIGN KEY (`labor_id`) REFERENCES `labors` (`id`),
  ADD CONSTRAINT `tractor_schedulings_lote_id_foreign` FOREIGN KEY (`lote_id`) REFERENCES `lotes` (`id`),
  ADD CONSTRAINT `tractor_schedulings_tractor_id_foreign` FOREIGN KEY (`tractor_id`) REFERENCES `tractors` (`id`),
  ADD CONSTRAINT `tractor_schedulings_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `warehouses`
--
ALTER TABLE `warehouses`
  ADD CONSTRAINT `warehouses_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`);

--
-- Filtros para la tabla `work_orders`
--
ALTER TABLE `work_orders`
  ADD CONSTRAINT `work_orders_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `work_orders_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `work_orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  ADD CONSTRAINT `work_order_details_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`),
  ADD CONSTRAINT `work_order_details_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

--
-- Filtros para la tabla `work_order_epps`
--
ALTER TABLE `work_order_epps`
  ADD CONSTRAINT `work_order_epps_epp_id_foreign` FOREIGN KEY (`epp_id`) REFERENCES `epps` (`id`),
  ADD CONSTRAINT `work_order_epps_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `liberar_material_event` ON SCHEDULE EVERY 1 MONTH STARTS '2022-05-18 09:00:54' ON COMPLETION NOT PRESERVE DISABLE DO UPDATE operator_assigned_stocks SET state = "LIBERADO", quantity = 0, price = 0 WHERE DATE_ADD(updated_at, INTERVAL 3 MONTH) < CURRENT_TIMESTAMP AND quantity > 0$$

CREATE DEFINER=`root`@`localhost` EVENT `asignar_monto_ceco` ON SCHEDULE EVERY 1 MONTH STARTS '2022-06-01 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO UPDATE ceco_allocation_amounts SET caa.is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

CREATE DEFINER=`root`@`localhost` EVENT `Listar_materiales_pedido` ON SCHEDULE EVERY 1 DAY STARTS '2022-06-27 00:00:00' ON COMPLETION PRESERVE DISABLE DO BEGIN
/*-------Variables para la fecha para abrir el pedido--------*/
DECLARE fecha_solicitud INT;
DECLARE fecha_abrir_solicitud DATE;
/*-------Obtener la fecha para abrir el pedido-------*/
SELECT id,open_request INTO fecha_solicitud, fecha_abrir_solicitud FROM order_dates r WHERE r.state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
IF(fecha_abrir_solicitud <= NOW()) THEN
BEGIN
/*--------variables para detener el ciclo-----------*/
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final  INT DEFAULT 0;
/*-------------------------------------------------*/
/*---------variables para almacenar variables del componente----------*/
DECLARE pedido INT;  #order_request_id
DECLARE implemento INT;
DECLARE componente INT;
DECLARE responsable INT;
DECLARE item INT;
DECLARE tiempo_vida DECIMAL(8,2);
DECLARE horas DECIMAL(8,2);
DECLARE cantidad DECIMAL(8,2);
DECLARE precio_estimado DECIMAL(8,2);
/*------------------------------------------------------------------------*/
/*--------------variables para la pieza------------------------------------*/
DECLARE pieza INT;
DECLARE item_pieza INT;
DECLARE horas_pieza DECIMAL(8,2);
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza DECIMAL(8,2);
DECLARE precio_estimado_pieza DECIMAL(8,2);
/*------------------------------------------------------------------------------*/
/*---------Declarando cursores para iterar por cada componente y pieza-----------*/
DECLARE cur_comp CURSOR FOR SELECT i.id, c.id, c.item_id, c.lifespan, i.user_id, it.estimated_price FROM component_implement_model cim INNER JOIN implements i ON i.implement_model_id = cim.implement_model_id INNER JOIN components c ON c.id = cim.component_id INNER JOIN items it ON it.id = c.item_id;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
/*-----------------------------------------------------------------------------------*/
OPEN cur_comp;
	bucle:LOOP
    IF componente_final = 1 THEN
    	LEAVE bucle;
    END IF;
    FETCH cur_comp INTO implemento,componente,item,tiempo_vida,responsable,precio_estimado;
    /*--------------Obtener horas del componente-----------------------------------*/
    IF EXISTS(SELECT * FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE") THEN
    	SELECT hours INTO horas FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE" LIMIT 1;
    ELSE
    	SELECT 0 INTO horas;
    END IF;
    /*-----------------------------------------------------------*/
    /*-------Calcular la cantidad del pedido-------------------*/
    SELECT ROUND((336+horas)/tiempo_vida) INTO cantidad;
    /*-----------Verificar si se requiere el componente----------*/
    IF(cantidad > 0) THEN
    /*------------Verificar si existe la cabecera de la solicitud------*/
    	IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE") THEN
        	INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
        END IF;
    /*-----------Obteniendo la cabecera de la solicitud-------------------------*/
        SELECT id INTO pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" LIMIT 1;
    /*------Creando la solicitud del componente--------*/
    	INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (pedido,item,cantidad,precio_estimado);
    END IF;
    BEGIN
    /*-------Declarando cursor para piezas---------------------*/
    	DECLARE cur_part CURSOR FOR SELECT cpm.part,c.lifespan,c.item_id,it.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items it ON it.id = c.item_id WHERE cpm.component = componente;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
    /*--------------------------------------------------*/
    	OPEN cur_part;
        	bucle2:LOOP
            IF pieza_final = 1 THEN
            	LEAVE bucle2;
            END IF;
            FETCH cur_part INTO pieza,tiempo_vida_pieza,item_pieza,precio_estimado_pieza;
            /*--------------Obtener horas de la pieza-------------------------------*/
            IF EXISTS(SELECT * FROM component_part cp INNER JOIN component_implement ci ON ci.id = cp.component_implement_id WHERE ci.component_id = componente AND cp.part = pieza AND cp.state = "PENDIENTE") THEN
    			SELECT cp.hours INTO horas_pieza FROM component_part cp INNER JOIN component_implement ci ON ci.id = cp.component_implement_id WHERE ci.component_id = componente AND cp.part = pieza AND cp.state = "PENDIENTE" LIMIT 1;
    		ELSE
    			SELECT 0 INTO horas_pieza;
    		END IF;
            /*------------------------------------------------------------*/
            /*-------------Calcular la cantidad del pedido---------------------*/
            SELECT ROUND((336+horas_pieza)/tiempo_vida_pieza) INTO cantidad_pieza;
            /*----------Verificar si se requiere la pieza----------------------------*/
            IF(cantidad_pieza > 0) THEN
            /*----------Verificar si existe la cabecera de la solicitud-------------------------------*/
            IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE") THEN
        		INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
        	END IF;
            /*-------------Obteniendo la cabecera de la solicitud--------------------------------------------------*/
            SELECT id INTO pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" LIMIT 1;
            /*-------------Creando la solicitud de la pieza---------------------------------------------*/
            IF EXISTS(SELECT * FROM order_request_details r WHERE r.order_request_id = pedido AND r.item_id = item_pieza) THEN
            	UPDATE order_request_details r SET r.quantity = r.quantity + cantidad_pieza, r.estimated_price = r.estimated_price + precio_estimado_pieza WHERE r.order_request_id = pedido AND r.item_id = item_pieza;
            ELSE
            	INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (pedido,item_pieza,cantidad_pieza,precio_estimado_pieza);
            END IF;

            END IF;
            END LOOP bucle2;
            SELECT 0 INTO pieza_final;
        CLOSE cur_part;
    /*----------------------*/
    END;
    END LOOP bucle;
CLOSE cur_comp;
UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
END;
END IF;
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;