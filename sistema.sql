-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 08-07-2022 a las 21:22:31
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
            	UPDATE order_request_details r SET r.quantity = r.quantity + cantidad_pieza WHERE r.order_request_id = pedido AND r.item_id = item_pieza;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `cerrarPedido` ()   BEGIN
/*---Variables para la fecha para cerrar el pedido----------*/
DECLARE fecha_solicitud INT;
DECLARE fecha_cerrar_solicitud DATE;
/*-------Obtener la fecha para cerrar el pedido-------*/
SELECT id,close_request INTO fecha_solicitud, fecha_cerrar_solicitud FROM order_dates r WHERE r.state = "ABIERTO" ORDER BY open_request ASC LIMIT 1;
/*----Validar la fecha de cierre de pedido-----------*/
IF(fecha_cerrar_solicitud <= NOW()) THEN
/*--------Cerrar pedido----------------*/
UPDATE order_dates SET state = "CERRADO" WHERE state = "ABIERTO" LIMIT 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_mantenimientos_programados` ()   BEGIN
/*-----------VARIABLES PARA DETENER CICLOS--------------*/
DECLARE material_final INT DEFAULT 0;
DECLARE implemento_final INT DEFAULT 0;
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final INT DEFAULT 0;
DECLARE tarea_final INT DEFAULT 0;
/*--------------VARIABLES CABECERA ORDEN DE TRABAJO-------------------*/
DECLARE implemento INT;
DECLARE responsable INT;
DECLARE ubicacion INT;
DECLARE fecha INT;
/*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
DECLARE orden_trabajo INT;
DECLARE tarea INT;
DECLARE componente_del_implemento INT;
DECLARE pieza_del_componente INT;
/*--------------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO------------------------*/
DECLARE modelo_del_implemento INT;
/*--------------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE---------*/
DECLARE componente INT;
DECLARE horas_componente DECIMAL(8,2);
DECLARE tiempo_vida_componente DECIMAL(8,2);
DECLARE cantidad_componente INT;
DECLARE item_componente INT;
/*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
DECLARE pieza INT;
DECLARE horas_pieza DECIMAL(8,2);
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza INT;
DECLARE item_pieza INT;
/*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id FROM implements;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
/*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
OPEN cursor_implementos;
    bucle_implementos:LOOP
        IF implemento_final = 1 THEN
            LEAVE bucle_implementos;
        END IF;
    /*--OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ----------------------*/
        FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable,ubicacion;
    /*-----------CREAR LA CABECERA DE ORDEN DE TRABAJO SI NO HAY EN LOS SIGUIENTES 3 DÍAS---------------*/
        IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE" AND date <= DATE_ADD(NOW(),INTERVAL 3 DAY)) THEN
            INSERT INTO work_orders (implement_id,user_id,location_id,date,maintenance) VALUES(implemento,responsable,ubicacion,DATE_ADD(NOW(),INTERVAL 3 DAY),1);
        /*-----------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------*/
            SELECT id INTO orden_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE";
    /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
            BEGIN
                DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                /*------------ABRIR CURSOR COMPONENTES---------------*/
                OPEN cursor_componentes;
                    bucle_componentes:LOOP
                        IF componente_final = 1 THEN
                            LEAVE bucle_componentes;
                        END IF;
                        /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                        FETCH cursor_componentes INTO componente;
                        /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                        IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                            INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                        END IF;
                        /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                        SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                        /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                        SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                        /*---------------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DIAS-----------------------------------*/
                        SELECT FLOOR((horas_componente+24)/tiempo_vida_componente) INTO cantidad_componente;
                        /*---------------TAREA DE RECAMBIO SI LO NECESITA-------------------------------*/
                        IF(cantidad_componente > 0) THEN
                            /*-----------OBTENER TAREA DE RECAMBIO DEL COMPONENTE----------------------*/
                            SELECT id INTO tarea FROM tasks WHERE component_id = componente AND task = "RECAMBIO" LIMIT 1;
                            /*-----------CREAR TAREA DE RECAMBIO PARA EL COMPONENTE---------------------*/
                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "RECOMENDADO" AND component_implement_id = componente_del_implemento) THEN
                                INSERT INTO work_order_details (work_order_id,task_id,state,component_implement_id ) VALUES (orden_trabajo,tarea,"RECOMENDADO",componente_del_implemento);
                            END IF;
                            /*------------MARCAR COMO NO VALIDADO HASTA QUE EL SUPERVISOR LO APRUEBE O LO RECHACE-------------*/
                            IF NOT EXISTS(SELECT * FROM work_orders WHERE id = orden_trabajo AND state = "NO VALIDADO") THEN
                                UPDATE work_orders SET state = "NO VALIDADO" WHERE id = orden_trabajo;
                            END IF;
                            /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                        /*----------------RUTINARIO SI NO NECESITA RECAMBIO----------------------------*/
                        ELSE
                            /*------------CURSOR PARA CREAR EL RUTINARIO POR CADA COMPONENTE----------------*/
                            BEGIN
                                DECLARE cursor_componente_tareas CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND task <> "RECAMBIO";
                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                /*--------ABRIR CURSOR DE TAREAS DEL COMPONENTE------------------------------*/
                                OPEN cursor_componente_tareas;
                                    bucle_componente_tareas:LOOP
                                        IF tarea_final = 1 THEN
                                            LEAVE bucle_componente_tareas;
                                        END IF;
                                        /*----------------OBTENER TAREA DEL COMPONENTE-----------------------------------------------*/
                                        FETCH cursor_componente_tareas INTO tarea;
                                        /*-------------INSERTAR RUTINARIO DE TAREAS EN EL DETALLE DE LA ORDEN DE TRABAJO-----------------------*/
                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "ACEPTADO" AND component_implement_id = componente_del_implemento) THEN
                                            INSERT INTO work_order_details (work_order_id,task_id,component_implement_id ) VALUES (orden_trabajo,tarea,componente_del_implemento);
                                        END IF;
                                        IF EXISTS(SELECT * FROM task_required_materials WHERE task_id = tarea) THEN
                                            BEGIN
                                                DECLARE cursor_materiales CURSOR FOR SELECT item_id FROM task_required_materials WHERE task_id = tarea;
                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                OPEN cursor_materiales;
                                                    bucle_materiales:LOOP
                                                        IF material_final = 1 THEN
                                                            LEAVE bucle_materiales;
                                                        END IF;
                                                        FETCH cursor_materiales INTO item_componente;
                                                        INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                                                    END LOOP bucle_materiales;
                                                CLOSE cursor_materiales;
                                                SELECT 0 INTO material_final;
                                            END;
                                        END IF;
                                    END LOOP bucle_componente_tareas;
                                CLOSE cursor_componente_tareas;
                                /*------------PONER TAREA FINAL A 0----------------------------------------*/
                                SELECT 0 INTO tarea_final;
                            END;
                            /*-----------FIN DEL RUTNARIO DEL COMPONENTE-------------------------------------*/
                            /*-------------INICIO DE LAS TAREAS DE LA PIEZA---------------------------------*/
                            /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                            BEGIN
                                DECLARE cursor_piezas CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                OPEN cursor_piezas;
                                    bucle_piezas:LOOP
                                        IF pieza_final = 1 THEN
                                            LEAVE bucle_piezas;
                                        END IF;
                                        /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                        FETCH cursor_piezas INTO pieza;
                                        /*----------------COMPROBAR SI EXISTE LA PEIZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                        IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                            INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                        END IF;
                                        /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                        SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                        /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                        SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                        /*---------------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DIAS-----------------------------------*/
                                        SELECT FLOOR((horas_pieza+24)/tiempo_vida_pieza) INTO cantidad_pieza;
                                        /*---------------TAREA DE RECAMBIO SI LO NECESITA-------------------------------*/
                                        IF(cantidad_pieza > 0) THEN
                                            /*-----------OBTENER TAREA DE RECAMBIO DE LA PIEZA----------------------*/
                                            SELECT id INTO tarea FROM tasks WHERE component_id = pieza AND task = "RECAMBIO" LIMIT 1;
                                            /*-----------CREAR TAREA DE RECAMBIO PARA LA PIEZA---------------------*/
                                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "RECOMENDADO" AND component_part_id = pieza_del_componente) THEN
                                                INSERT INTO work_order_details (work_order_id,task_id,state,component_part_id) VALUES (orden_trabajo,tarea,"RECOMENDADO",pieza_del_componente);
                                            END IF;
                                            /*-----------MARCAR COMO NO VALIDADO HASTA QUE EL SUPERVISOR LO APRUEBE O LO RECHACE-----------------*/
                                            IF NOT EXISTS(SELECT * FROM work_orders WHERE id = orden_trabajo AND state = "NO VALIDADO") THEN
                                                UPDATE work_orders SET state = "NO VALIDADO" WHERE id = orden_trabajo;
                                            END IF;
                                            /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                        /*--------------RUTINARIO SI NO NECESITA RECAMBIO---------------------------------*/
                                        ELSE
                                        /*--------------CURSOR PARA CREAR EL RUTINARIO DE CADA COMPONENTE-----------------*/
                                            BEGIN
                                                DECLARE cursor_pieza_tareas CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND task <> "RECAMBIO";
                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                /*--------ABRIR CURSOR DE TAREAS DEL COMPONENTE------------------------------*/
                                                OPEN cursor_pieza_tareas;
                                                    bucle_pieza_tareas:LOOP
                                                        IF tarea_final = 1 THEN
                                                            LEAVE bucle_pieza_tareas;
                                                        END IF;
                                                        /*----------------OBTENER TAREA DE LA PIEZA-----------------------------------------------*/
                                                        FETCH cursor_pieza_tareas INTO tarea;
                                                        /*-------------INSERTAR RUTINARIO DE TAREAS EN EL DETALLE DE LA ORDEN DE TRABAJO-----------------------*/
                                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "ACEPTADO" AND component_part_id  = pieza_del_componente) THEN
                                                            INSERT INTO work_order_details (work_order_id,task_id,component_part_id) VALUES (orden_trabajo,tarea,pieza_del_componente);
                                                        END IF;
                                                        IF EXISTS(SELECT * FROM task_required_materials WHERE task_id = tarea) THEN
                                                            BEGIN
                                                                DECLARE cursor_materiales CURSOR FOR SELECT item_id FROM task_required_materials WHERE task_id = tarea;
                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                OPEN cursor_materiales;
                                                                    bucle_materiales:LOOP
                                                                        IF material_final = 1 THEN
                                                                            LEAVE bucle_materiales;
                                                                        END IF;
                                                                        FETCH cursor_materiales INTO item_pieza;
                                                                        INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                                                    END LOOP bucle_materiales;
                                                                CLOSE cursor_materiales;
                                                                SELECT 0 INTO material_final;
                                                            END;
                                                        END IF;
                                                    END LOOP bucle_pieza_tareas;
                                                CLOSE cursor_pieza_tareas;
                                                /*------------PONER TAREA FINAL A 0----------------------------------------*/
                                                SELECT 0 INTO tarea_final;
                                            END;
                                        END IF;
                                    END LOOP bucle_piezas;
                                CLOSE cursor_piezas;
                                /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                SELECT 0 INTO pieza_final;
                            END;
                        END IF;
                    END LOOP bucle_componentes;
                CLOSE cursor_componentes;
                /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                SELECT 0 INTO componente_final;
            END;
        END IF;
    END LOOP bucle_implementos;
CLOSE cursor_implementos;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ssasd` (IN `tarea` INT)   BEGIN
		DECLARE epp_final INT DEFAULT 0;
        DECLARE equipo_proteccion INT;
        DECLARE cur_epp CURSOR FOR SELECT er.epp_id FROM risk_task_order rt INNER JOIN epp_risk er ON er.risk_id = rt.risk_id WHERE rt.task_id = tarea GROUP BY er.epp_id;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET epp_final = 1;
        /*-------Abrir cursor para iterar epps--------------------------------------------*/
        OPEN cur_epp;
            bucle:LOOP
                IF epp_final = 1 THEN
                    LEAVE bucle;
                END IF;
                FETCH cur_epp INTO equipo_proteccion;
                	SELECT equipo_proteccion;
            END LOOP bucle;
        CLOSE cur_epp;
    END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `tarea_reponer_componentes` ()   BEGIN
DECLARE componente INT;
DECLARE componente_final INT DEFAULT 0;
DECLARE cur_componente CURSOR FOR SELECT id FROM components;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
OPEN cur_componente;
	bucle:LOOP
    IF componente_final = 1 THEN
    	LEAVE bucle;
  	END IF;
    FETCH cur_componente INTO componente;
    IF NOT EXISTS(SELECT * FROM tasks WHERE component_id = componente AND task = "Reponer") THEN
    INSERT INTO tasks (task,component_id,estimated_time) VALUES ('Reponer',componente,15);
    END IF;
    END LOOP bucle;
CLOSE cur_componente;
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

--
-- Volcado de datos para la tabla `affected_movement`
--

INSERT INTO `affected_movement` (`id`, `operator_stock_id`, `operator_stock_detail_id`, `operator_assigned_stock_id`, `stock_id`) VALUES
(1, 2, 2, 1, 2),
(2, 2, 3, 2, 2),
(3, 3, 4, 3, 3),
(4, 4, 5, 4, 4),
(5, 5, 6, 5, 5),
(6, 6, 7, 6, 6),
(7, 7, 8, 7, 7),
(8, 7, 9, 8, 7),
(9, 8, 10, 9, 7),
(10, 8, 11, 10, 7),
(11, 8, 12, 11, 7),
(12, 8, 13, 12, 7),
(13, 8, 14, 13, 7),
(14, 8, 15, 14, 7),
(15, 8, 16, 15, 7),
(16, 8, 17, 16, 7),
(17, 9, 18, 17, 8),
(18, 9, 19, 18, 8);

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
(30, 'ad', '2022-06-20 21:21:43', '2022-06-20 21:21:43'),
(39, 'suryuu', '2022-06-30 22:21:26', '2022-06-30 22:21:26'),
(40, 'banpresto', '2022-06-30 22:22:14', '2022-06-30 22:22:14'),
(41, 'figma', '2022-07-01 09:30:18', '2022-07-01 09:30:18'),
(42, 'pop up', '2022-07-01 09:37:51', '2022-07-01 09:37:51'),
(43, 'crossfire', '2022-07-01 20:48:48', '2022-07-01 20:48:48');

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
  `system_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_part` tinyint(1) NOT NULL,
  `lifespan` decimal(8,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `components`
--

INSERT INTO `components` (`id`, `item_id`, `component`, `system_id`, `is_part`, `lifespan`, `created_at`, `updated_at`) VALUES
(1, 2, 'fenphxjv', 5, 0, '4829.00', NULL, NULL),
(2, 3, 'uodoiizm', NULL, 1, '258.00', NULL, NULL),
(3, 4, 'inqxlhvr', NULL, 1, '344.00', NULL, NULL),
(4, 9, 'ynxsloty', NULL, 1, '443.00', NULL, NULL),
(5, 10, 'vdmjztzo', 1, 0, '1844.00', NULL, NULL),
(6, 13, 'xazvmvok', 1, 0, '929.00', NULL, NULL),
(7, 15, 'malgbbvu', NULL, 1, '411.00', NULL, NULL),
(8, 17, 'iinqimeg', 6, 0, '2765.00', NULL, NULL),
(9, 18, 'jrnuwort', 3, 0, '1495.00', NULL, NULL),
(10, 19, 'glqsvril', 6, 0, '4180.00', NULL, NULL),
(11, 21, 'qrrmsgax', NULL, 1, '142.00', NULL, NULL),
(12, 23, 'tqgvkyjd', 4, 0, '4542.00', NULL, NULL),
(13, 24, 'hnvixqmu', NULL, 1, '346.00', NULL, NULL),
(14, 25, 'nnxqjpih', NULL, 1, '367.00', NULL, NULL),
(15, 26, 'ztypliaa', NULL, 1, '297.00', NULL, NULL),
(16, 27, 'uufgzlwz', 4, 0, '3841.00', NULL, NULL),
(17, 29, 'sjepvnhk', NULL, 1, '30.00', NULL, NULL),
(18, 32, 'vzjkkcej', NULL, 1, '496.00', NULL, NULL),
(19, 33, 'qyltgffe', 4, 0, '3903.00', NULL, NULL),
(20, 34, 'oozarwvm', 4, 0, '4639.00', NULL, NULL),
(21, 39, 'uydbihgf', 4, 0, '1485.00', NULL, NULL),
(22, 43, 'pvphmrrt', 5, 0, '3510.00', NULL, NULL),
(23, 44, 'odzxmwyq', NULL, 1, '310.00', NULL, NULL),
(24, 45, 'spnpzerr', 2, 0, '4948.00', NULL, NULL),
(25, 46, 'abqkzfka', 1, 0, '452.00', NULL, NULL),
(26, 47, 'tdtlgqur', 6, 0, '2414.00', NULL, NULL),
(27, 48, 'omzaqrnd', 4, 0, '717.00', NULL, NULL),
(28, 51, 'igkjtofr', 4, 0, '1342.00', NULL, NULL),
(29, 52, 'lxlrfbxf', NULL, 1, '456.00', NULL, NULL),
(30, 53, 'tjhhvizw', NULL, 1, '377.00', NULL, NULL),
(31, 54, 'fubvgxmw', NULL, 1, '18.00', NULL, NULL),
(32, 55, 'upvgdrsm', 5, 0, '4575.00', NULL, NULL),
(33, 57, 'peorviek', NULL, 1, '234.00', NULL, NULL),
(34, 59, 'qvjzldtw', 3, 0, '2974.00', NULL, NULL);

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
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_implement`
--

INSERT INTO `component_implement` (`id`, `component_id`, `implement_id`, `hours`, `state`, `created_at`, `updated_at`) VALUES
(1, 28, 1, '379.95', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(2, 8, 1, '379.95', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(3, 20, 1, '379.95', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(4, 28, 2, '382.50', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(5, 8, 2, '382.50', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(6, 20, 2, '382.50', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(7, 28, 3, '379.10', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(8, 8, 3, '379.10', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(9, 20, 3, '379.10', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(10, 28, 4, '255.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(11, 8, 4, '255.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(12, 20, 4, '255.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(13, 20, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(14, 19, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(15, 22, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(16, 20, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(17, 19, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(18, 22, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(19, 20, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(20, 19, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(21, 22, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(22, 20, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(23, 19, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(24, 22, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(25, 10, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(26, 5, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(27, 21, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(28, 10, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(29, 5, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(30, 21, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(31, 10, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(32, 5, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(33, 21, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(34, 10, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(35, 5, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(36, 21, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(37, 28, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(38, 27, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(39, 22, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(40, 28, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(41, 27, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(42, 22, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(43, 28, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(44, 27, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(45, 22, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(46, 28, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(47, 27, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(48, 22, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(49, 1, 1, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(50, 2, 1, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(51, 3, 1, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(52, 1, 2, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(53, 2, 2, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(54, 3, 2, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(55, 1, 3, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(56, 2, 3, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(57, 3, 3, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(58, 1, 4, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(59, 2, 4, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(60, 3, 4, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(61, 4, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(62, 5, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(63, 6, 5, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(64, 4, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(65, 5, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(66, 6, 6, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(67, 4, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(68, 5, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(69, 6, 7, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(70, 4, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(71, 5, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(72, 6, 8, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(73, 7, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(74, 8, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(75, 9, 9, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(76, 7, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(77, 8, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(78, 9, 10, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(79, 7, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(80, 8, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(81, 9, 11, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(82, 7, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(83, 8, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(84, 9, 12, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(85, 10, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(86, 11, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(87, 12, 13, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(88, 10, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(89, 11, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(90, 12, 14, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(91, 10, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(92, 11, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(93, 12, 15, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(94, 10, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(95, 11, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56'),
(96, 12, 16, '0.00', 'PENDIENTE', '2022-07-08 06:59:56', '2022-07-08 06:59:56');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_implement_model`
--

CREATE TABLE `component_implement_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `implement_model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_implement_model`
--

INSERT INTO `component_implement_model` (`id`, `component_id`, `implement_model_id`) VALUES
(8, 5, 3),
(2, 8, 1),
(7, 10, 3),
(5, 19, 2),
(3, 20, 1),
(4, 20, 2),
(9, 21, 3),
(6, 22, 2),
(12, 22, 4),
(11, 27, 4),
(1, 28, 1),
(10, 28, 4);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_part`
--

CREATE TABLE `component_part` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_implement_id` bigint(20) UNSIGNED NOT NULL,
  `part` bigint(20) UNSIGNED NOT NULL,
  `hours` decimal(8,2) NOT NULL DEFAULT 0.00,
  `state` enum('PENDIENTE','ORDENADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_part`
--

INSERT INTO `component_part` (`id`, `component_implement_id`, `part`, `hours`, `state`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '379.95', 'PENDIENTE', NULL, NULL),
(2, 1, 13, '379.95', 'PENDIENTE', NULL, NULL),
(3, 1, 33, '379.95', 'PENDIENTE', NULL, NULL),
(4, 2, 4, '379.95', 'PENDIENTE', NULL, NULL),
(5, 2, 11, '379.95', 'PENDIENTE', NULL, NULL),
(6, 2, 23, '379.95', 'PENDIENTE', NULL, NULL),
(7, 3, 4, '379.95', 'PENDIENTE', NULL, NULL),
(8, 3, 29, '379.95', 'PENDIENTE', NULL, NULL),
(9, 3, 33, '379.95', 'PENDIENTE', NULL, NULL),
(10, 7, 2, '379.10', 'PENDIENTE', NULL, NULL),
(11, 7, 13, '379.10', 'PENDIENTE', NULL, NULL),
(12, 7, 33, '379.10', 'PENDIENTE', NULL, NULL),
(13, 8, 4, '379.10', 'PENDIENTE', NULL, NULL),
(14, 8, 11, '379.10', 'PENDIENTE', NULL, NULL),
(15, 8, 23, '379.10', 'PENDIENTE', NULL, NULL),
(16, 9, 4, '379.10', 'PENDIENTE', NULL, NULL),
(17, 9, 29, '379.10', 'PENDIENTE', NULL, NULL),
(18, 9, 33, '379.10', 'PENDIENTE', NULL, NULL),
(19, 10, 2, '255.00', 'PENDIENTE', NULL, NULL),
(20, 10, 13, '255.00', 'PENDIENTE', NULL, NULL),
(21, 10, 33, '255.00', 'PENDIENTE', NULL, NULL),
(22, 11, 4, '255.00', 'PENDIENTE', NULL, NULL),
(23, 11, 11, '255.00', 'PENDIENTE', NULL, NULL),
(24, 11, 23, '255.00', 'PENDIENTE', NULL, NULL),
(25, 12, 4, '255.00', 'PENDIENTE', NULL, NULL),
(26, 12, 29, '255.00', 'PENDIENTE', NULL, NULL),
(27, 12, 33, '255.00', 'PENDIENTE', NULL, NULL),
(28, 4, 2, '382.50', 'PENDIENTE', NULL, NULL),
(29, 4, 13, '382.50', 'PENDIENTE', NULL, NULL),
(30, 4, 33, '382.50', 'PENDIENTE', NULL, NULL),
(31, 5, 4, '382.50', 'PENDIENTE', NULL, NULL),
(32, 5, 11, '382.50', 'PENDIENTE', NULL, NULL),
(33, 5, 23, '382.50', 'PENDIENTE', NULL, NULL),
(34, 6, 4, '382.50', 'PENDIENTE', NULL, NULL),
(35, 6, 29, '382.50', 'PENDIENTE', NULL, NULL),
(36, 6, 33, '382.50', 'PENDIENTE', NULL, NULL),
(37, 13, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(38, 13, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(39, 13, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(40, 14, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(41, 14, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(42, 14, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(43, 15, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(44, 15, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(45, 15, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(46, 16, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(47, 16, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(48, 16, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(49, 17, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(50, 17, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(51, 17, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(52, 18, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(53, 18, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(54, 18, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(55, 19, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(56, 19, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(57, 19, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(58, 20, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(59, 20, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(60, 20, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(61, 21, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(62, 21, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(63, 21, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(64, 22, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(65, 22, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(66, 22, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(67, 23, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(68, 23, 4, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(69, 23, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(70, 24, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(71, 24, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(72, 24, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(73, 25, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(74, 25, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(75, 25, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(76, 26, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(77, 26, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(78, 26, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(79, 27, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(80, 27, 17, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(81, 27, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(82, 28, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(83, 28, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(84, 28, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(85, 29, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(86, 29, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(87, 29, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(88, 30, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(89, 30, 17, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(90, 30, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(91, 31, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(92, 31, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(93, 31, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(94, 32, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(95, 32, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(96, 32, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(97, 33, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(98, 33, 17, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(99, 33, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(100, 34, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(101, 34, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(102, 34, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:38', '2022-07-08 07:24:38'),
(103, 35, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(104, 35, 7, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(105, 35, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(106, 36, 3, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(107, 36, 17, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(108, 36, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(109, 37, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(110, 37, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(111, 37, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(112, 38, 11, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(113, 38, 30, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(114, 38, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(115, 39, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(116, 39, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(117, 39, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(118, 40, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(119, 40, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(120, 40, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(121, 41, 11, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(122, 41, 30, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(123, 41, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(124, 42, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(125, 42, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(126, 42, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(127, 43, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(128, 43, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(129, 43, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(130, 44, 11, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(131, 44, 30, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(132, 44, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(133, 45, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(134, 45, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(135, 45, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(136, 46, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(137, 46, 13, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(138, 46, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(139, 47, 11, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(140, 47, 30, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(141, 47, 33, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(142, 48, 2, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(143, 48, 23, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39'),
(144, 48, 29, '0.00', 'PENDIENTE', '2022-07-08 07:24:39', '2022-07-08 07:24:39');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_part_model`
--

CREATE TABLE `component_part_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component` bigint(20) UNSIGNED NOT NULL,
  `part` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_part_model`
--

INSERT INTO `component_part_model` (`id`, `component`, `part`) VALUES
(3, 1, 2),
(1, 1, 13),
(2, 1, 31),
(4, 5, 2),
(5, 5, 7),
(6, 5, 13),
(9, 6, 7),
(8, 6, 15),
(7, 6, 30),
(11, 8, 4),
(10, 8, 11),
(12, 8, 23),
(15, 9, 3),
(13, 9, 11),
(14, 9, 29),
(17, 10, 7),
(18, 10, 29),
(16, 10, 33),
(19, 12, 2),
(20, 12, 13),
(21, 12, 23),
(24, 16, 18),
(23, 16, 23),
(22, 16, 29),
(26, 19, 3),
(25, 19, 4),
(27, 19, 13),
(28, 20, 4),
(29, 20, 29),
(30, 20, 33),
(31, 21, 3),
(33, 21, 17),
(32, 21, 33),
(34, 22, 2),
(35, 22, 23),
(36, 22, 29),
(38, 24, 3),
(39, 24, 13),
(37, 24, 14),
(42, 25, 2),
(41, 25, 15),
(40, 25, 30),
(45, 26, 2),
(43, 26, 30),
(44, 26, 33),
(46, 27, 11),
(47, 27, 30),
(48, 27, 33),
(50, 28, 2),
(49, 28, 13),
(51, 28, 33),
(54, 32, 2),
(53, 32, 4),
(52, 32, 23),
(56, 34, 3),
(57, 34, 31),
(55, 34, 33);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_work_order_detail`
--

CREATE TABLE `component_work_order_detail` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `work_order_detail_id` bigint(20) UNSIGNED NOT NULL,
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
  `risk_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `epp_risk`
--

INSERT INTO `epp_risk` (`id`, `epp_id`, `risk_id`) VALUES
(6, 1, 23),
(8, 2, 23),
(7, 3, 23),
(4, 4, 26),
(11, 5, 22),
(17, 6, 21),
(10, 7, 28),
(1, 8, 26),
(13, 9, 27),
(9, 10, 28),
(3, 11, 26),
(12, 12, 22),
(2, 13, 26),
(20, 14, 25),
(21, 15, 22),
(18, 16, 21),
(16, 16, 24),
(19, 17, 29),
(5, 18, 23),
(14, 19, 27),
(15, 20, 24);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epp_work_order`
--

CREATE TABLE `epp_work_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `epp_work_order`
--

INSERT INTO `epp_work_order` (`id`, `epp_id`, `work_order_id`) VALUES
(272, 1, 21),
(289, 1, 22),
(306, 1, 23),
(323, 1, 24),
(340, 1, 25),
(354, 1, 26),
(368, 1, 27),
(382, 1, 28),
(391, 1, 29),
(405, 1, 30),
(419, 1, 31),
(433, 1, 32),
(273, 2, 21),
(290, 2, 22),
(307, 2, 23),
(324, 2, 24),
(341, 2, 25),
(355, 2, 26),
(369, 2, 27),
(383, 2, 28),
(392, 2, 29),
(406, 2, 30),
(420, 2, 31),
(434, 2, 32),
(274, 3, 21),
(291, 3, 22),
(308, 3, 23),
(325, 3, 24),
(342, 3, 25),
(356, 3, 26),
(370, 3, 27),
(384, 3, 28),
(393, 3, 29),
(407, 3, 30),
(421, 3, 31),
(435, 3, 32),
(258, 4, 20),
(277, 4, 21),
(294, 4, 22),
(311, 4, 23),
(328, 4, 24),
(398, 4, 29),
(412, 4, 30),
(426, 4, 31),
(440, 4, 32),
(225, 5, 17),
(235, 5, 18),
(245, 5, 19),
(255, 5, 20),
(269, 5, 21),
(286, 5, 22),
(303, 5, 23),
(320, 5, 24),
(335, 5, 25),
(349, 5, 26),
(363, 5, 27),
(377, 5, 28),
(231, 6, 17),
(241, 6, 18),
(251, 6, 19),
(264, 6, 20),
(267, 6, 21),
(284, 6, 22),
(301, 6, 23),
(318, 6, 24),
(338, 6, 25),
(352, 6, 26),
(366, 6, 27),
(380, 6, 28),
(396, 6, 29),
(410, 6, 30),
(424, 6, 31),
(438, 6, 32),
(228, 7, 17),
(238, 7, 18),
(248, 7, 19),
(333, 7, 25),
(347, 7, 26),
(361, 7, 27),
(375, 7, 28),
(259, 8, 20),
(278, 8, 21),
(295, 8, 22),
(312, 8, 23),
(329, 8, 24),
(399, 8, 29),
(413, 8, 30),
(427, 8, 31),
(441, 8, 32),
(223, 9, 17),
(233, 9, 18),
(243, 9, 19),
(253, 9, 20),
(265, 9, 21),
(282, 9, 22),
(299, 9, 23),
(316, 9, 24),
(344, 9, 25),
(358, 9, 26),
(372, 9, 27),
(386, 9, 28),
(389, 9, 29),
(403, 9, 30),
(417, 9, 31),
(431, 9, 32),
(229, 10, 17),
(239, 10, 18),
(249, 10, 19),
(334, 10, 25),
(348, 10, 26),
(362, 10, 27),
(376, 10, 28),
(260, 11, 20),
(279, 11, 21),
(296, 11, 22),
(313, 11, 23),
(330, 11, 24),
(400, 11, 29),
(414, 11, 30),
(428, 11, 31),
(442, 11, 32),
(226, 12, 17),
(236, 12, 18),
(246, 12, 19),
(256, 12, 20),
(270, 12, 21),
(287, 12, 22),
(304, 12, 23),
(321, 12, 24),
(336, 12, 25),
(350, 12, 26),
(364, 12, 27),
(378, 12, 28),
(261, 13, 20),
(280, 13, 21),
(297, 13, 22),
(314, 13, 23),
(331, 13, 24),
(401, 13, 29),
(415, 13, 30),
(429, 13, 31),
(443, 13, 32),
(230, 14, 17),
(240, 14, 18),
(250, 14, 19),
(276, 14, 21),
(293, 14, 22),
(310, 14, 23),
(327, 14, 24),
(346, 14, 25),
(360, 14, 26),
(374, 14, 27),
(388, 14, 28),
(395, 14, 29),
(409, 14, 30),
(423, 14, 31),
(437, 14, 32),
(227, 15, 17),
(237, 15, 18),
(247, 15, 19),
(257, 15, 20),
(271, 15, 21),
(288, 15, 22),
(305, 15, 23),
(322, 15, 24),
(337, 15, 25),
(351, 15, 26),
(365, 15, 27),
(379, 15, 28),
(232, 16, 17),
(242, 16, 18),
(252, 16, 19),
(262, 16, 20),
(268, 16, 21),
(285, 16, 22),
(302, 16, 23),
(319, 16, 24),
(339, 16, 25),
(353, 16, 26),
(367, 16, 27),
(381, 16, 28),
(397, 16, 29),
(411, 16, 30),
(425, 16, 31),
(439, 16, 32),
(275, 18, 21),
(292, 18, 22),
(309, 18, 23),
(326, 18, 24),
(343, 18, 25),
(357, 18, 26),
(371, 18, 27),
(385, 18, 28),
(394, 18, 29),
(408, 18, 30),
(422, 18, 31),
(436, 18, 32),
(224, 19, 17),
(234, 19, 18),
(244, 19, 19),
(254, 19, 20),
(266, 19, 21),
(283, 19, 22),
(300, 19, 23),
(317, 19, 24),
(345, 19, 25),
(359, 19, 26),
(373, 19, 27),
(387, 19, 28),
(390, 19, 29),
(404, 19, 30),
(418, 19, 31),
(432, 19, 32),
(263, 20, 20),
(281, 20, 21),
(298, 20, 22),
(315, 20, 23),
(332, 20, 24),
(402, 20, 29),
(416, 20, 30),
(430, 20, 31),
(444, 20, 32);

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
(1, 1, '5243', '446.90', 1, 1, 1, '2022-06-20 21:21:59', '2022-07-07 02:36:52'),
(2, 1, '2399', '407.44', 2, 1, 2, '2022-06-20 21:21:59', '2022-07-07 02:37:04'),
(3, 1, '6977', '431.61', 3, 2, 3, '2022-06-20 21:21:59', '2022-07-07 02:37:32'),
(4, 1, '9149', '336.06', 4, 2, 4, '2022-06-20 21:21:59', '2022-07-07 02:37:48'),
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
(60, '88387187', 'ouenaesm', 19, 25, '473.77', 'FUNGIBLE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(63, '35214885', 'shino', 39, 9, '560.00', 'FUNGIBLE', 1, '2022-07-01 09:28:01', '2022-07-01 09:28:01'),
(64, '35214884', 'ruka', 41, 3, '7850.00', 'HERRAMIENTA', 1, '2022-07-01 09:30:29', '2022-07-01 09:30:29'),
(65, '4522126', 'yami', 42, 3, '2600.00', 'HERRAMIENTA', 1, '2022-07-01 09:38:12', '2022-07-01 09:38:12'),
(66, '1485236', 'kotori', 43, 1, '69.50', 'FUNGIBLE', 1, '2022-07-01 20:49:10', '2022-07-01 20:49:10'),
(67, '4588856', 'siesta', 42, 1, '150.00', 'FUNGIBLE', 1, '2022-07-01 21:14:02', '2022-07-01 21:14:02'),
(68, '458225', 'kurumi tokisaki', 41, 1, '36.00', 'FUNGIBLE', 1, '2022-07-01 21:41:08', '2022-07-01 21:41:08'),
(69, '522544', 'neptunia', 40, 4, '452.00', 'FUNGIBLE', 1, '2022-07-01 22:36:30', '2022-07-01 22:36:30'),
(70, '4588563', 'mayuri', 43, 5, '156.00', 'FUNGIBLE', 1, '2022-07-02 18:16:04', '2022-07-02 18:16:04');

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
-- Estructura Stand-in para la vista `lista_mantenimiento`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `lista_mantenimiento` (
`work_order_id` bigint(20) unsigned
,`task` varchar(255)
,`componente` varchar(255)
,`pieza` varchar(255)
);

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
(60, '2022_06_20_052727_create_permission_tables', 1),
(61, '2022_07_05_161645_create_component_work_order_detail_table', 2);

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
(3, 'App\\Models\\User', 1),
(3, 'App\\Models\\User', 2),
(3, 'App\\Models\\User', 3),
(3, 'App\\Models\\User', 4),
(3, 'App\\Models\\User', 5),
(3, 'App\\Models\\User', 6),
(3, 'App\\Models\\User', 7),
(3, 'App\\Models\\User', 8),
(3, 'App\\Models\\User', 9),
(3, 'App\\Models\\User', 10),
(3, 'App\\Models\\User', 11),
(3, 'App\\Models\\User', 12),
(3, 'App\\Models\\User', 13),
(3, 'App\\Models\\User', 14),
(3, 'App\\Models\\User', 15),
(3, 'App\\Models\\User', 16),
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
-- Volcado de datos para la tabla `operator_assigned_stocks`
--

INSERT INTO `operator_assigned_stocks` (`id`, `user_id`, `item_id`, `quantity`, `price`, `warehouse_id`, `state`, `created_at`, `updated_at`) VALUES
(1, 1, 21, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(2, 1, 21, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(3, 1, 44, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(4, 1, 64, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(5, 1, 52, '0.00', '-216.64', 1, 'ASIGNADO', NULL, NULL),
(6, 1, 57, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(7, 2, 9, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(8, 2, 9, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(9, 2, 57, '2.00', '502.17', 1, 'ASIGNADO', NULL, NULL),
(10, 2, 9, '2.00', '362.42', 1, 'ASIGNADO', NULL, NULL),
(11, 1, 21, '2.00', '800.00', 1, 'ASIGNADO', NULL, NULL),
(12, 1, 44, '1.00', '954.65', 1, 'ASIGNADO', NULL, NULL),
(13, 1, 52, '2.00', '216.64', 1, 'ASIGNADO', NULL, NULL),
(14, 1, 57, '2.00', '420.00', 1, 'ASIGNADO', NULL, NULL),
(15, 2, 57, '0.00', '0.00', 1, 'ASIGNADO', NULL, NULL),
(16, 2, 57, '2.00', '502.17', 1, 'ASIGNADO', NULL, NULL),
(17, 1, 63, '3.00', '610.00', 1, 'ASIGNADO', NULL, NULL),
(18, 1, 64, '1.00', '785.00', 1, 'ASIGNADO', NULL, NULL);

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

--
-- Volcado de datos para la tabla `operator_stocks`
--

INSERT INTO `operator_stocks` (`id`, `user_id`, `item_id`, `quantity`, `price`, `warehouse_id`, `created_at`, `updated_at`) VALUES
(2, 1, 21, '2.00', '1600.00', 1, NULL, NULL),
(3, 1, 44, '1.00', '954.65', 1, NULL, NULL),
(4, 1, 64, '1.00', '785.00', 1, NULL, NULL),
(5, 1, 52, '2.00', '433.28', 1, NULL, NULL),
(6, 1, 57, '2.00', '840.00', 1, NULL, NULL),
(7, 2, 9, '2.00', '724.84', 1, NULL, NULL),
(8, 2, 57, '4.00', '2008.68', 1, NULL, NULL),
(9, 1, 63, '3.00', '1830.00', 1, NULL, NULL);

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
-- Volcado de datos para la tabla `operator_stock_details`
--

INSERT INTO `operator_stock_details` (`id`, `user_id`, `item_id`, `movement`, `quantity`, `price`, `warehouse_id`, `state`, `order_request_detail_id`, `created_at`, `updated_at`) VALUES
(2, 1, 21, 'INGRESO', '1.00', '800.00', 1, 'ANULADO', 381, '2022-07-04 20:05:25', '2022-07-04 23:09:59'),
(3, 1, 21, 'INGRESO', '1.00', '800.00', 1, 'ANULADO', 381, '2022-07-04 20:05:37', '2022-07-04 20:05:37'),
(4, 1, 44, 'INGRESO', '1.00', '954.65', 1, 'ANULADO', 384, '2022-07-04 21:10:09', '2022-07-04 23:14:07'),
(5, 1, 64, 'INGRESO', '1.00', '785.00', 1, 'ANULADO', 383, '2022-07-04 21:22:38', '2022-07-04 23:10:38'),
(6, 1, 52, 'INGRESO', '2.00', '216.64', 1, 'ANULADO', 385, '2022-07-04 21:32:52', '2022-07-04 23:13:57'),
(7, 1, 57, 'INGRESO', '1.00', '420.00', 1, 'ANULADO', 410, '2022-07-04 21:39:09', '2022-07-04 23:14:04'),
(8, 2, 9, 'INGRESO', '1.00', '362.42', 1, 'ANULADO', 411, '2022-07-04 22:13:53', '2022-07-04 23:15:01'),
(9, 2, 9, 'INGRESO', '1.00', '362.42', 1, 'ANULADO', 411, '2022-07-04 22:13:57', '2022-07-04 23:15:03'),
(10, 2, 57, 'INGRESO', '2.00', '502.17', 1, 'CONFIRMADO', 374, '2022-07-04 23:15:09', '2022-07-04 23:15:09'),
(11, 2, 9, 'INGRESO', '2.00', '362.42', 1, 'CONFIRMADO', 411, '2022-07-04 23:15:14', '2022-07-04 23:15:14'),
(12, 1, 21, 'INGRESO', '2.00', '800.00', 1, 'CONFIRMADO', 381, '2022-07-05 18:20:59', '2022-07-05 18:20:59'),
(13, 1, 44, 'INGRESO', '1.00', '954.65', 1, 'CONFIRMADO', 384, '2022-07-05 18:21:03', '2022-07-05 18:21:03'),
(14, 1, 52, 'INGRESO', '2.00', '216.64', 1, 'CONFIRMADO', 385, '2022-07-05 18:21:06', '2022-07-05 18:21:06'),
(15, 1, 57, 'INGRESO', '2.00', '420.00', 1, 'CONFIRMADO', 410, '2022-07-05 18:21:12', '2022-07-05 18:21:12'),
(16, 2, 57, 'INGRESO', '1.00', '502.17', 1, 'ANULADO', 374, '2022-07-05 19:41:08', '2022-07-05 19:41:15'),
(17, 2, 57, 'INGRESO', '2.00', '502.17', 1, 'CONFIRMADO', 374, '2022-07-05 19:41:21', '2022-07-05 19:41:21'),
(18, 1, 63, 'INGRESO', '3.00', '610.00', 1, 'CONFIRMADO', 380, '2022-07-05 19:42:03', '2022-07-05 19:42:03'),
(19, 1, 64, 'INGRESO', '1.00', '785.00', 1, 'CONFIRMADO', 383, '2022-07-05 19:42:07', '2022-07-05 19:42:07');

--
-- Disparadores `operator_stock_details`
--
DELIMITER $$
CREATE TRIGGER `anulacion_movimientos` AFTER UPDATE ON `operator_stock_details` FOR EACH ROW BEGIN
DECLARE op_stock INT;
DECLARE op_assigned INT;
DECLARE stock INT;
/*---Obteniendo filas afectadas------*/
SELECT operator_stock_id, operator_assigned_stock_id, stock_id INTO op_stock,op_assigned,stock FROM affected_movement WHERE operator_stock_detail_id = old.id;
IF new.movement = "INGRESO" THEN
/*----------ANULAR INGRESO------*/
/*-----Anular en operator_stocks--------*/
UPDATE operator_stocks SET quantity = quantity - old.quantity, price = price - (new.price*new.quantity) WHERE id = op_stock;
/*----Anular en operator_assigned_stocks--*/
UPDATE operator_assigned_stocks SET quantity = quantity - old.quantity, price = price - (old.price*old.quantity) WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity - old.quantity, price = price - (old.price*old.quantity) WHERE id = stock;
ELSE
/*----------ANULAR SALIDA-------*/
/*---------Anular en op_stock---------*/
UPDATE operator_stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = op_stock;
/*----Anular en operator_assigned_stocks--*/
UPDATE operator_assigned_stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = stock;
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
SET quantity = quantity+new.quantity, price = price+(new.price*new.quantity) WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO op_stock FROM operator_stocks ORDER BY updated_at DESC LIMIT 1;
ELSE
INSERT INTO operator_stocks(user_id, item_id, quantity, price, warehouse_id) VALUES (new.user_id, new.item_id, new.quantity, (new.price*new.quantity), new.warehouse_id);
SELECT MAX(id) INTO op_stock FROM operator_stocks;
END IF;
/*--Insertar material al acumulado general del almacen--*/
IF EXISTS (SELECT * FROM stocks WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id) THEN
UPDATE stocks SET quantity = quantity + new.quantity, price = price + (new.price*new.quantity) WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO stock_general FROM stocks ORDER BY updated_at DESC LIMIT 1;
ELSE
INSERT INTO stocks (item_id, quantity, price, warehouse_id) VALUES (new.item_id, new.quantity, (new.price*new.quantity), new.warehouse_id);
SELECT MAX(id) INTO stock_general FROM stocks;
END IF;
/*-------Material asignado al operador por fecha para descontar--------*/
INSERT INTO operator_assigned_stocks(user_id, item_id, quantity, price, warehouse_id) VALUES (new.user_id, new.item_id, new.quantity, new.price, new.warehouse_id);
SELECT MAX(id) INTO op_assigned FROM operator_assigned_stocks;
ELSEIF new.movement = "SALIDA" THEN
/*-------SALIDA DEL MATERIAL-----------*/
/*-----Acumulado del operador-----*/
UPDATE operator_stocks SET quantity = quantity - new.quantity, price = price-(new.price*new.quantity) WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id;
SELECT id INTO op_stock FROM operator_stocks ORDER BY updated_at DESC LIMIT 1;
IF new.state = "CONFIRMADO" THEN
/*---Descontar items por antiguedad----*/
SELECT quantity, (price*quantity) INTO cantidad, precio FROM operator_assigned_stocks WHERE user_id = new.user_id AND item_id = new.item_id AND warehouse_id = new.warehouse_id AND quantity <> 0 ORDER BY created_at ASC LIMIT 1;
SELECT new.quantity, (new.price*new.quantity) INTO cantidad_sobrante,precio_sobrante;
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
UPDATE stocks SET quantity = quantity - new.quantity, price = price - (new.price*new.quantity) WHERE item_id = new.item_id AND warehouse_id = new.warehouse_id;
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
  `state` enum('PENDIENTE','ABIERTO','CERRADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_dates`
--

INSERT INTO `order_dates` (`id`, `open_request`, `close_request`, `order_date`, `arrival_date`, `state`, `created_at`, `updated_at`) VALUES
(1, '2022-04-25', '2022-04-28', '2022-05-02', '2022-07-01', 'CERRADO', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(2, '2022-06-27', '2022-06-30', '2022-07-04', '2022-09-01', 'PENDIENTE', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(3, '2022-08-29', '2022-09-01', '2022-09-05', '2022-11-01', 'PENDIENTE', '2022-06-20 22:22:55', '2022-06-20 22:22:55'),
(4, '2022-10-31', '2022-11-03', '2022-11-07', '2023-01-01', 'PENDIENTE', '2022-06-20 22:22:56', '2022-06-20 22:22:56');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_requests`
--

CREATE TABLE `order_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','CERRADO','VALIDADO','RECHAZADO','INCOMPLETO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validate_by` bigint(20) UNSIGNED DEFAULT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `order_date_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_requests`
--

INSERT INTO `order_requests` (`id`, `user_id`, `implement_id`, `state`, `validate_by`, `is_canceled`, `order_date_id`, `created_at`, `updated_at`) VALUES
(33, 1, 1, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 08:15:48'),
(34, 2, 2, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 18:14:12'),
(35, 3, 3, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 18:15:15'),
(36, 4, 4, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 18:29:30'),
(37, 5, 5, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 18:17:35'),
(38, 6, 6, 'VALIDADO', 4, 0, 1, NULL, '2022-07-02 18:17:47'),
(39, 7, 7, 'CERRADO', NULL, 0, 1, NULL, '2022-07-01 23:28:24'),
(40, 8, 8, 'RECHAZADO', NULL, 0, 1, NULL, '2022-07-02 18:26:30'),
(41, 9, 9, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(42, 10, 10, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(43, 11, 11, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(44, 12, 12, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(45, 13, 13, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(46, 14, 14, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(47, 15, 15, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(48, 16, 16, 'PENDIENTE', NULL, 0, 1, NULL, NULL);

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
  `state` enum('PENDIENTE','ACEPTADO','MODIFICADO','RECHAZADO','VALIDADO','INCOMPLETO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `observation` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assigned_quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `assigned_state` enum('NO ASIGNADO','ASIGNADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NO ASIGNADO',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_details`
--

INSERT INTO `order_request_details` (`id`, `order_request_id`, `item_id`, `quantity`, `estimated_price`, `state`, `observation`, `assigned_quantity`, `assigned_state`, `created_at`, `updated_at`) VALUES
(236, 33, 9, '2.00', '362.42', 'RECHAZADO', 'as', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 18:15:49'),
(237, 33, 21, '1.00', '785.44', 'ACEPTADO', 'NGG', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 09:28:45'),
(238, 33, 44, '1.00', '954.65', 'ACEPTADO', 'Se aceptó todo.', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 09:34:51'),
(239, 33, 52, '2.00', '216.64', 'ACEPTADO', 'ÑÑ', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 09:34:57'),
(240, 33, 57, '2.00', '502.17', 'ACEPTADO', 'as', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 23:30:57'),
(241, 33, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 21:51:40'),
(242, 33, 24, '0.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 21:51:34'),
(243, 34, 9, '2.00', '362.42', 'ACEPTADO', 'a', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 23:31:24'),
(244, 34, 21, '0.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:14:12'),
(245, 34, 44, '0.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:14:39'),
(246, 34, 52, '0.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:14:34'),
(247, 34, 57, '4.00', '502.17', 'ACEPTADO', 'Se aceptop todo completo', '0.00', 'NO ASIGNADO', NULL, '2022-06-29 00:16:11'),
(248, 34, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:14:29'),
(249, 34, 24, '0.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:14:25'),
(250, 35, 9, '2.00', '362.42', 'RECHAZADO', 'AA', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 09:43:02'),
(251, 35, 21, '3.00', '785.44', 'ACEPTADO', 'ASA', '0.00', 'NO ASIGNADO', NULL, '2022-07-02 18:15:04'),
(252, 35, 44, '0.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:17:29'),
(253, 35, 52, '0.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:17:25'),
(254, 35, 57, '4.00', '502.17', 'MODIFICADO', 'AS', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 09:42:24'),
(255, 35, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:17:17'),
(256, 35, 24, '0.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-25 23:17:21'),
(257, 36, 9, '1.00', '362.42', 'ACEPTADO', '.', '0.00', 'NO ASIGNADO', NULL, '2022-07-02 18:29:23'),
(258, 36, 21, '0.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-29 16:39:58'),
(259, 36, 44, '1.00', '954.65', 'ACEPTADO', '5', '0.00', 'NO ASIGNADO', NULL, '2022-07-02 18:29:13'),
(260, 36, 52, '0.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-29 16:40:09'),
(261, 36, 57, '4.00', '502.17', 'ACEPTADO', '.', '0.00', 'NO ASIGNADO', NULL, '2022-07-02 18:29:05'),
(262, 36, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-29 16:39:48'),
(263, 36, 24, '0.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-29 16:39:52'),
(264, 37, 4, '0.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:23:22'),
(265, 37, 9, '1.00', '362.42', 'RECHAZADO', 'j', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:39:00'),
(266, 37, 24, '2.00', '577.05', 'MODIFICADO', 'jk', '0.00', 'NO ASIGNADO', NULL, '2022-07-02 18:17:05'),
(267, 37, 52, '3.00', '216.64', 'ACEPTADO', 'jj', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:36:41'),
(268, 37, 57, '0.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:23:16'),
(269, 37, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:23:13'),
(270, 37, 44, '0.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:23:10'),
(271, 38, 4, '0.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 21:04:03'),
(272, 38, 9, '2.00', '362.42', 'ACEPTADO', 'da', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:06:18'),
(273, 38, 24, '0.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 21:04:06'),
(274, 38, 52, '3.00', '216.64', 'MODIFICADO', 'da', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:05:55'),
(275, 38, 57, '2.00', '502.17', 'MODIFICADO', 'sad', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:07:00'),
(276, 38, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 21:04:10'),
(277, 38, 44, '1.00', '954.65', 'ACEPTADO', 'da', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:06:08'),
(278, 39, 4, '0.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 20:45:50'),
(279, 39, 9, '0.00', '362.42', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 20:45:47'),
(280, 39, 24, '2.00', '577.05', 'ACEPTADO', 'sas', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 23:28:13'),
(281, 39, 52, '0.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 20:45:39'),
(282, 39, 57, '4.00', '502.17', 'MODIFICADO', 'asas', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 23:28:19'),
(283, 39, 3, '0.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 20:45:35'),
(284, 39, 44, '0.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-07-01 20:45:56'),
(285, 40, 4, '1.00', '459.05', 'RECHAZADO', 'asd', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:57:16'),
(286, 40, 9, '2.00', '362.42', 'RECHAZADO', 'sadad', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:57:39'),
(287, 40, 24, '2.00', '577.05', 'RECHAZADO', 'dasd', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:58:05'),
(288, 40, 52, '3.00', '216.64', 'RECHAZADO', 'dad', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:57:25'),
(289, 40, 57, '0.00', '502.17', 'RECHAZADO', NULL, '0.00', 'NO ASIGNADO', NULL, '2022-06-30 18:38:55'),
(290, 40, 3, '1.00', '692.98', 'RECHAZADO', 'dad', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:57:35'),
(291, 40, 44, '2.00', '954.65', 'RECHAZADO', 'dad', '0.00', 'NO ASIGNADO', NULL, '2022-07-01 22:57:31'),
(292, 41, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(293, 41, 15, '2.00', '958.75', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(294, 41, 24, '2.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(295, 41, 52, '1.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(296, 41, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(297, 41, 4, '1.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(298, 41, 29, '11.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(299, 42, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(300, 42, 15, '2.00', '958.75', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(301, 42, 24, '2.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(302, 42, 52, '1.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(303, 42, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(304, 42, 4, '1.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(305, 42, 29, '11.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(306, 43, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(307, 43, 15, '2.00', '958.75', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(308, 43, 24, '2.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(309, 43, 52, '1.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(310, 43, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(311, 43, 4, '1.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(312, 43, 29, '11.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(313, 44, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(314, 44, 15, '2.00', '958.75', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(315, 44, 24, '2.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(316, 44, 52, '1.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(317, 44, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(318, 44, 4, '1.00', '459.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(319, 44, 29, '11.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(320, 45, 3, '2.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(321, 45, 44, '1.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(322, 45, 52, '2.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(323, 45, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(324, 45, 53, '1.00', '952.16', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(325, 45, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(326, 45, 24, '1.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(327, 46, 3, '2.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(328, 46, 44, '1.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(329, 46, 52, '2.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(330, 46, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(331, 46, 53, '1.00', '952.16', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(332, 46, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(333, 46, 24, '1.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(334, 47, 3, '2.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(335, 47, 44, '1.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(336, 47, 52, '2.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(337, 47, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(338, 47, 53, '1.00', '952.16', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(339, 47, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(340, 47, 24, '1.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(341, 48, 3, '3.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(342, 48, 44, '1.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(343, 48, 52, '2.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(344, 48, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(345, 48, 53, '1.00', '952.16', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(346, 48, 57, '6.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(347, 48, 24, '2.00', '577.05', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', NULL, NULL),
(348, 33, 17, '1.00', '906.47', 'RECHAZADO', 'LNK', '0.00', 'NO ASIGNADO', '2022-06-25 21:51:57', '2022-07-01 18:15:24'),
(349, 34, 8, '2.00', '563.25', 'RECHAZADO', 'Se rechazó todo.', '0.00', 'NO ASIGNADO', '2022-06-25 22:19:52', '2022-06-29 00:17:01'),
(374, 34, 57, '4.00', '502.17', 'VALIDADO', 'Se aceptop todo completo', '4.00', 'ASIGNADO', '2022-06-29 00:16:11', '2022-07-05 19:41:21'),
(375, 36, 8, '1.00', '563.25', 'ACEPTADO', '2', '0.00', 'NO ASIGNADO', '2022-06-29 16:40:28', '2022-07-02 18:28:57'),
(379, 33, 63, '3.00', '600.00', 'ACEPTADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-01 09:28:01', '2022-07-01 09:28:17'),
(380, 33, 63, '3.00', '610.00', 'VALIDADO', 'NJ', '3.00', 'ASIGNADO', '2022-07-01 09:28:01', '2022-07-05 19:42:04'),
(381, 33, 21, '1.00', '800.00', 'VALIDADO', 'NGG', '1.00', 'ASIGNADO', '2022-07-01 09:28:45', '2022-07-05 18:20:59'),
(382, 33, 64, '3.00', '7850.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-01 09:30:29', '2022-07-01 09:30:29'),
(383, 33, 64, '1.00', '785.00', 'VALIDADO', 'ÑL', '1.00', 'ASIGNADO', '2022-07-01 09:30:29', '2022-07-05 19:42:07'),
(384, 33, 44, '1.00', '954.65', 'VALIDADO', 'Se aceptó todo.', '1.00', 'ASIGNADO', '2022-07-01 09:34:51', '2022-07-05 18:21:03'),
(385, 33, 52, '2.00', '216.64', 'VALIDADO', 'ÑÑ', '2.00', 'ASIGNADO', '2022-07-01 09:34:57', '2022-07-05 18:21:06'),
(386, 35, 65, '32.00', '2600.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-01 09:38:12', '2022-07-01 09:38:12'),
(387, 35, 65, '2.00', '260.00', 'VALIDADO', '5', '0.00', 'NO ASIGNADO', '2022-07-01 09:38:12', '2022-07-01 21:36:35'),
(388, 35, 57, '2.00', '502.17', 'VALIDADO', 'AS', '0.00', 'NO ASIGNADO', '2022-07-01 09:42:24', '2022-07-01 09:42:24'),
(390, 39, 66, '18.00', '69.50', 'MODIFICADO', '32', '0.00', 'NO ASIGNADO', '2022-07-01 20:49:10', '2022-07-02 18:18:39'),
(391, 39, 67, '400.00', '150.00', 'MODIFICADO', '36', '0.00', 'NO ASIGNADO', '2022-07-01 21:14:02', '2022-07-02 18:25:29'),
(393, 38, 68, '45.00', '36.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-01 21:41:08', '2022-07-01 22:06:37'),
(394, 38, 68, '22.00', '36.00', 'VALIDADO', 'sda', '0.00', 'NO ASIGNADO', '2022-07-01 21:41:08', '2022-07-01 22:06:51'),
(395, 38, 52, '2.00', '216.64', 'VALIDADO', 'da', '0.00', 'NO ASIGNADO', '2022-07-01 22:05:55', '2022-07-01 22:05:55'),
(396, 38, 44, '1.00', '1000.00', 'VALIDADO', 'da', '0.00', 'NO ASIGNADO', '2022-07-01 22:06:08', '2022-07-01 22:06:08'),
(397, 38, 9, '2.00', '350.00', 'VALIDADO', 'da', '0.00', 'NO ASIGNADO', '2022-07-01 22:06:18', '2022-07-01 22:06:18'),
(398, 38, 57, '1.00', '506.00', 'VALIDADO', 'sad', '0.00', 'NO ASIGNADO', '2022-07-01 22:06:27', '2022-07-01 22:07:00'),
(399, 37, 69, '2.00', '452.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-01 22:36:30', '2022-07-01 22:36:30'),
(400, 37, 69, '1.00', '440.00', 'VALIDADO', 'jk', '0.00', 'NO ASIGNADO', '2022-07-01 22:36:30', '2022-07-01 22:37:32'),
(401, 37, 52, '3.00', '150.00', 'VALIDADO', 'jj', '0.00', 'NO ASIGNADO', '2022-07-01 22:36:41', '2022-07-01 22:37:46'),
(408, 39, 24, '2.00', '577.05', 'VALIDADO', 'sas', '0.00', 'NO ASIGNADO', '2022-07-01 23:28:13', '2022-07-01 23:28:13'),
(409, 39, 57, '3.00', '502.17', 'VALIDADO', 'asas', '0.00', 'NO ASIGNADO', '2022-07-01 23:28:19', '2022-07-01 23:28:19'),
(410, 33, 57, '2.00', '420.00', 'VALIDADO', 'as', '2.00', 'ASIGNADO', '2022-07-01 23:30:57', '2022-07-05 18:21:12'),
(411, 34, 9, '2.00', '362.42', 'VALIDADO', 'a', '2.00', 'ASIGNADO', '2022-07-01 23:31:24', '2022-07-04 23:15:14'),
(412, 35, 21, '3.00', '785.44', 'VALIDADO', 'ASA', '0.00', 'NO ASIGNADO', '2022-07-02 18:15:04', '2022-07-02 18:15:04'),
(413, 37, 70, '6.00', '156.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-02 18:16:04', '2022-07-02 18:17:29'),
(414, 37, 70, '4.00', '156.00', 'VALIDADO', '55', '0.00', 'NO ASIGNADO', '2022-07-02 18:16:04', '2022-07-02 18:17:29'),
(415, 37, 24, '1.00', '600.00', 'VALIDADO', 'jk', '0.00', 'NO ASIGNADO', '2022-07-02 18:17:05', '2022-07-02 18:17:17'),
(417, 39, 67, '9.00', '150.00', 'VALIDADO', '36', '0.00', 'NO ASIGNADO', '2022-07-02 18:25:29', '2022-07-02 18:26:06'),
(418, 36, 8, '1.00', '560.00', 'VALIDADO', '2', '0.00', 'NO ASIGNADO', '2022-07-02 18:28:57', '2022-07-02 18:28:57'),
(419, 36, 57, '4.00', '500.00', 'VALIDADO', '.', '0.00', 'NO ASIGNADO', '2022-07-02 18:29:05', '2022-07-02 18:29:05'),
(420, 36, 44, '1.00', '1000.00', 'VALIDADO', '5', '0.00', 'NO ASIGNADO', '2022-07-02 18:29:13', '2022-07-02 18:29:13'),
(421, 36, 9, '1.00', '300.00', 'VALIDADO', '.', '0.00', 'NO ASIGNADO', '2022-07-02 18:29:23', '2022-07-02 18:29:23');

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
  `state` enum('PENDIENTE','CREADO','RECHAZADO') COLLATE utf8mb4_unicode_ci DEFAULT 'PENDIENTE',
  `item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `observation` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_new_items`
--

INSERT INTO `order_request_new_items` (`id`, `order_request_id`, `new_item`, `quantity`, `measurement_unit_id`, `brand`, `datasheet`, `image`, `state`, `item_id`, `observation`, `created_at`, `updated_at`) VALUES
(9, 33, 'Ruka', '3.00', 3, 'saa', '-sad\n-sa\n-sa', 'public/newMaterials/zHyV8jgLSvA3k9SovgkQP6pehGMkaLVgHhWm51w2.jpg', 'CREADO', 64, '', '2022-06-25 21:53:12', '2022-07-01 09:30:29'),
(10, 33, 'Shino', '3.00', 9, 'Suryuu', '-ssa\n-sa\n-ñláéíóú', 'public/newMaterials/hvhXgQ5Myw77Np2aIOPZtaGSarDTcgEkCWnnuU1t.jpg', 'CREADO', 63, '', '2022-06-25 21:54:03', '2022-07-01 09:28:01'),
(11, 35, 'YAMI', '32.00', 3, 'SDSA', 'SDASD', 'public/newMaterials/h8jbuHVOvBZmHiy6luMaYxfILhTYYweUqZga4BwR.jpg', 'CREADO', 65, '', '2022-06-25 23:17:09', '2022-07-01 09:38:12'),
(12, 36, 'Perno ed 1/2\"', '12.00', 1, '33', 'das', 'public/newMaterials/zxhcqq8HPDSqiOTKo9U3eIYyDaHvgUdxiJaBXXKu.png', 'RECHAZADO', NULL, '', '2022-06-29 16:39:43', '2022-07-01 09:56:10'),
(13, 40, 'ARDUINO UNO', '12.00', 2, 'ARDUINO', '-NINGUNA', 'public/newMaterials/ZqdVsQCe4FRjdxjgNGKbSvrLI2PUAm7b66QAvmwR.jpg', 'RECHAZADO', NULL, '', '2022-06-30 18:38:42', '2022-07-01 09:59:58'),
(14, 39, 'SIESTA', '400.00', 1, 'POP UP', '-Editado', 'public/newMaterials/3OgF3aUzTFg7dk37LkZhz6hz3S9wmloI2FotmG2g.jpg', 'CREADO', 67, '', '2022-07-01 18:21:35', '2022-07-01 21:14:03'),
(16, 39, 'KOTORI', '320.00', 1, 'GHG', 'SDA', 'public/newMaterials/fCfInt5S1XjoTAazPQl6YmZjDARC0ZWepv7U13Du.jpg', 'CREADO', NULL, '', '2022-07-01 20:30:07', '2022-07-01 20:49:10'),
(17, 38, 'Kurumi Tokisaki', '45.00', 1, 'figma', 'lknlk', 'public/newMaterials/L1RogEtjFauRgOxcNhhPwsBITzlYpWf9trIMBiDR.jpg', 'CREADO', 68, '', '2022-07-01 21:01:32', '2022-07-01 21:41:08'),
(18, 38, 'ninin', '22.00', 6, 'pop up', '-sdad-', 'public/newMaterials/iALbNJDMxYFxqyc7wMlHyfPpCIPEF1OFBMrrqG7M.jpg', 'RECHAZADO', NULL, '', '2022-07-01 21:03:08', '2022-07-01 22:05:40'),
(20, 37, 'NEPTUNIA', '2.00', 4, 'BANPRESTO', '-NUEVA', 'public/newMaterials/43jFlkhV3Uok4udePPLUQu3aXKxWbfdB71GeLE4A.jpg', 'CREADO', 69, '', '2022-07-01 22:26:00', '2022-07-01 22:36:30'),
(21, 37, 'SIESTA', '5.00', 2, 'FIGMA', 'ADASD', 'public/newMaterials/U4DnnKLHf1ySJYNnij3X4GI9ATacV7ITTkfrcaIQ.jpg', 'RECHAZADO', NULL, '', '2022-07-01 22:26:28', '2022-07-02 18:16:37'),
(22, 37, 'MAYURI', '6.00', 5, 'DATE A LIVE', '-MOVIE', 'public/newMaterials/DPzB3hATRpH7MGUsKihwXssugO14xAqn7loUCF80.jpg', 'CREADO', 70, '', '2022-07-01 22:27:13', '2022-07-02 18:16:04');

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
  `abbreviation` varchar(5) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `risks`
--

INSERT INTO `risks` (`id`, `risk`, `abbreviation`, `created_at`, `updated_at`) VALUES
(21, 'MECÁNICO', 'M', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(22, 'FÍSICO', 'F', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(23, 'ELÉCTRICO', 'E', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(24, 'LOCATIVO', 'L', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(25, 'QUÍMICO', 'Q', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(26, 'BIOLÓGICO', 'B', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(27, 'FÍSICO QUÍMICO', 'FQ', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(28, 'ERGONÓMICO', 'EG', '2022-07-05 13:16:21', '2022-07-05 13:16:21'),
(29, 'PSICO SOCIAL', 'PS', '2022-07-05 13:16:21', '2022-07-05 13:16:21');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `risk_task_order`
--

CREATE TABLE `risk_task_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `risk_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `risk_task_order`
--

INSERT INTO `risk_task_order` (`id`, `risk_id`, `task_id`) VALUES
(25, 21, 2),
(73, 21, 14),
(30, 21, 22),
(74, 21, 26),
(14, 21, 32),
(11, 21, 33),
(60, 21, 75),
(62, 21, 77),
(64, 21, 79),
(70, 22, 9),
(34, 22, 21),
(20, 22, 27),
(76, 22, 28),
(18, 22, 29),
(8, 22, 31),
(35, 22, 47),
(36, 22, 51),
(37, 22, 52),
(38, 22, 53),
(39, 22, 54),
(40, 22, 55),
(41, 22, 56),
(43, 22, 58),
(44, 22, 59),
(45, 22, 60),
(48, 22, 63),
(49, 22, 64),
(50, 22, 65),
(51, 22, 66),
(52, 22, 67),
(66, 22, 81),
(6, 23, 4),
(72, 23, 16),
(69, 23, 17),
(5, 23, 24),
(29, 23, 25),
(17, 23, 38),
(59, 23, 74),
(61, 23, 76),
(10, 24, 12),
(16, 24, 39),
(26, 25, 5),
(31, 25, 13),
(13, 25, 35),
(57, 25, 72),
(19, 26, 15),
(3, 26, 18),
(4, 26, 37),
(46, 26, 61),
(54, 26, 69),
(65, 26, 80),
(15, 27, 1),
(21, 27, 3),
(71, 27, 6),
(9, 27, 8),
(75, 27, 11),
(23, 27, 23),
(24, 27, 30),
(42, 27, 57),
(55, 27, 70),
(63, 27, 78),
(67, 27, 82),
(68, 27, 83),
(77, 27, 84),
(78, 27, 85),
(79, 27, 86),
(80, 27, 87),
(81, 27, 88),
(82, 27, 89),
(83, 27, 90),
(84, 27, 94),
(85, 27, 95),
(86, 27, 96),
(28, 28, 10),
(32, 28, 19),
(7, 28, 20),
(33, 28, 40),
(47, 28, 62),
(56, 28, 71),
(58, 28, 73),
(27, 29, 7),
(22, 29, 34),
(12, 29, 36),
(53, 29, 68);

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
('Ap3rZUCbnDmQ0qkAzyRTM983bCqv3yDdhjDTK5GW', 3, '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.115 Safari/537.36 OPR/88.0.4412.40', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiZ01vVGwwb052SlpNY0gwcVZMNmw4dHBwMkdBSHY5SkdhVlQ3TFBVRiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDk6Imh0dHA6Ly9zaXN0ZW1hL29wZXJhdG9yL01hbnRlbmltaWVudG9zLVBlbmRpZW50ZXMiO31zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTozO30=', 1657308125),
('jSti0w3Ki5xnrG0fe8BljSSIbUQaTzWEcQ9moZEF', 5, '127.0.0.1', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.115 Safari/537.36 OPR/88.0.4412.40', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiUGxIRnhGeVYycjZRWG9jdnpjTFNIejkyOWJKNTNseWpOWWU5YTBpaiI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjQ5OiJodHRwOi8vc2lzdGVtYS9vcGVyYXRvci9NYW50ZW5pbWllbnRvcy1QZW5kaWVudGVzIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NTt9', 1657308027);

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

--
-- Volcado de datos para la tabla `stocks`
--

INSERT INTO `stocks` (`id`, `item_id`, `quantity`, `price`, `warehouse_id`, `created_at`, `updated_at`) VALUES
(2, 21, '2.00', '1600.00', 1, NULL, NULL),
(3, 44, '1.00', '954.65', 1, NULL, NULL),
(4, 64, '1.00', '785.00', 1, NULL, NULL),
(5, 52, '2.00', '433.28', 1, NULL, NULL),
(6, 57, '7.00', '3350.85', 1, NULL, NULL),
(7, 9, '1.00', '222.67', 1, NULL, NULL),
(8, 63, '3.00', '1830.00', 1, NULL, NULL);

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

--
-- Volcado de datos para la tabla `systems`
--

INSERT INTO `systems` (`id`, `system`, `created_at`, `updated_at`) VALUES
(1, 'HIDRAÚLICO', '2022-07-05 14:20:55', '2022-07-05 14:20:55'),
(2, 'OLEO HIDRAÚLICO', '2022-07-05 14:20:55', '2022-07-05 14:20:55'),
(3, 'NUEUMÁTICO', '2022-07-05 14:20:55', '2022-07-05 14:20:55'),
(4, 'MECÁNICO', '2022-07-05 14:20:55', '2022-07-05 14:20:55'),
(5, 'ELECTRÓNICO', '2022-07-05 14:20:55', '2022-07-05 14:20:55'),
(6, 'ELÉCTRICO', NULL, NULL);

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
(1, 'Esse reprehenderit commodi pariatur quibusdam vitae enim odio.', 8, '15.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(2, 'Minus asperiores perferendis quia sequi autem.', 25, '15.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(3, 'Iusto officia tempore id dolore quia.', 14, '15.00', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(4, 'Aut est odio dolorum dolor qui dolorem.', 2, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(5, 'Minus fugit voluptate non sit optio placeat.', 18, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(6, 'Sit et voluptatum quis ullam rem voluptate aut.', 31, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(7, 'Necessitatibus ut esse adipisci.', 9, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(8, 'Consequatur non aliquam aspernatur quis.', 3, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(9, 'Sed eius dolorem sequi fuga nihil.', 7, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(10, 'Nisi vitae dolorum modi molestiae consequatur nisi quis molestiae.', 10, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(11, 'Voluptatibus id alias ad rerum sint beatae sit voluptatem.', 9, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(12, 'Cumque magnam et et eligendi.', 32, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(13, 'Pariatur non qui provident dolores.', 1, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(14, 'Velit doloremque saepe ipsum et temporibus vitae omnis.', 22, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(15, 'Id possimus et sint blanditiis fugit accusamus ducimus.', 12, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(16, 'Tenetur autem recusandae nam dicta alias.', 24, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(17, 'Reprehenderit pariatur repellat voluptas et qui quis dolore dignissimos.', 18, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(18, 'Amet blanditiis nesciunt veniam consequatur qui harum odio.', 23, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(19, 'Placeat ullam quia enim pariatur sint delectus dolor.', 32, '15.00', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(20, 'Aut sit sed natus.', 15, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(21, 'Qui et earum voluptatum ratione aut.', 7, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(22, 'Officiis quo libero ut sapiente.', 7, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(23, 'Libero dolor reiciendis ullam ut enim eos.', 8, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(24, 'Atque nulla fugit voluptatem reiciendis recusandae culpa.', 7, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(25, 'Molestiae vitae quia iste nemo harum.', 21, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(26, 'Voluptas illo quia ullam.', 24, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(27, 'Iure et reprehenderit molestiae.', 19, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(28, 'Aut totam unde qui voluptatem deserunt quia ipsum.', 15, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(29, 'Fugit iure occaecati quas alias itaque consequuntur perspiciatis.', 10, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(30, 'Maiores in laborum molestias.', 31, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(31, 'Commodi molestias magni fuga aspernatur.', 8, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(32, 'Eius quam et esse accusamus accusantium.', 29, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(33, 'Doloremque blanditiis amet ullam aut rerum quos et.', 17, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(34, 'Laudantium omnis sed laboriosam et ut.', 32, '15.00', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(35, 'Earum dolorum quia sit sit voluptas.', 2, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(36, 'Dolores debitis esse quia et dolores modi.', 26, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(37, 'Animi est necessitatibus omnis omnis est dolor.', 34, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(38, 'Excepturi laborum dolore ea et autem dignissimos.', 30, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(39, 'Est minus accusantium deserunt et voluptatem nulla odio.', 23, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(40, 'Qui deserunt corporis id ut impedit explicabo nihil quaerat.', 9, '15.00', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(47, 'RECAMBIO', 1, '30.00', NULL, NULL),
(51, 'RECAMBIO', 2, '15.00', NULL, NULL),
(52, 'RECAMBIO', 3, '15.00', NULL, NULL),
(53, 'RECAMBIO', 4, '15.00', NULL, NULL),
(54, 'RECAMBIO', 5, '15.00', NULL, NULL),
(55, 'RECAMBIO', 6, '15.00', NULL, NULL),
(56, 'RECAMBIO', 7, '15.00', NULL, NULL),
(57, 'RECAMBIO', 8, '15.00', NULL, NULL),
(58, 'RECAMBIO', 9, '15.00', NULL, NULL),
(59, 'RECAMBIO', 10, '15.00', NULL, NULL),
(60, 'RECAMBIO', 11, '15.00', NULL, NULL),
(61, 'RECAMBIO', 12, '15.00', NULL, NULL),
(62, 'RECAMBIO', 13, '15.00', NULL, NULL),
(63, 'RECAMBIO', 14, '15.00', NULL, NULL),
(64, 'RECAMBIO', 15, '15.00', NULL, NULL),
(65, 'RECAMBIO', 16, '15.00', NULL, NULL),
(66, 'RECAMBIO', 17, '15.00', NULL, NULL),
(67, 'RECAMBIO', 18, '15.00', NULL, NULL),
(68, 'RECAMBIO', 19, '15.00', NULL, NULL),
(69, 'RECAMBIO', 20, '15.00', NULL, NULL),
(70, 'RECAMBIO', 21, '15.00', NULL, NULL),
(71, 'RECAMBIO', 22, '15.00', NULL, NULL),
(72, 'RECAMBIO', 23, '15.00', NULL, NULL),
(73, 'RECAMBIO', 24, '15.00', NULL, NULL),
(74, 'RECAMBIO', 25, '15.00', NULL, NULL),
(75, 'RECAMBIO', 26, '15.00', NULL, NULL),
(76, 'RECAMBIO', 27, '15.00', NULL, NULL),
(77, 'RECAMBIO', 28, '15.00', NULL, NULL),
(78, 'RECAMBIO', 29, '15.00', NULL, NULL),
(79, 'RECAMBIO', 30, '15.00', NULL, NULL),
(80, 'RECAMBIO', 31, '15.00', NULL, NULL),
(81, 'RECAMBIO', 32, '15.00', NULL, NULL),
(82, 'RECAMBIO', 33, '15.00', NULL, NULL),
(83, 'RECAMBIO', 34, '15.00', NULL, NULL),
(84, 'Verfiicar', 4, '15.00', NULL, NULL),
(85, 'Comprobar', 5, '15.00', NULL, NULL),
(86, 'Rectificar', 6, '15.00', NULL, NULL),
(87, 'Mirar', 11, '15.00', NULL, NULL),
(88, 'Observar', 13, '15.00', NULL, NULL),
(89, 'Cotejar', 16, '15.00', NULL, NULL),
(90, 'Kasda', 20, '15.00', NULL, NULL),
(94, 'aerr', 27, '15.00', NULL, NULL),
(95, 'ser', 28, '15.00', NULL, NULL),
(96, 'dad', 33, '15.00', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `task_required_materials`
--

CREATE TABLE `task_required_materials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `task_required_materials`
--

INSERT INTO `task_required_materials` (`id`, `task_id`, `item_id`, `quantity`) VALUES
(1, 95, 1, '1.00'),
(2, 95, 5, '1.00'),
(3, 95, 7, '1.00'),
(4, 23, 6, '1.00'),
(5, 23, 8, '1.00'),
(6, 31, 11, '1.00'),
(7, 31, 12, '1.00'),
(8, 1, 22, '1.00'),
(9, 1, 16, '1.00'),
(10, 1, 12, '1.00'),
(11, 90, 28, '1.00'),
(12, 90, 30, '1.00'),
(13, 84, 31, '1.00'),
(14, 84, 41, '1.00'),
(15, 84, 49, '1.00'),
(16, 84, 50, '1.00');

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
(1, 1, '72307', '700.00', 1, '2022-06-20 21:22:03', '2022-07-07 02:36:52'),
(2, 1, '76737', '900.00', 1, '2022-06-20 21:22:03', '2022-07-07 02:37:04'),
(3, 1, '65116', '750.00', 2, '2022-06-20 21:22:04', '2022-07-07 02:37:48'),
(4, 1, '76977', '800.00', 2, '2022-06-20 21:22:04', '2022-07-07 02:37:32'),
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
(1, 1, 2, 1, 'sadada', '2022-06-23', 'MAÑANA', 1, '435.00', '450.00', '15.00', '', 1, 0, '2022-06-24 17:57:46', '2022-06-24 18:00:49'),
(2, 2, 1, 3, '12553', '2022-06-24', 'NOCHE', 1, '268.00', '282.00', '14.00', '', 1, 0, '2022-06-25 22:07:10', '2022-06-25 22:19:32'),
(3, 3, 3, 4, '1365646', '2022-07-06', 'MAÑANA', 3, '390.00', '450.00', '60.00', 'saSDSDA', 3, 0, '2022-07-07 07:36:16', '2022-07-07 07:36:16'),
(4, 4, 3, 4, '54398363', '2022-07-06', 'MAÑANA', 4, '450.00', '700.00', '250.00', 'WDEQ', 3, 0, '2022-07-07 07:36:36', '2022-07-07 07:36:36'),
(5, 1, 1, 3, '3265465', '2022-07-06', 'MAÑANA', 1, '282.00', '700.00', '418.00', 'SAD', 1, 0, '2022-07-07 07:36:52', '2022-07-07 07:36:52'),
(6, 2, 2, 3, '2113', '2022-07-06', 'MAÑANA', 2, '450.00', '900.00', '450.00', 'EQW21', 1, 0, '2022-07-07 07:37:04', '2022-07-07 07:37:04'),
(7, 3, 4, 2, '213213', '2022-07-06', 'NOCHE', 3, '414.00', '800.00', '386.00', '', 3, 0, '2022-07-07 07:37:32', '2022-07-07 07:37:32'),
(8, 3, 3, 4, '245456', '2022-07-06', 'NOCHE', 4, '700.00', '750.00', '50.00', 'SDA', 3, 0, '2022-07-07 07:37:48', '2022-07-07 07:37:48');

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
(5, 5, 3, 5, 5, '2022-06-25', 'MAÑANA', 5, 1, '2022-06-24 17:37:42', '2022-06-24 17:40:25'),
(6, 6, 4, 5, 5, '2022-07-02', 'MAÑANA', 5, 0, '2022-07-01 22:28:34', '2022-07-01 22:28:34'),
(7, 5, 4, 6, 6, '2022-07-02', 'NOCHE', 5, 0, '2022-07-01 22:28:45', '2022-07-01 22:28:45');

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
(1, '777269', 'Mr. Ford Vandervort', 'Kunze', 1, 'roob.brianne@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'WPn7K7yearpM20WS3s964CPUZ2vtDhTFL8wlqrSDztRxP3X56ohOycrlwG8V', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '213312', 'Birdie Waelchi', 'Walker', 1, 'ernser.caden@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '3DKrIkMWt3jIXg69NAE526q76vAEEmns9MsmPACorvjwqMwQYj7Mi6QQoMIu', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '109931', 'Randi Leuschke', 'Cormier', 2, 'amaya.feeney@example.org', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'lhojjEAiJKr92QAxNgJwXhEcm4HSe56ZLSXSJUxVJm5eYOvshi0Eso93MwIZ', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '854140', 'Dr. Levi Feest', 'Ondricka', 2, 'woodrow.bogan@example.com', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'W4E2Tb3Qn0kiEFSjJR6ZHDyC2rtoHLtLiCO9Xr7yXUthV6OR7MqppsSPeeCP', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '912055', 'Erwin Green', 'Heidenreich', 3, 'hbeatty@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'Oez5hWgGNfZkraPBczri2IXpecESS65AmoH6uU7tmL7WOMMKK7xlv2aZ3Ga9', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '502387', 'Bella Block', 'Bashirian', 3, 'sibyl08@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '3NXfsNa9xGchlBQ9iIbNaHjLcFz5unflenQ1Z74g5YCsxiXyXk0bKpoWgElS', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '981787', 'Jaylon Prosacco', 'Langosh', 4, 'pleuschke@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'rc7GJRvdk8Hja3W1jLepIOIhBPkUfcaM2TtoYLw1sJTXXmjxVBy2kQtGm8t1', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '588440', 'Irving Strosin', 'Langosh', 4, 'mercedes57@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'Xz2S4RCr9v6EVwxQhozRejcp04TFyIs2GCHh2Tfl34GSok2M0yzbvy4gDfuv', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
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
(2, '518707', 'culpa', 4, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(3, '564628', 'libero', 7, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(4, '597593', 'fuga', 5, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(5, '342722', 'dignissimos', 3, '2022-06-20 21:21:47', '2022-06-20 21:21:47'),
(6, '487606', 'nesciunt', 2, '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(7, '716983', 'consequuntur', 1, '2022-06-20 21:21:48', '2022-06-20 21:21:48'),
(8, '209261', 'eveniet', 6, '2022-06-20 21:21:48', '2022-06-20 21:21:48');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_orders`
--

CREATE TABLE `work_orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `maintenance` enum('1','2','3') COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` enum('PENDIENTE','NO VALIDADO','CONCLUIDO','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `work_orders`
--

INSERT INTO `work_orders` (`id`, `implement_id`, `user_id`, `location_id`, `date`, `maintenance`, `state`, `is_canceled`, `created_at`, `updated_at`) VALUES
(17, 1, 1, 1, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:01:58', '2022-07-09 00:07:29'),
(18, 2, 2, 1, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:04', '2022-07-09 00:07:21'),
(19, 3, 3, 2, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:10', '2022-07-09 00:07:25'),
(20, 4, 4, 2, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:17', '2022-07-09 00:07:33'),
(21, 5, 5, 3, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(22, 6, 6, 3, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(23, 7, 7, 4, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(24, 8, 8, 4, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:33', '2022-07-08 19:02:33'),
(25, 9, 9, 5, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:36', '2022-07-08 19:02:36'),
(26, 10, 10, 5, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:38', '2022-07-08 19:02:38'),
(27, 11, 11, 6, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:40', '2022-07-08 19:02:40'),
(28, 12, 12, 6, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:41', '2022-07-08 19:02:41'),
(29, 13, 13, 7, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:42', '2022-07-08 19:02:42'),
(30, 14, 14, 7, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:44', '2022-07-08 19:02:44'),
(31, 15, 15, 8, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:46', '2022-07-08 19:02:46'),
(32, 16, 16, 8, '2022-07-11', '1', 'PENDIENTE', 0, '2022-07-08 19:02:48', '2022-07-08 19:02:48');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_details`
--

CREATE TABLE `work_order_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('RECOMENDADO','ACEPTADO','NO ACEPTADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACEPTADO',
  `is_checked` tinyint(1) NOT NULL DEFAULT 0,
  `component_implement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `component_part_id` bigint(20) UNSIGNED DEFAULT NULL,
  `observation` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `work_order_details`
--

INSERT INTO `work_order_details` (`id`, `work_order_id`, `task_id`, `state`, `is_checked`, `component_implement_id`, `component_part_id`, `observation`, `created_at`, `updated_at`) VALUES
(254, 17, 95, 'ACEPTADO', 0, 1, NULL, NULL, NULL, NULL),
(255, 17, 51, 'NO ACEPTADO', 0, NULL, 1, NULL, NULL, '2022-07-09 00:07:29'),
(256, 17, 62, 'NO ACEPTADO', 0, NULL, 2, NULL, NULL, '2022-07-09 00:07:29'),
(257, 17, 82, 'NO ACEPTADO', 0, NULL, 3, NULL, NULL, '2022-07-09 00:07:29'),
(258, 17, 1, 'ACEPTADO', 0, 2, NULL, NULL, NULL, NULL),
(259, 17, 23, 'ACEPTADO', 0, 2, NULL, NULL, NULL, NULL),
(260, 17, 31, 'ACEPTADO', 0, 2, NULL, NULL, NULL, NULL),
(261, 17, 84, 'ACEPTADO', 0, NULL, 4, NULL, NULL, NULL),
(262, 17, 60, 'NO ACEPTADO', 0, NULL, 5, NULL, NULL, '2022-07-09 00:07:29'),
(263, 17, 72, 'NO ACEPTADO', 0, NULL, 6, NULL, NULL, '2022-07-09 00:07:29'),
(264, 17, 90, 'ACEPTADO', 0, 3, NULL, NULL, NULL, NULL),
(265, 17, 84, 'ACEPTADO', 0, NULL, 7, NULL, NULL, NULL),
(266, 17, 32, 'ACEPTADO', 0, NULL, 8, NULL, NULL, NULL),
(267, 17, 82, 'NO ACEPTADO', 0, NULL, 9, NULL, NULL, '2022-07-09 00:07:29'),
(268, 18, 95, 'ACEPTADO', 0, 4, NULL, NULL, NULL, NULL),
(269, 18, 51, 'ACEPTADO', 0, NULL, 28, NULL, NULL, '2022-07-09 00:07:21'),
(270, 18, 62, 'ACEPTADO', 0, NULL, 29, NULL, NULL, '2022-07-09 00:07:21'),
(271, 18, 82, 'ACEPTADO', 0, NULL, 30, NULL, NULL, '2022-07-09 00:07:21'),
(272, 18, 1, 'ACEPTADO', 0, 5, NULL, NULL, NULL, NULL),
(273, 18, 23, 'ACEPTADO', 0, 5, NULL, NULL, NULL, NULL),
(274, 18, 31, 'ACEPTADO', 0, 5, NULL, NULL, NULL, NULL),
(275, 18, 84, 'ACEPTADO', 0, NULL, 31, NULL, NULL, NULL),
(276, 18, 60, 'ACEPTADO', 0, NULL, 32, NULL, NULL, '2022-07-09 00:07:21'),
(277, 18, 72, 'ACEPTADO', 0, NULL, 33, NULL, NULL, '2022-07-09 00:07:21'),
(278, 18, 90, 'ACEPTADO', 0, 6, NULL, NULL, NULL, NULL),
(279, 18, 84, 'ACEPTADO', 0, NULL, 34, NULL, NULL, NULL),
(280, 18, 32, 'ACEPTADO', 0, NULL, 35, NULL, NULL, NULL),
(281, 18, 82, 'ACEPTADO', 0, NULL, 36, NULL, NULL, '2022-07-09 00:07:21'),
(282, 19, 95, 'ACEPTADO', 0, 7, NULL, NULL, NULL, NULL),
(283, 19, 51, 'ACEPTADO', 0, NULL, 10, NULL, NULL, '2022-07-09 00:07:25'),
(284, 19, 62, 'ACEPTADO', 0, NULL, 11, NULL, NULL, '2022-07-09 00:07:25'),
(285, 19, 82, 'ACEPTADO', 0, NULL, 12, NULL, NULL, '2022-07-09 00:07:25'),
(286, 19, 1, 'ACEPTADO', 0, 8, NULL, NULL, NULL, NULL),
(287, 19, 23, 'ACEPTADO', 0, 8, NULL, NULL, NULL, NULL),
(288, 19, 31, 'ACEPTADO', 0, 8, NULL, NULL, NULL, NULL),
(289, 19, 84, 'ACEPTADO', 0, NULL, 13, NULL, NULL, NULL),
(290, 19, 60, 'ACEPTADO', 0, NULL, 14, NULL, NULL, '2022-07-09 00:07:25'),
(291, 19, 72, 'ACEPTADO', 0, NULL, 15, NULL, NULL, '2022-07-09 00:07:25'),
(292, 19, 90, 'ACEPTADO', 0, 9, NULL, NULL, NULL, NULL),
(293, 19, 84, 'ACEPTADO', 0, NULL, 16, NULL, NULL, NULL),
(294, 19, 32, 'ACEPTADO', 0, NULL, 17, NULL, NULL, NULL),
(295, 19, 82, 'ACEPTADO', 0, NULL, 18, NULL, NULL, '2022-07-09 00:07:25'),
(296, 20, 95, 'ACEPTADO', 0, 10, NULL, NULL, NULL, NULL),
(297, 20, 51, 'ACEPTADO', 0, NULL, 19, NULL, NULL, '2022-07-09 00:07:33'),
(298, 20, 88, 'ACEPTADO', 0, NULL, 20, NULL, NULL, NULL),
(299, 20, 82, 'ACEPTADO', 0, NULL, 21, NULL, NULL, '2022-07-09 00:07:33'),
(300, 20, 1, 'ACEPTADO', 0, 11, NULL, NULL, NULL, NULL),
(301, 20, 23, 'ACEPTADO', 0, 11, NULL, NULL, NULL, NULL),
(302, 20, 31, 'ACEPTADO', 0, 11, NULL, NULL, NULL, NULL),
(303, 20, 84, 'ACEPTADO', 0, NULL, 22, NULL, NULL, NULL),
(304, 20, 60, 'ACEPTADO', 0, NULL, 23, NULL, NULL, '2022-07-09 00:07:33'),
(305, 20, 18, 'ACEPTADO', 0, NULL, 24, NULL, NULL, NULL),
(306, 20, 39, 'ACEPTADO', 0, NULL, 24, NULL, NULL, NULL),
(307, 20, 90, 'ACEPTADO', 0, 12, NULL, NULL, NULL, NULL),
(308, 20, 84, 'ACEPTADO', 0, NULL, 25, NULL, NULL, NULL),
(309, 20, 32, 'ACEPTADO', 0, NULL, 26, NULL, NULL, NULL),
(310, 20, 82, 'ACEPTADO', 0, NULL, 27, NULL, NULL, '2022-07-09 00:07:33'),
(311, 21, 90, 'ACEPTADO', 0, 13, NULL, NULL, NULL, NULL),
(312, 21, 84, 'ACEPTADO', 0, NULL, 37, NULL, NULL, NULL),
(313, 21, 32, 'ACEPTADO', 0, NULL, 38, NULL, NULL, NULL),
(314, 21, 96, 'ACEPTADO', 0, NULL, 39, NULL, NULL, NULL),
(315, 21, 27, 'ACEPTADO', 0, 14, NULL, NULL, NULL, NULL),
(316, 21, 8, 'ACEPTADO', 0, NULL, 40, NULL, NULL, NULL),
(317, 21, 84, 'ACEPTADO', 0, NULL, 41, NULL, NULL, NULL),
(318, 21, 88, 'ACEPTADO', 0, NULL, 42, NULL, NULL, NULL),
(319, 21, 14, 'ACEPTADO', 0, 15, NULL, NULL, NULL, NULL),
(320, 21, 4, 'ACEPTADO', 0, NULL, 43, NULL, NULL, NULL),
(321, 21, 35, 'ACEPTADO', 0, NULL, 43, NULL, NULL, NULL),
(322, 21, 18, 'ACEPTADO', 0, NULL, 44, NULL, NULL, NULL),
(323, 21, 39, 'ACEPTADO', 0, NULL, 44, NULL, NULL, NULL),
(324, 21, 32, 'ACEPTADO', 0, NULL, 45, NULL, NULL, NULL),
(325, 22, 90, 'ACEPTADO', 0, 16, NULL, NULL, NULL, NULL),
(326, 22, 84, 'ACEPTADO', 0, NULL, 46, NULL, NULL, NULL),
(327, 22, 32, 'ACEPTADO', 0, NULL, 47, NULL, NULL, NULL),
(328, 22, 96, 'ACEPTADO', 0, NULL, 48, NULL, NULL, NULL),
(329, 22, 27, 'ACEPTADO', 0, 17, NULL, NULL, NULL, NULL),
(330, 22, 8, 'ACEPTADO', 0, NULL, 49, NULL, NULL, NULL),
(331, 22, 84, 'ACEPTADO', 0, NULL, 50, NULL, NULL, NULL),
(332, 22, 88, 'ACEPTADO', 0, NULL, 51, NULL, NULL, NULL),
(333, 22, 14, 'ACEPTADO', 0, 18, NULL, NULL, NULL, NULL),
(334, 22, 4, 'ACEPTADO', 0, NULL, 52, NULL, NULL, NULL),
(335, 22, 35, 'ACEPTADO', 0, NULL, 52, NULL, NULL, NULL),
(336, 22, 18, 'ACEPTADO', 0, NULL, 53, NULL, NULL, NULL),
(337, 22, 39, 'ACEPTADO', 0, NULL, 53, NULL, NULL, NULL),
(338, 22, 32, 'ACEPTADO', 0, NULL, 54, NULL, NULL, NULL),
(339, 23, 90, 'ACEPTADO', 0, 19, NULL, NULL, NULL, NULL),
(340, 23, 84, 'ACEPTADO', 0, NULL, 55, NULL, NULL, NULL),
(341, 23, 32, 'ACEPTADO', 0, NULL, 56, NULL, NULL, NULL),
(342, 23, 96, 'ACEPTADO', 0, NULL, 57, NULL, NULL, NULL),
(343, 23, 27, 'ACEPTADO', 0, 20, NULL, NULL, NULL, NULL),
(344, 23, 8, 'ACEPTADO', 0, NULL, 58, NULL, NULL, NULL),
(345, 23, 84, 'ACEPTADO', 0, NULL, 59, NULL, NULL, NULL),
(346, 23, 88, 'ACEPTADO', 0, NULL, 60, NULL, NULL, NULL),
(347, 23, 14, 'ACEPTADO', 0, 21, NULL, NULL, NULL, NULL),
(348, 23, 4, 'ACEPTADO', 0, NULL, 61, NULL, NULL, NULL),
(349, 23, 35, 'ACEPTADO', 0, NULL, 61, NULL, NULL, NULL),
(350, 23, 18, 'ACEPTADO', 0, NULL, 62, NULL, NULL, NULL),
(351, 23, 39, 'ACEPTADO', 0, NULL, 62, NULL, NULL, NULL),
(352, 23, 32, 'ACEPTADO', 0, NULL, 63, NULL, NULL, NULL),
(353, 24, 90, 'ACEPTADO', 0, 22, NULL, NULL, NULL, NULL),
(354, 24, 84, 'ACEPTADO', 0, NULL, 64, NULL, NULL, NULL),
(355, 24, 32, 'ACEPTADO', 0, NULL, 65, NULL, NULL, NULL),
(356, 24, 96, 'ACEPTADO', 0, NULL, 66, NULL, NULL, NULL),
(357, 24, 27, 'ACEPTADO', 0, 23, NULL, NULL, NULL, NULL),
(358, 24, 8, 'ACEPTADO', 0, NULL, 67, NULL, NULL, NULL),
(359, 24, 84, 'ACEPTADO', 0, NULL, 68, NULL, NULL, NULL),
(360, 24, 88, 'ACEPTADO', 0, NULL, 69, NULL, NULL, NULL),
(361, 24, 14, 'ACEPTADO', 0, 24, NULL, NULL, NULL, NULL),
(362, 24, 4, 'ACEPTADO', 0, NULL, 70, NULL, NULL, NULL),
(363, 24, 35, 'ACEPTADO', 0, NULL, 70, NULL, NULL, NULL),
(364, 24, 18, 'ACEPTADO', 0, NULL, 71, NULL, NULL, NULL),
(365, 24, 39, 'ACEPTADO', 0, NULL, 71, NULL, NULL, NULL),
(366, 24, 32, 'ACEPTADO', 0, NULL, 72, NULL, NULL, NULL),
(367, 25, 10, 'ACEPTADO', 0, 25, NULL, NULL, NULL, NULL),
(368, 25, 29, 'ACEPTADO', 0, 25, NULL, NULL, NULL, NULL),
(369, 25, 9, 'ACEPTADO', 0, NULL, 73, NULL, NULL, NULL),
(370, 25, 21, 'ACEPTADO', 0, NULL, 73, NULL, NULL, NULL),
(371, 25, 22, 'ACEPTADO', 0, NULL, 73, NULL, NULL, NULL),
(372, 25, 24, 'ACEPTADO', 0, NULL, 73, NULL, NULL, NULL),
(373, 25, 32, 'ACEPTADO', 0, NULL, 74, NULL, NULL, NULL),
(374, 25, 96, 'ACEPTADO', 0, NULL, 75, NULL, NULL, NULL),
(375, 25, 85, 'ACEPTADO', 0, 26, NULL, NULL, NULL, NULL),
(376, 25, 4, 'ACEPTADO', 0, NULL, 76, NULL, NULL, NULL),
(377, 25, 35, 'ACEPTADO', 0, NULL, 76, NULL, NULL, NULL),
(378, 25, 9, 'ACEPTADO', 0, NULL, 77, NULL, NULL, NULL),
(379, 25, 21, 'ACEPTADO', 0, NULL, 77, NULL, NULL, NULL),
(380, 25, 22, 'ACEPTADO', 0, NULL, 77, NULL, NULL, NULL),
(381, 25, 24, 'ACEPTADO', 0, NULL, 77, NULL, NULL, NULL),
(382, 25, 88, 'ACEPTADO', 0, NULL, 78, NULL, NULL, NULL),
(383, 25, 25, 'ACEPTADO', 0, 27, NULL, NULL, NULL, NULL),
(384, 25, 8, 'ACEPTADO', 0, NULL, 79, NULL, NULL, NULL),
(385, 25, 33, 'ACEPTADO', 0, NULL, 80, NULL, NULL, NULL),
(386, 25, 96, 'ACEPTADO', 0, NULL, 81, NULL, NULL, NULL),
(387, 26, 10, 'ACEPTADO', 0, 28, NULL, NULL, NULL, NULL),
(388, 26, 29, 'ACEPTADO', 0, 28, NULL, NULL, NULL, NULL),
(389, 26, 9, 'ACEPTADO', 0, NULL, 82, NULL, NULL, NULL),
(390, 26, 21, 'ACEPTADO', 0, NULL, 82, NULL, NULL, NULL),
(391, 26, 22, 'ACEPTADO', 0, NULL, 82, NULL, NULL, NULL),
(392, 26, 24, 'ACEPTADO', 0, NULL, 82, NULL, NULL, NULL),
(393, 26, 32, 'ACEPTADO', 0, NULL, 83, NULL, NULL, NULL),
(394, 26, 96, 'ACEPTADO', 0, NULL, 84, NULL, NULL, NULL),
(395, 26, 85, 'ACEPTADO', 0, 29, NULL, NULL, NULL, NULL),
(396, 26, 4, 'ACEPTADO', 0, NULL, 85, NULL, NULL, NULL),
(397, 26, 35, 'ACEPTADO', 0, NULL, 85, NULL, NULL, NULL),
(398, 26, 9, 'ACEPTADO', 0, NULL, 86, NULL, NULL, NULL),
(399, 26, 21, 'ACEPTADO', 0, NULL, 86, NULL, NULL, NULL),
(400, 26, 22, 'ACEPTADO', 0, NULL, 86, NULL, NULL, NULL),
(401, 26, 24, 'ACEPTADO', 0, NULL, 86, NULL, NULL, NULL),
(402, 26, 88, 'ACEPTADO', 0, NULL, 87, NULL, NULL, NULL),
(403, 26, 25, 'ACEPTADO', 0, 30, NULL, NULL, NULL, NULL),
(404, 26, 8, 'ACEPTADO', 0, NULL, 88, NULL, NULL, NULL),
(405, 26, 33, 'ACEPTADO', 0, NULL, 89, NULL, NULL, NULL),
(406, 26, 96, 'ACEPTADO', 0, NULL, 90, NULL, NULL, NULL),
(407, 27, 10, 'ACEPTADO', 0, 31, NULL, NULL, NULL, NULL),
(408, 27, 29, 'ACEPTADO', 0, 31, NULL, NULL, NULL, NULL),
(409, 27, 9, 'ACEPTADO', 0, NULL, 91, NULL, NULL, NULL),
(410, 27, 21, 'ACEPTADO', 0, NULL, 91, NULL, NULL, NULL),
(411, 27, 22, 'ACEPTADO', 0, NULL, 91, NULL, NULL, NULL),
(412, 27, 24, 'ACEPTADO', 0, NULL, 91, NULL, NULL, NULL),
(413, 27, 32, 'ACEPTADO', 0, NULL, 92, NULL, NULL, NULL),
(414, 27, 96, 'ACEPTADO', 0, NULL, 93, NULL, NULL, NULL),
(415, 27, 85, 'ACEPTADO', 0, 32, NULL, NULL, NULL, NULL),
(416, 27, 4, 'ACEPTADO', 0, NULL, 94, NULL, NULL, NULL),
(417, 27, 35, 'ACEPTADO', 0, NULL, 94, NULL, NULL, NULL),
(418, 27, 9, 'ACEPTADO', 0, NULL, 95, NULL, NULL, NULL),
(419, 27, 21, 'ACEPTADO', 0, NULL, 95, NULL, NULL, NULL),
(420, 27, 22, 'ACEPTADO', 0, NULL, 95, NULL, NULL, NULL),
(421, 27, 24, 'ACEPTADO', 0, NULL, 95, NULL, NULL, NULL),
(422, 27, 88, 'ACEPTADO', 0, NULL, 96, NULL, NULL, NULL),
(423, 27, 25, 'ACEPTADO', 0, 33, NULL, NULL, NULL, NULL),
(424, 27, 8, 'ACEPTADO', 0, NULL, 97, NULL, NULL, NULL),
(425, 27, 33, 'ACEPTADO', 0, NULL, 98, NULL, NULL, NULL),
(426, 27, 96, 'ACEPTADO', 0, NULL, 99, NULL, NULL, NULL),
(427, 28, 10, 'ACEPTADO', 0, 34, NULL, NULL, NULL, NULL),
(428, 28, 29, 'ACEPTADO', 0, 34, NULL, NULL, NULL, NULL),
(429, 28, 9, 'ACEPTADO', 0, NULL, 100, NULL, NULL, NULL),
(430, 28, 21, 'ACEPTADO', 0, NULL, 100, NULL, NULL, NULL),
(431, 28, 22, 'ACEPTADO', 0, NULL, 100, NULL, NULL, NULL),
(432, 28, 24, 'ACEPTADO', 0, NULL, 100, NULL, NULL, NULL),
(433, 28, 32, 'ACEPTADO', 0, NULL, 101, NULL, NULL, NULL),
(434, 28, 96, 'ACEPTADO', 0, NULL, 102, NULL, NULL, NULL),
(435, 28, 85, 'ACEPTADO', 0, 35, NULL, NULL, NULL, NULL),
(436, 28, 4, 'ACEPTADO', 0, NULL, 103, NULL, NULL, NULL),
(437, 28, 35, 'ACEPTADO', 0, NULL, 103, NULL, NULL, NULL),
(438, 28, 9, 'ACEPTADO', 0, NULL, 104, NULL, NULL, NULL),
(439, 28, 21, 'ACEPTADO', 0, NULL, 104, NULL, NULL, NULL),
(440, 28, 22, 'ACEPTADO', 0, NULL, 104, NULL, NULL, NULL),
(441, 28, 24, 'ACEPTADO', 0, NULL, 104, NULL, NULL, NULL),
(442, 28, 88, 'ACEPTADO', 0, NULL, 105, NULL, NULL, NULL),
(443, 28, 25, 'ACEPTADO', 0, 36, NULL, NULL, NULL, NULL),
(444, 28, 8, 'ACEPTADO', 0, NULL, 106, NULL, NULL, NULL),
(445, 28, 33, 'ACEPTADO', 0, NULL, 107, NULL, NULL, NULL),
(446, 28, 96, 'ACEPTADO', 0, NULL, 108, NULL, NULL, NULL),
(447, 29, 95, 'ACEPTADO', 0, 37, NULL, NULL, NULL, NULL),
(448, 29, 4, 'ACEPTADO', 0, NULL, 109, NULL, NULL, NULL),
(449, 29, 35, 'ACEPTADO', 0, NULL, 109, NULL, NULL, NULL),
(450, 29, 88, 'ACEPTADO', 0, NULL, 110, NULL, NULL, NULL),
(451, 29, 96, 'ACEPTADO', 0, NULL, 111, NULL, NULL, NULL),
(452, 29, 94, 'ACEPTADO', 0, 38, NULL, NULL, NULL, NULL),
(453, 29, 87, 'ACEPTADO', 0, NULL, 112, NULL, NULL, NULL),
(454, 29, 38, 'ACEPTADO', 0, NULL, 113, NULL, NULL, NULL),
(455, 29, 96, 'ACEPTADO', 0, NULL, 114, NULL, NULL, NULL),
(456, 29, 14, 'ACEPTADO', 0, 39, NULL, NULL, NULL, NULL),
(457, 29, 4, 'ACEPTADO', 0, NULL, 115, NULL, NULL, NULL),
(458, 29, 35, 'ACEPTADO', 0, NULL, 115, NULL, NULL, NULL),
(459, 29, 18, 'ACEPTADO', 0, NULL, 116, NULL, NULL, NULL),
(460, 29, 39, 'ACEPTADO', 0, NULL, 116, NULL, NULL, NULL),
(461, 29, 32, 'ACEPTADO', 0, NULL, 117, NULL, NULL, NULL),
(462, 30, 95, 'ACEPTADO', 0, 40, NULL, NULL, NULL, NULL),
(463, 30, 4, 'ACEPTADO', 0, NULL, 118, NULL, NULL, NULL),
(464, 30, 35, 'ACEPTADO', 0, NULL, 118, NULL, NULL, NULL),
(465, 30, 88, 'ACEPTADO', 0, NULL, 119, NULL, NULL, NULL),
(466, 30, 96, 'ACEPTADO', 0, NULL, 120, NULL, NULL, NULL),
(467, 30, 94, 'ACEPTADO', 0, 41, NULL, NULL, NULL, NULL),
(468, 30, 87, 'ACEPTADO', 0, NULL, 121, NULL, NULL, NULL),
(469, 30, 38, 'ACEPTADO', 0, NULL, 122, NULL, NULL, NULL),
(470, 30, 96, 'ACEPTADO', 0, NULL, 123, NULL, NULL, NULL),
(471, 30, 14, 'ACEPTADO', 0, 42, NULL, NULL, NULL, NULL),
(472, 30, 4, 'ACEPTADO', 0, NULL, 124, NULL, NULL, NULL),
(473, 30, 35, 'ACEPTADO', 0, NULL, 124, NULL, NULL, NULL),
(474, 30, 18, 'ACEPTADO', 0, NULL, 125, NULL, NULL, NULL),
(475, 30, 39, 'ACEPTADO', 0, NULL, 125, NULL, NULL, NULL),
(476, 30, 32, 'ACEPTADO', 0, NULL, 126, NULL, NULL, NULL),
(477, 31, 95, 'ACEPTADO', 0, 43, NULL, NULL, NULL, NULL),
(478, 31, 4, 'ACEPTADO', 0, NULL, 127, NULL, NULL, NULL),
(479, 31, 35, 'ACEPTADO', 0, NULL, 127, NULL, NULL, NULL),
(480, 31, 88, 'ACEPTADO', 0, NULL, 128, NULL, NULL, NULL),
(481, 31, 96, 'ACEPTADO', 0, NULL, 129, NULL, NULL, NULL),
(482, 31, 94, 'ACEPTADO', 0, 44, NULL, NULL, NULL, NULL),
(483, 31, 87, 'ACEPTADO', 0, NULL, 130, NULL, NULL, NULL),
(484, 31, 38, 'ACEPTADO', 0, NULL, 131, NULL, NULL, NULL),
(485, 31, 96, 'ACEPTADO', 0, NULL, 132, NULL, NULL, NULL),
(486, 31, 14, 'ACEPTADO', 0, 45, NULL, NULL, NULL, NULL),
(487, 31, 4, 'ACEPTADO', 0, NULL, 133, NULL, NULL, NULL),
(488, 31, 35, 'ACEPTADO', 0, NULL, 133, NULL, NULL, NULL),
(489, 31, 18, 'ACEPTADO', 0, NULL, 134, NULL, NULL, NULL),
(490, 31, 39, 'ACEPTADO', 0, NULL, 134, NULL, NULL, NULL),
(491, 31, 32, 'ACEPTADO', 0, NULL, 135, NULL, NULL, NULL),
(492, 32, 95, 'ACEPTADO', 0, 46, NULL, NULL, NULL, NULL),
(493, 32, 4, 'ACEPTADO', 0, NULL, 136, NULL, NULL, NULL),
(494, 32, 35, 'ACEPTADO', 0, NULL, 136, NULL, NULL, NULL),
(495, 32, 88, 'ACEPTADO', 0, NULL, 137, NULL, NULL, NULL),
(496, 32, 96, 'ACEPTADO', 0, NULL, 138, NULL, NULL, NULL),
(497, 32, 94, 'ACEPTADO', 0, 47, NULL, NULL, NULL, NULL),
(498, 32, 87, 'ACEPTADO', 0, NULL, 139, NULL, NULL, NULL),
(499, 32, 38, 'ACEPTADO', 0, NULL, 140, NULL, NULL, NULL),
(500, 32, 96, 'ACEPTADO', 0, NULL, 141, NULL, NULL, NULL),
(501, 32, 14, 'ACEPTADO', 0, 48, NULL, NULL, NULL, NULL),
(502, 32, 4, 'ACEPTADO', 0, NULL, 142, NULL, NULL, NULL),
(503, 32, 35, 'ACEPTADO', 0, NULL, 142, NULL, NULL, NULL),
(504, 32, 18, 'ACEPTADO', 0, NULL, 143, NULL, NULL, NULL),
(505, 32, 39, 'ACEPTADO', 0, NULL, 143, NULL, NULL, NULL),
(506, 32, 32, 'ACEPTADO', 0, NULL, 144, NULL, NULL, NULL);

--
-- Disparadores `work_order_details`
--
DELIMITER $$
CREATE TRIGGER `insert_orden_trabajo` AFTER INSERT ON `work_order_details` FOR EACH ROW BEGIN
/*----------VARIABLE PARA DETENER CICLO DE EPPS----------*/
DECLARE epp_final INT DEFAULT 0;
/*----------VARIABLE PARA LA TAREA ASIGNADA---------------*/
DECLARE tarea VARCHAR(255);
/*----------VARIABLE PARA EL EPP--------------------------*/
DECLARE equipo_proteccion INT;
/*----------OBTENER NOMBRE DE LA TAREA--------------------*/
SELECT task INTO tarea FROM tasks WHERE id = new.task_id;
/*-----------AGREGAR EPPS NECESARIOS PARA LA ORDEN DE TRABAJO----------*/
    /*-----------Obtener los epp según el riesgo--------------------------*/
	BEGIN
		DECLARE cur_epp CURSOR FOR SELECT er.epp_id FROM risk_task_order rt INNER JOIN epp_risk er ON er.risk_id = rt.risk_id WHERE rt.task_id = new.task_id GROUP BY er.epp_id;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET epp_final = 1;
        /*-------Abrir cursor para iterar epps--------------------------------------------*/
        OPEN cur_epp;
            bucle:LOOP
                IF epp_final = 1 THEN
                    LEAVE bucle;
                END IF;
                FETCH cur_epp INTO equipo_proteccion;
                IF NOT EXISTS(SELECT * FROM epp_work_order WHERE work_order_id = new.work_order_id AND epp_id = equipo_proteccion) THEN
                    INSERT INTO epp_work_order(epp_id , work_order_id) VALUES (equipo_proteccion, new.work_order_id);
                END IF;
            END LOOP bucle;
        CLOSE cur_epp;
    END;
/*----------------------------------------------------------------------------------------*/
/*----------AGREGAR AL COMPONENTE O A LA PIEZA ORDENADO RECAMBIO SI TASK ES REPONER-------*/
    /*----------Verificar si la tarea cambiará un componente----*/
    IF(new.component_implement_id != NULL AND tarea = "RECAMBIO") THEN
    /*------------PONER  A LA ORDEN DE TRABAJO-------*/
    UPDATE component_implement SET state = "ORDENADO" WHERE id = new.component_implement_id;
    /*---------Verificar si la tarea cambiará una pieza------*/
    ELSEIF(new.component_part_id != NULL AND tarea = "RECAMBIO") THEN
    /*------------PONER ORDENADO A LA PIEZA-----------------*/
    UPDATE component_part SET state = "ORDENADO" WHERE id = new.component_part_id;
    END IF;
/*-----------------------------------------------------------------------------------------*/
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_required_materials`
--

CREATE TABLE `work_order_required_materials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 1.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `work_order_required_materials`
--

INSERT INTO `work_order_required_materials` (`id`, `work_order_id`, `item_id`, `quantity`, `created_at`, `updated_at`) VALUES
(218, 17, 1, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(219, 17, 5, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(220, 17, 7, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(221, 17, 7, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(222, 17, 1, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(223, 17, 5, '1.00', '2022-07-08 19:01:58', '2022-07-08 19:01:58'),
(224, 17, 7, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(225, 17, 7, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(226, 17, 3, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(227, 17, 24, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(228, 17, 57, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(229, 17, 57, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(230, 17, 22, '1.00', '2022-07-08 19:01:59', '2022-07-08 19:01:59'),
(231, 17, 16, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(232, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(233, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(234, 17, 6, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(235, 17, 8, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(236, 17, 8, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(237, 17, 11, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(238, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(239, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(240, 17, 11, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(241, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(242, 17, 12, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(243, 17, 31, '1.00', '2022-07-08 19:02:00', '2022-07-08 19:02:00'),
(244, 17, 41, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(245, 17, 49, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(246, 17, 50, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(247, 17, 50, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(248, 17, 31, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(249, 17, 41, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(250, 17, 49, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(251, 17, 50, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(252, 17, 50, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(253, 17, 21, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(254, 17, 44, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(255, 17, 44, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(256, 17, 28, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(257, 17, 30, '1.00', '2022-07-08 19:02:01', '2022-07-08 19:02:01'),
(258, 17, 30, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(259, 17, 28, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(260, 17, 30, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(261, 17, 30, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(262, 17, 31, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(263, 17, 41, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(264, 17, 49, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(265, 17, 50, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(266, 17, 50, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(267, 17, 31, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(268, 17, 41, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(269, 17, 49, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(270, 17, 50, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(271, 17, 50, '1.00', '2022-07-08 19:02:02', '2022-07-08 19:02:02'),
(272, 17, 57, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(273, 17, 57, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(274, 17, 28, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(275, 17, 30, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(276, 17, 30, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(277, 17, 28, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(278, 17, 30, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(279, 17, 30, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(280, 17, 31, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(281, 17, 41, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(282, 17, 49, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(283, 17, 50, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(284, 17, 50, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(285, 17, 31, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(286, 17, 41, '1.00', '2022-07-08 19:02:03', '2022-07-08 19:02:03'),
(287, 17, 49, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(288, 17, 50, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(289, 17, 50, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(290, 17, 57, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(291, 17, 57, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(292, 18, 1, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(293, 18, 5, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(294, 18, 7, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(295, 18, 7, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(296, 18, 1, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(297, 18, 5, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(298, 18, 7, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(299, 18, 7, '1.00', '2022-07-08 19:02:04', '2022-07-08 19:02:04'),
(300, 18, 3, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(301, 18, 24, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(302, 18, 57, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(303, 18, 57, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(304, 18, 22, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(305, 18, 16, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(306, 18, 12, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(307, 18, 12, '1.00', '2022-07-08 19:02:05', '2022-07-08 19:02:05'),
(308, 18, 6, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(309, 18, 8, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(310, 18, 8, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(311, 18, 11, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(312, 18, 12, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(313, 18, 12, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(314, 18, 11, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(315, 18, 12, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(316, 18, 12, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(317, 18, 31, '1.00', '2022-07-08 19:02:06', '2022-07-08 19:02:06'),
(318, 18, 41, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(319, 18, 49, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(320, 18, 50, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(321, 18, 50, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(322, 18, 31, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(323, 18, 41, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(324, 18, 49, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(325, 18, 50, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(326, 18, 50, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(327, 18, 21, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(328, 18, 44, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(329, 18, 44, '1.00', '2022-07-08 19:02:07', '2022-07-08 19:02:07'),
(330, 18, 28, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(331, 18, 30, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(332, 18, 30, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(333, 18, 28, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(334, 18, 30, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(335, 18, 30, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(336, 18, 31, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(337, 18, 41, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(338, 18, 49, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(339, 18, 50, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(340, 18, 50, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(341, 18, 31, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(342, 18, 41, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(343, 18, 49, '1.00', '2022-07-08 19:02:08', '2022-07-08 19:02:08'),
(344, 18, 50, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(345, 18, 50, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(346, 18, 57, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(347, 18, 57, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(348, 18, 28, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(349, 18, 30, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(350, 18, 30, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(351, 18, 28, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(352, 18, 30, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(353, 18, 30, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(354, 18, 31, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(355, 18, 41, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(356, 18, 49, '1.00', '2022-07-08 19:02:09', '2022-07-08 19:02:09'),
(357, 18, 50, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(358, 18, 50, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(359, 18, 31, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(360, 18, 41, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(361, 18, 49, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(362, 18, 50, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(363, 18, 50, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(364, 18, 57, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(365, 18, 57, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(366, 19, 1, '1.00', '2022-07-08 19:02:10', '2022-07-08 19:02:10'),
(367, 19, 5, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(368, 19, 7, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(369, 19, 7, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(370, 19, 1, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(371, 19, 5, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(372, 19, 7, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(373, 19, 7, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(374, 19, 3, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(375, 19, 24, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(376, 19, 57, '1.00', '2022-07-08 19:02:11', '2022-07-08 19:02:11'),
(377, 19, 57, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(378, 19, 22, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(379, 19, 16, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(380, 19, 12, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(381, 19, 12, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(382, 19, 6, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(383, 19, 8, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(384, 19, 8, '1.00', '2022-07-08 19:02:12', '2022-07-08 19:02:12'),
(385, 19, 11, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(386, 19, 12, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(387, 19, 12, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(388, 19, 11, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(389, 19, 12, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(390, 19, 12, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(391, 19, 31, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(392, 19, 41, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(393, 19, 49, '1.00', '2022-07-08 19:02:13', '2022-07-08 19:02:13'),
(394, 19, 50, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(395, 19, 50, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(396, 19, 31, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(397, 19, 41, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(398, 19, 49, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(399, 19, 50, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(400, 19, 50, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(401, 19, 21, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(402, 19, 44, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(403, 19, 44, '1.00', '2022-07-08 19:02:14', '2022-07-08 19:02:14'),
(404, 19, 28, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(405, 19, 30, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(406, 19, 30, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(407, 19, 28, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(408, 19, 30, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(409, 19, 30, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(410, 19, 31, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(411, 19, 41, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(412, 19, 49, '1.00', '2022-07-08 19:02:15', '2022-07-08 19:02:15'),
(413, 19, 50, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(414, 19, 50, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(415, 19, 31, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(416, 19, 41, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(417, 19, 49, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(418, 19, 50, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(419, 19, 50, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(420, 19, 57, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(421, 19, 57, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(422, 19, 28, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(423, 19, 30, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(424, 19, 30, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(425, 19, 28, '1.00', '2022-07-08 19:02:16', '2022-07-08 19:02:16'),
(426, 19, 30, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(427, 19, 30, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(428, 19, 31, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(429, 19, 41, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(430, 19, 49, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(431, 19, 50, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(432, 19, 50, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(433, 19, 31, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(434, 19, 41, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(435, 19, 49, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(436, 19, 50, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(437, 19, 50, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(438, 19, 57, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(439, 19, 57, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(440, 20, 1, '1.00', '2022-07-08 19:02:17', '2022-07-08 19:02:17'),
(441, 20, 5, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(442, 20, 7, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(443, 20, 7, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(444, 20, 1, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(445, 20, 5, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(446, 20, 7, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(447, 20, 7, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(448, 20, 3, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(449, 20, 57, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(450, 20, 57, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(451, 20, 22, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(452, 20, 16, '1.00', '2022-07-08 19:02:18', '2022-07-08 19:02:18'),
(453, 20, 12, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(454, 20, 12, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(455, 20, 6, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(456, 20, 8, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(457, 20, 8, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(458, 20, 11, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(459, 20, 12, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(460, 20, 12, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(461, 20, 11, '1.00', '2022-07-08 19:02:19', '2022-07-08 19:02:19'),
(462, 20, 12, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(463, 20, 12, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(464, 20, 31, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(465, 20, 41, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(466, 20, 49, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(467, 20, 50, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(468, 20, 50, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(469, 20, 31, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(470, 20, 41, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(471, 20, 49, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(472, 20, 50, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(473, 20, 50, '1.00', '2022-07-08 19:02:20', '2022-07-08 19:02:20'),
(474, 20, 21, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(475, 20, 28, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(476, 20, 30, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(477, 20, 30, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(478, 20, 28, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(479, 20, 30, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(480, 20, 30, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(481, 20, 31, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(482, 20, 41, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(483, 20, 49, '1.00', '2022-07-08 19:02:21', '2022-07-08 19:02:21'),
(484, 20, 50, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(485, 20, 50, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(486, 20, 31, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(487, 20, 41, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(488, 20, 49, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(489, 20, 50, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(490, 20, 50, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(491, 20, 57, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(492, 20, 57, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(493, 20, 28, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(494, 20, 30, '1.00', '2022-07-08 19:02:22', '2022-07-08 19:02:22'),
(495, 20, 30, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(496, 20, 28, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(497, 20, 30, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(498, 20, 30, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(499, 20, 31, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(500, 20, 41, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(501, 20, 49, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(502, 20, 50, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(503, 20, 50, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(504, 20, 31, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(505, 20, 41, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(506, 20, 49, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(507, 20, 50, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(508, 20, 50, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(509, 20, 57, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(510, 20, 57, '1.00', '2022-07-08 19:02:23', '2022-07-08 19:02:23'),
(511, 21, 28, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(512, 21, 30, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(513, 21, 30, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(514, 21, 28, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(515, 21, 30, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(516, 21, 30, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(517, 21, 31, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(518, 21, 41, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(519, 21, 49, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(520, 21, 50, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(521, 21, 50, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(522, 21, 31, '1.00', '2022-07-08 19:02:24', '2022-07-08 19:02:24'),
(523, 21, 41, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(524, 21, 49, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(525, 21, 50, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(526, 21, 50, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(527, 21, 31, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(528, 21, 41, '1.00', '2022-07-08 19:02:25', '2022-07-08 19:02:25'),
(529, 21, 49, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(530, 21, 50, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(531, 21, 50, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(532, 21, 31, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(533, 21, 41, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(534, 21, 49, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(535, 21, 50, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(536, 21, 50, '1.00', '2022-07-08 19:02:26', '2022-07-08 19:02:26'),
(537, 22, 28, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(538, 22, 30, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(539, 22, 30, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(540, 22, 28, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(541, 22, 30, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(542, 22, 30, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(543, 22, 31, '1.00', '2022-07-08 19:02:27', '2022-07-08 19:02:27'),
(544, 22, 41, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(545, 22, 49, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(546, 22, 50, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(547, 22, 50, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(548, 22, 31, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(549, 22, 41, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(550, 22, 49, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(551, 22, 50, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(552, 22, 50, '1.00', '2022-07-08 19:02:28', '2022-07-08 19:02:28'),
(553, 22, 31, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(554, 22, 41, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(555, 22, 49, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(556, 22, 50, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(557, 22, 50, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(558, 22, 31, '1.00', '2022-07-08 19:02:29', '2022-07-08 19:02:29'),
(559, 22, 41, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(560, 22, 49, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(561, 22, 50, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(562, 22, 50, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(563, 23, 28, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(564, 23, 30, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(565, 23, 30, '1.00', '2022-07-08 19:02:30', '2022-07-08 19:02:30'),
(566, 23, 28, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(567, 23, 30, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(568, 23, 30, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(569, 23, 31, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(570, 23, 41, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(571, 23, 49, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(572, 23, 50, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(573, 23, 50, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(574, 23, 31, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(575, 23, 41, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(576, 23, 49, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(577, 23, 50, '1.00', '2022-07-08 19:02:31', '2022-07-08 19:02:31'),
(578, 23, 50, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(579, 23, 31, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(580, 23, 41, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(581, 23, 49, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(582, 23, 50, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(583, 23, 50, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(584, 23, 31, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(585, 23, 41, '1.00', '2022-07-08 19:02:32', '2022-07-08 19:02:32'),
(586, 23, 49, '1.00', '2022-07-08 19:02:33', '2022-07-08 19:02:33'),
(587, 23, 50, '1.00', '2022-07-08 19:02:33', '2022-07-08 19:02:33'),
(588, 23, 50, '1.00', '2022-07-08 19:02:33', '2022-07-08 19:02:33'),
(589, 24, 28, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(590, 24, 30, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(591, 24, 30, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(592, 24, 28, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(593, 24, 30, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(594, 24, 30, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(595, 24, 31, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(596, 24, 41, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(597, 24, 49, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(598, 24, 50, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(599, 24, 50, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(600, 24, 31, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(601, 24, 41, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(602, 24, 49, '1.00', '2022-07-08 19:02:34', '2022-07-08 19:02:34'),
(603, 24, 50, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(604, 24, 50, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(605, 24, 31, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(606, 24, 41, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(607, 24, 49, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(608, 24, 50, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(609, 24, 50, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(610, 24, 31, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(611, 24, 41, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(612, 24, 49, '1.00', '2022-07-08 19:02:35', '2022-07-08 19:02:35'),
(613, 24, 50, '1.00', '2022-07-08 19:02:36', '2022-07-08 19:02:36'),
(614, 24, 50, '1.00', '2022-07-08 19:02:36', '2022-07-08 19:02:36'),
(615, 29, 1, '1.00', '2022-07-08 19:02:42', '2022-07-08 19:02:42'),
(616, 29, 5, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(617, 29, 7, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(618, 29, 7, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(619, 29, 1, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(620, 29, 5, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(621, 29, 7, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(622, 29, 7, '1.00', '2022-07-08 19:02:43', '2022-07-08 19:02:43'),
(623, 30, 1, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(624, 30, 5, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(625, 30, 7, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(626, 30, 7, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(627, 30, 1, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(628, 30, 5, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(629, 30, 7, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(630, 30, 7, '1.00', '2022-07-08 19:02:45', '2022-07-08 19:02:45'),
(631, 31, 1, '1.00', '2022-07-08 19:02:46', '2022-07-08 19:02:46'),
(632, 31, 5, '1.00', '2022-07-08 19:02:46', '2022-07-08 19:02:46'),
(633, 31, 7, '1.00', '2022-07-08 19:02:46', '2022-07-08 19:02:46'),
(634, 31, 7, '1.00', '2022-07-08 19:02:47', '2022-07-08 19:02:47'),
(635, 31, 1, '1.00', '2022-07-08 19:02:47', '2022-07-08 19:02:47'),
(636, 31, 5, '1.00', '2022-07-08 19:02:47', '2022-07-08 19:02:47'),
(637, 31, 7, '1.00', '2022-07-08 19:02:47', '2022-07-08 19:02:47'),
(638, 31, 7, '1.00', '2022-07-08 19:02:47', '2022-07-08 19:02:47'),
(639, 32, 1, '1.00', '2022-07-08 19:02:48', '2022-07-08 19:02:48'),
(640, 32, 5, '1.00', '2022-07-08 19:02:48', '2022-07-08 19:02:48'),
(641, 32, 7, '1.00', '2022-07-08 19:02:48', '2022-07-08 19:02:48'),
(642, 32, 7, '1.00', '2022-07-08 19:02:48', '2022-07-08 19:02:48'),
(643, 32, 1, '1.00', '2022-07-08 19:02:49', '2022-07-08 19:02:49'),
(644, 32, 5, '1.00', '2022-07-08 19:02:49', '2022-07-08 19:02:49'),
(645, 32, 7, '1.00', '2022-07-08 19:02:49', '2022-07-08 19:02:49'),
(646, 32, 7, '1.00', '2022-07-08 19:02:49', '2022-07-08 19:02:49');

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
-- Estructura para la vista `lista_mantenimiento`
--
DROP TABLE IF EXISTS `lista_mantenimiento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_mantenimiento`  AS SELECT `wod`.`work_order_id` AS `work_order_id`, `t`.`task` AS `task`, ifnull((select `c`.`component` from (`component_implement` `ci` join `components` `c` on(`c`.`id` = `ci`.`component_id`)) where `ci`.`id` = `wod`.`component_implement_id`),(select `c`.`component` from ((`component_part` `cp` join `component_implement` `ci` on(`ci`.`id` = `cp`.`component_implement_id`)) join `components` `c` on(`c`.`id` = `cp`.`part`)) where `cp`.`id` = `wod`.`component_part_id`)) AS `componente`, ifnull((select `p`.`component` from (`component_part` `cp` join `components` `p` on(`p`.`id` = `cp`.`part`)) where `cp`.`id` = `wod`.`component_part_id`),'GENERAL') AS `pieza` FROM (`work_order_details` `wod` join `tasks` `t` on(`wod`.`task_id` = `t`.`id`))  ;

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
  ADD UNIQUE KEY `components_component_unique` (`component`),
  ADD KEY `components_system_id_foreign` (`system_id`);

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
-- Indices de la tabla `component_work_order_detail`
--
ALTER TABLE `component_work_order_detail`
  ADD PRIMARY KEY (`id`),
  ADD KEY `component_work_order_detail_component_id_foreign` (`component_id`),
  ADD KEY `component_work_order_detail_work_order_detail_id_foreign` (`work_order_detail_id`);

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
  ADD KEY `epp_work_order_work_order_id_foreign` (`work_order_id`) USING BTREE,
  ADD KEY `epp_work_order_epp_id_work_order_id_index` (`epp_id`,`work_order_id`) USING BTREE;

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
  ADD KEY `order_request_new_items_measurement_unit_id_foreign` (`measurement_unit_id`),
  ADD KEY `order_request_new_items_item_id_foreign` (`item_id`);

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
  ADD KEY `tasks_component_id_foreign` (`component_id`);

--
-- Indices de la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  ADD PRIMARY KEY (`id`),
  ADD KEY `task_required_materials_task_id_foreign` (`task_id`),
  ADD KEY `task_required_materials_item_id_foreign` (`item_id`);

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
  ADD KEY `work_order_details_task_id_foreign` (`task_id`),
  ADD KEY `work_order_details_component_implement_id_foreign` (`component_implement_id`),
  ADD KEY `work_order_details_component_part_id_foreign` (`component_part_id`);

--
-- Indices de la tabla `work_order_required_materials`
--
ALTER TABLE `work_order_required_materials`
  ADD PRIMARY KEY (`id`),
  ADD KEY `work_order_required_materials_work_order_id_foreign` (`work_order_id`),
  ADD KEY `work_order_required_materials_item_id_foreign` (`item_id`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `brands`
--
ALTER TABLE `brands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `component_part`
--
ALTER TABLE `component_part`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=145;

--
-- AUTO_INCREMENT de la tabla `component_part_model`
--
ALTER TABLE `component_part_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `component_work_order_detail`
--
ALTER TABLE `component_work_order_detail`
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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `epp_work_order`
--
ALTER TABLE `epp_work_order`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=445;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

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
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=422;

--
-- AUTO_INCREMENT de la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT de la tabla `risk_task_order`
--
ALTER TABLE `risk_task_order`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=87;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `systems`
--
ALTER TABLE `systems`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT de la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=507;

--
-- AUTO_INCREMENT de la tabla `work_order_required_materials`
--
ALTER TABLE `work_order_required_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=647;

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
  ADD CONSTRAINT `components_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `components_system_id_foreign` FOREIGN KEY (`system_id`) REFERENCES `systems` (`id`);

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
-- Filtros para la tabla `component_work_order_detail`
--
ALTER TABLE `component_work_order_detail`
  ADD CONSTRAINT `component_work_order_detail_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`),
  ADD CONSTRAINT `component_work_order_detail_work_order_detail_id_foreign` FOREIGN KEY (`work_order_detail_id`) REFERENCES `work_order_details` (`id`);

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
  ADD CONSTRAINT `epp_work_order_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

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
  ADD CONSTRAINT `order_request_new_items_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
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
-- Filtros para la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  ADD CONSTRAINT `task_required_materials_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `task_required_materials_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`);

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
  ADD CONSTRAINT `work_order_details_component_implement_id_foreign` FOREIGN KEY (`component_implement_id`) REFERENCES `component_implement` (`id`),
  ADD CONSTRAINT `work_order_details_component_part_id_foreign` FOREIGN KEY (`component_part_id`) REFERENCES `component_part` (`id`),
  ADD CONSTRAINT `work_order_details_task_id_foreign` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`),
  ADD CONSTRAINT `work_order_details_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

--
-- Filtros para la tabla `work_order_required_materials`
--
ALTER TABLE `work_order_required_materials`
  ADD CONSTRAINT `work_order_required_materials_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `work_order_required_materials_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `liberar_material_event` ON SCHEDULE EVERY 1 MONTH STARTS '2022-05-18 09:00:54' ON COMPLETION NOT PRESERVE DISABLE DO UPDATE operator_assigned_stocks SET state = "LIBERADO", quantity = 0, price = 0 WHERE DATE_ADD(updated_at, INTERVAL 3 MONTH) < CURRENT_TIMESTAMP AND quantity > 0$$

CREATE DEFINER=`root`@`localhost` EVENT `asignar_monto_ceco` ON SCHEDULE EVERY 1 MONTH STARTS '2022-06-01 00:00:00' ON COMPLETION NOT PRESERVE DISABLE DO UPDATE ceco_allocation_amounts SET caa.is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

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
            	UPDATE order_request_details r SET r.quantity = r.quantity + cantidad_pieza WHERE r.order_request_id = pedido AND r.item_id = item_pieza;
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

CREATE DEFINER=`root`@`localhost` EVENT `cerrarPedido` ON SCHEDULE EVERY 1 DAY STARTS '2022-07-01 00:00:00' ON COMPLETION NOT PRESERVE DISABLE DO BEGIN
/*---Variables para la fecha para cerrar el pedido----------*/
DECLARE fecha_solicitud INT;
DECLARE fecha_cerrar_solicitud DATE;
/*-------Obtener la fecha para cerrar el pedido-------*/
SELECT id,close_request INTO fecha_solicitud, fecha_cerrar_solicitud FROM order_dates r WHERE r.state = "ABIERTO" ORDER BY open_request ASC LIMIT 1;
/*----Validar la fecha de cierre de pedido-----------*/
IF(fecha_cerrar_solicitud <= NOW()) THEN
/*--------Cerrar pedido----------------*/
UPDATE order_dates SET state = "CERRADO" WHERE state = "ABIERTO" LIMIT 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` EVENT `Listar_mantenimientos_programados` ON SCHEDULE EVERY 1 DAY STARTS '2022-07-05 00:21:00' ON COMPLETION NOT PRESERVE DISABLE DO BEGIN
/*-----------VARIABLES PARA DETENER CICLOS--------------*/
DECLARE material_final INT DEFAULT 0;
DECLARE implemento_final INT DEFAULT 0;
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final INT DEFAULT 0;
DECLARE tarea_final INT DEFAULT 0;
/*--------------VARIABLES CABECERA ORDEN DE TRABAJO-------------------*/
DECLARE implemento INT;
DECLARE responsable INT;
DECLARE ubicacion INT;
DECLARE fecha INT;
/*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
DECLARE orden_trabajo INT;
DECLARE tarea INT;
DECLARE componente_del_implemento INT;
DECLARE pieza_del_componente INT;
/*--------------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO------------------------*/
DECLARE modelo_del_implemento INT;
/*--------------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE---------*/
DECLARE componente INT;
DECLARE horas_componente DECIMAL(8,2);
DECLARE tiempo_vida_componente DECIMAL(8,2);
DECLARE cantidad_componente INT;
DECLARE item_componente INT;
/*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
DECLARE pieza INT;
DECLARE horas_pieza DECIMAL(8,2);
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza INT;
DECLARE item_pieza INT;
/*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id FROM implements;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
/*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
OPEN cursor_implementos;
    bucle_implementos:LOOP
        IF implemento_final = 1 THEN
            LEAVE bucle_implementos;
        END IF;
    /*--OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ----------------------*/
        FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable,ubicacion;
    /*-----------CREAR LA CABECERA DE ORDEN DE TRABAJO SI NO HAY EN LOS SIGUIENTES 3 DÍAS---------------*/
        IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE" AND date <= DATE_ADD(NOW(),INTERVAL 3 DAY)) THEN
            INSERT INTO work_orders (implement_id,user_id,location_id,date,maintenance) VALUES(implemento,responsable,ubicacion,DATE_ADD(NOW(),INTERVAL 3 DAY),1);
        /*-----------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------*/
            SELECT id INTO orden_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE";
    /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
            BEGIN
                DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                /*------------ABRIR CURSOR COMPONENTES---------------*/
                OPEN cursor_componentes;
                    bucle_componentes:LOOP
                        IF componente_final = 1 THEN
                            LEAVE bucle_componentes;
                        END IF;
                        /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                        FETCH cursor_componentes INTO componente;
                        /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                        IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                            INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                        END IF;
                        /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                        SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                        /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                        SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                        /*---------------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DIAS-----------------------------------*/
                        SELECT FLOOR((horas_componente+24)/tiempo_vida_componente) INTO cantidad_componente;
                        /*---------------TAREA DE RECAMBIO SI LO NECESITA-------------------------------*/
                        IF(cantidad_componente > 0) THEN
                            /*-----------OBTENER TAREA DE RECAMBIO DEL COMPONENTE----------------------*/
                            SELECT id INTO tarea FROM tasks WHERE component_id = componente AND task = "RECAMBIO" LIMIT 1;
                            /*-----------CREAR TAREA DE RECAMBIO PARA EL COMPONENTE---------------------*/
                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "RECOMENDADO" AND component_implement_id = componente_del_implemento) THEN
                                INSERT INTO work_order_details (work_order_id,task_id,state,component_implement_id ) VALUES (orden_trabajo,tarea,"RECOMENDADO",componente_del_implemento);
                            END IF;
                            /*------------MARCAR COMO NO VALIDADO HASTA QUE EL SUPERVISOR LO APRUEBE O LO RECHACE-------------*/
                            IF NOT EXISTS(SELECT * FROM work_orders WHERE id = orden_trabajo AND state = "NO VALIDADO") THEN
                                UPDATE work_orders SET state = "NO VALIDADO" WHERE id = orden_trabajo;
                            END IF;
                            /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                        /*----------------RUTINARIO SI NO NECESITA RECAMBIO----------------------------*/
                        ELSE
                            /*------------CURSOR PARA CREAR EL RUTINARIO POR CADA COMPONENTE----------------*/
                            BEGIN
                                DECLARE cursor_componente_tareas CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND task <> "RECAMBIO";
                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                /*--------ABRIR CURSOR DE TAREAS DEL COMPONENTE------------------------------*/
                                OPEN cursor_componente_tareas;
                                    bucle_componente_tareas:LOOP
                                        IF tarea_final = 1 THEN
                                            LEAVE bucle_componente_tareas;
                                        END IF;
                                        /*----------------OBTENER TAREA DEL COMPONENTE-----------------------------------------------*/
                                        FETCH cursor_componente_tareas INTO tarea;
                                        /*-------------INSERTAR RUTINARIO DE TAREAS EN EL DETALLE DE LA ORDEN DE TRABAJO-----------------------*/
                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "ACEPTADO" AND component_implement_id = componente_del_implemento) THEN
                                            INSERT INTO work_order_details (work_order_id,task_id,component_implement_id ) VALUES (orden_trabajo,tarea,componente_del_implemento);
                                        END IF;
                                        IF EXISTS(SELECT * FROM task_required_materials WHERE task_id = tarea) THEN
                                            BEGIN
                                                DECLARE cursor_materiales CURSOR FOR SELECT item_id FROM task_required_materials WHERE task_id = tarea;
                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                OPEN cursor_materiales;
                                                    bucle_materiales:LOOP
                                                        IF material_final = 1 THEN
                                                            LEAVE bucle_materiales;
                                                        END IF;
                                                        FETCH cursor_materiales INTO item_componente;
                                                        INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                                                    END LOOP bucle_materiales;
                                                CLOSE cursor_materiales;
                                                SELECT 0 INTO material_final;
                                            END;
                                        END IF;
                                    END LOOP bucle_componente_tareas;
                                CLOSE cursor_componente_tareas;
                                /*------------PONER TAREA FINAL A 0----------------------------------------*/
                                SELECT 0 INTO tarea_final;
                            END;
                            /*-----------FIN DEL RUTNARIO DEL COMPONENTE-------------------------------------*/
                            /*-------------INICIO DE LAS TAREAS DE LA PIEZA---------------------------------*/
                            /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                            BEGIN
                                DECLARE cursor_piezas CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                OPEN cursor_piezas;
                                    bucle_piezas:LOOP
                                        IF pieza_final = 1 THEN
                                            LEAVE bucle_piezas;
                                        END IF;
                                        /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                        FETCH cursor_piezas INTO pieza;
                                        /*----------------COMPROBAR SI EXISTE LA PEIZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                        IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                            INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                        END IF;
                                        /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                        SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                        /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                        SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                        /*---------------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DIAS-----------------------------------*/
                                        SELECT FLOOR((horas_pieza+24)/tiempo_vida_pieza) INTO cantidad_pieza;
                                        /*---------------TAREA DE RECAMBIO SI LO NECESITA-------------------------------*/
                                        IF(cantidad_pieza > 0) THEN
                                            /*-----------OBTENER TAREA DE RECAMBIO DE LA PIEZA----------------------*/
                                            SELECT id INTO tarea FROM tasks WHERE component_id = pieza AND task = "RECAMBIO" LIMIT 1;
                                            /*-----------CREAR TAREA DE RECAMBIO PARA LA PIEZA---------------------*/
                                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "RECOMENDADO" AND component_part_id = pieza_del_componente) THEN
                                                INSERT INTO work_order_details (work_order_id,task_id,state,component_part_id) VALUES (orden_trabajo,tarea,"RECOMENDADO",pieza_del_componente);
                                            END IF;
                                            /*-----------MARCAR COMO NO VALIDADO HASTA QUE EL SUPERVISOR LO APRUEBE O LO RECHACE-----------------*/
                                            IF NOT EXISTS(SELECT * FROM work_orders WHERE id = orden_trabajo AND state = "NO VALIDADO") THEN
                                                UPDATE work_orders SET state = "NO VALIDADO" WHERE id = orden_trabajo;
                                            END IF;
                                            /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                        /*--------------RUTINARIO SI NO NECESITA RECAMBIO---------------------------------*/
                                        ELSE
                                        /*--------------CURSOR PARA CREAR EL RUTINARIO DE CADA COMPONENTE-----------------*/
                                            BEGIN
                                                DECLARE cursor_pieza_tareas CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND task <> "RECAMBIO";
                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                /*--------ABRIR CURSOR DE TAREAS DEL COMPONENTE------------------------------*/
                                                OPEN cursor_pieza_tareas;
                                                    bucle_pieza_tareas:LOOP
                                                        IF tarea_final = 1 THEN
                                                            LEAVE bucle_pieza_tareas;
                                                        END IF;
                                                        /*----------------OBTENER TAREA DE LA PIEZA-----------------------------------------------*/
                                                        FETCH cursor_pieza_tareas INTO tarea;
                                                        /*-------------INSERTAR RUTINARIO DE TAREAS EN EL DETALLE DE LA ORDEN DE TRABAJO-----------------------*/
                                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_trabajo AND task_id = tarea AND state = "ACEPTADO" AND component_part_id  = pieza_del_componente) THEN
                                                            INSERT INTO work_order_details (work_order_id,task_id,component_part_id) VALUES (orden_trabajo,tarea,pieza_del_componente);
                                                        END IF;
                                                        IF EXISTS(SELECT * FROM task_required_materials WHERE task_id = tarea) THEN
                                                            BEGIN
                                                                DECLARE cursor_materiales CURSOR FOR SELECT item_id FROM task_required_materials WHERE task_id = tarea;
                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                OPEN cursor_materiales;
                                                                    bucle_materiales:LOOP
                                                                        IF material_final = 1 THEN
                                                                            LEAVE bucle_materiales;
                                                                        END IF;
                                                                        FETCH cursor_materiales INTO item_pieza;
                                                                        INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                                                    END LOOP bucle_materiales;
                                                                CLOSE cursor_materiales;
                                                                SELECT 0 INTO material_final;
                                                            END;
                                                        END IF;
                                                    END LOOP bucle_pieza_tareas;
                                                CLOSE cursor_pieza_tareas;
                                                /*------------PONER TAREA FINAL A 0----------------------------------------*/
                                                SELECT 0 INTO tarea_final;
                                            END;
                                        END IF;
                                    END LOOP bucle_piezas;
                                CLOSE cursor_piezas;
                                /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                SELECT 0 INTO pieza_final;
                            END;
                        END IF;
                    END LOOP bucle_componentes;
                CLOSE cursor_componentes;
                /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                SELECT 0 INTO componente_final;
            END;
        END IF;
    END LOOP bucle_implementos;
CLOSE cursor_implementos;
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
