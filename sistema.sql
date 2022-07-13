-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 13-07-2022 a las 07:30:10
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
CREATE DEFINER=`root`@`localhost` PROCEDURE `asignarMontoCeco` ()   UPDATE ceco_allocation_amounts SET is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

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
                        IF horas_componente >= tiempo_vida_componente THEN
                            SELECT tiempo_vida_componente INTO horas_componente;
                        END IF;
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
                            IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_componente) THEN
                                INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                            ELSE
                                UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_componente;
                            END IF;
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
                                                        /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                                        IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_componente) THEN
                                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                                                        ELSE
                                                            UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_componente;
                                                        END IF;
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
                                        IF horas_pieza >= tiempo_vida_pieza THEN
                                            SELECT tiempo_vida_pieza INTO horas_pieza;
                                        END IF;
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
                                            IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_pieza) THEN
                                                INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                            ELSE
                                                UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_pieza;
                                            END IF;
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
                                                                        /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                                                        IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_pieza) THEN
                                                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                                                        ELSE
                                                                            UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_pieza;
                                                                        END IF;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_materiales_pedido` ()   BEGIN
    /*-------Variables para la fecha para abrir el pedido--------*/
    DECLARE fecha_solicitud INT;
    DECLARE fecha_abrir_solicitud DATE;
    /*-------Obtener la fecha para abrir el pedido-------*/
    SELECT id,open_request INTO fecha_solicitud, fecha_abrir_solicitud FROM order_dates r WHERE r.state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
    IF(fecha_abrir_solicitud <= NOW()) THEN
        BEGIN
        /*-----------VARIABLES PARA DETENER CICLOS--------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_final INT DEFAULT 0;
        DECLARE pieza_final INT DEFAULT 0;
        /*--------------VARIABLES CABECERA SOLICITUD DE PEDIDO-------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        /*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
        DECLARE solicitud_pedido INT;
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
        DECLARE precio_componente DECIMAL(8,2);
        /*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
        DECLARE pieza INT;
        DECLARE horas_pieza DECIMAL(8,2);
        DECLARE tiempo_vida_pieza DECIMAL(8,2);
        DECLARE cantidad_pieza INT;
        DECLARE item_pieza INT;
        DECLARE precio_pieza DECIMAL(8,2);
        /*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
        DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id FROM implements;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        /*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
        OPEN cursor_implementos;
            bucle_implementos:LOOP
                IF implemento_final = 1 THEN
                    LEAVE bucle_implementos;
                END IF;
            /*-----------------------------------OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ---------------------------*/
                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
            /*-----------CREAR LA CABECERA DE LA SOLICITUD DE PEDIDO SI NO EXISTE EN LA FECHA ASIGNADA---------------*/
                IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND order_date_id = fecha_solicitud) THEN
                    INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
                /*-----------OBTENER ID DE LA CABECERA DE LA SOLICITUD DE PEDIDO-------------------*/
                    SELECT id INTO solicitud_pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND order_date_id = fecha_solicitud;
            /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
                    BEGIN
                        DECLARE cursor_componentes CURSOR FOR SELECT cim.component_id,i.estimated_price FROM component_implement_model cim INNER JOIN components c ON c.id = cim.component_id INNER JOIN items i ON i.id = c.item_id WHERE cim.implement_model_id = modelo_del_implemento;
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                        /*------------ABRIR CURSOR COMPONENTES---------------*/
                        OPEN cursor_componentes;
                            bucle_componentes:LOOP
                                IF componente_final = 1 THEN
                                    LEAVE bucle_componentes;
                                END IF;
                                /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                                FETCH cursor_componentes INTO componente,precio_componente;
                                /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                                IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                                    INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                                END IF;
                                /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                                SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                                SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                                IF horas_componente >= tiempo_vida_componente THEN
                                    SELECT tiempo_vida_componente INTO horas_componente;
                                END IF;
                                /*---------------CALCULAR CUANTOS RECAMBIOS NECESITARÁ EN 2 MESES-----------------------------------*/
                                SELECT FLOOR((horas_componente+336)/tiempo_vida_componente) INTO cantidad_componente;
                                /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                IF(cantidad_componente > 0) THEN
                                    /*-----------PEDIR MATERIAL---------------------*/
                                    IF NOT EXISTS(SELECT * FROM order_request_details WHERE order_request_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE") THEN
                                        INSERT INTO order_request_details (order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_componente,cantidad_componente,precio_componente);
                                    ELSE
                                        UPDATE order_request_details SET quantity = quantity + cantidad_componente WHERE order_request_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE";
                                    END IF;
                                END IF;
                                    /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                                BEGIN
                                    DECLARE cursor_piezas CURSOR FOR SELECT cpm.part,i.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items i ON i.id = c.item_id WHERE cpm.component = componente;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                    /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                    OPEN cursor_piezas;
                                        bucle_piezas:LOOP
                                            IF pieza_final = 1 THEN
                                                LEAVE bucle_piezas;
                                            END IF;
                                                /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                            FETCH cursor_piezas INTO pieza,precio_pieza;
                                                /*----------------COMPROBAR SI EXISTE LA PIEZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                            IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                            END IF;
                                            /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                            SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                            /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                            SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                            IF(horas_pieza >= tiempo_vida_pieza)THEN
                                                SELECT tiempo_vida_pieza INTO horas_pieza;
                                            END IF;
                                            /*---------------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES-----------------------------------*/
                                            SELECT FLOOR((horas_pieza+336)/tiempo_vida_pieza) INTO cantidad_pieza;
                                            /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                            IF(cantidad_pieza > 0) THEN
                                                /*-----------PEDIR MATERIAL---------------------*/
                                                IF NOT EXISTS(SELECT * FROM order_request_details WHERE order_request_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE") THEN
                                                    INSERT INTO order_request_details (order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,(cantidad_pieza-cantidad_componente),precio_pieza);
                                                ELSE
                                                    UPDATE order_request_details SET quantity = (quantity + cantidad_pieza - cantidad_componente) WHERE order_request_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE";
                                                END IF;
                                            END IF;
                                        END LOOP bucle_piezas;
                                    CLOSE cursor_piezas;
                                    /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                    SELECT 0 INTO pieza_final;
                                END;
                            END LOOP bucle_componentes;
                        CLOSE cursor_componentes;
                        /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                        SELECT 0 INTO componente_final;
                    END;
                END IF;
            END LOOP bucle_implementos;
        CLOSE cursor_implementos;
        /*----------ABRIR FECHA DE PEDIDO-------------------*/
        UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
        END;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_prereserva` ()   BEGIN
    /*-------Variables para la fecha para abrir el pedido--------*/
    DECLARE fecha_solicitud INT;
    DECLARE fecha_abrir_solicitud DATE;
    /*-------Obtener la fecha para abrir el pedido-------*/
    SELECT id,open_pre_stockpile INTO fecha_solicitud, fecha_abrir_solicitud FROM pre_stockpile_dates WHERE state = "PENDIENTE" ORDER BY open_pre_stockpile ASC LIMIT 1;
    IF(fecha_abrir_solicitud <= NOW()) THEN
        BEGIN
        /*-----------VARIABLES PARA DETENER CICLOS--------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_final INT DEFAULT 0;
        DECLARE pieza_final INT DEFAULT 0;
        /*--------------VARIABLES CABECERA SOLICITUD DE PEDIDO-------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        DECLARE ceco INT;
        DECLARE almacen INT;
        /*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
        DECLARE solicitud_pedido INT;
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
        DECLARE precio_componente DECIMAL(8,2);
        /*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
        DECLARE pieza INT;
        DECLARE horas_pieza DECIMAL(8,2);
        DECLARE tiempo_vida_pieza DECIMAL(8,2);
        DECLARE cantidad_pieza INT;
        DECLARE item_pieza INT;
        DECLARE precio_pieza DECIMAL(8,2);
        /*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
        DECLARE cursor_implementos CURSOR FOR SELECT i.id,i.implement_model_id,i.user_id,i.ceco_id,w.id FROM implements i INNER JOIN warehouses w ON w.location_id = i.location_id;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        /*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
        OPEN cursor_implementos;
            bucle_implementos:LOOP
                IF implemento_final = 1 THEN
                    LEAVE bucle_implementos;
                END IF;
            /*-----------------------------------OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ---------------------------*/
                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable,ceco,almacen;
            /*-----------CREAR LA CABECERA DE LA SOLICITUD DE PEDIDO SI NO EXISTE EN LA FECHA ASIGNADA---------------*/
                IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_solicitud) THEN
                    INSERT INTO pre_stockpiles(user_id,implement_id,ceco_id,pre_stockpile_date_id) VALUES (responsable,implemento,ceco,fecha_solicitud);
                /*-----------OBTENER ID DE LA CABECERA DE LA SOLICITUD DE PEDIDO-------------------*/
                    SELECT id INTO solicitud_pedido FROM pre_stockpiles WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_solicitud;
            /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
                    BEGIN
                        DECLARE cursor_componentes CURSOR FOR SELECT cim.component_id,i.estimated_price FROM component_implement_model cim INNER JOIN components c ON c.id = cim.component_id INNER JOIN items i ON i.id = c.item_id WHERE cim.implement_model_id = modelo_del_implemento;
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                        /*------------ABRIR CURSOR COMPONENTES---------------*/
                        OPEN cursor_componentes;
                            bucle_componentes:LOOP
                                IF componente_final = 1 THEN
                                    LEAVE bucle_componentes;
                                END IF;
                                /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                                FETCH cursor_componentes INTO componente,precio_componente;
                                /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                                IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                                    INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                                END IF;
                                /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                                SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                                SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                                IF horas_componente >= tiempo_vida_componente THEN
                                    SELECT tiempo_vida_componente INTO horas_componente;
                                END IF;
                                /*---------------CALCULAR CUANTOS RECAMBIOS NECESITARÁ EN 2 MESES-----------------------------------*/
                                SELECT FLOOR((horas_componente+168)/tiempo_vida_componente) INTO cantidad_componente;
                                /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                IF(cantidad_componente > 0) THEN
                                    /*-----------PEDIR MATERIAL---------------------*/
                                    IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE") THEN
                                        INSERT INTO pre_stockpile_details (pre_stockpile_id,item_id,quantity,price,warehouse_id) VALUES (solicitud_pedido,item_componente,cantidad_componente,precio_componente,almacen);
                                    ELSE
                                        UPDATE pre_stockpile_details SET quantity = quantity + cantidad_componente WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE";
                                    END IF;
                                END IF;
                                    /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                                BEGIN
                                    DECLARE cursor_piezas CURSOR FOR SELECT cpm.part,i.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items i ON i.id = c.item_id WHERE cpm.component = componente;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                    /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                    OPEN cursor_piezas;
                                        bucle_piezas:LOOP
                                            IF pieza_final = 1 THEN
                                                LEAVE bucle_piezas;
                                            END IF;
                                                /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                            FETCH cursor_piezas INTO pieza,precio_pieza;
                                                /*----------------COMPROBAR SI EXISTE LA PIEZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                            IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                            END IF;
                                            /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                            SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                            /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                            SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                            IF(horas_pieza >= tiempo_vida_pieza)THEN
                                                SELECT tiempo_vida_pieza INTO horas_pieza;
                                            END IF;
                                            /*---------------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES-----------------------------------*/
                                            SELECT FLOOR((horas_pieza+168)/tiempo_vida_pieza) INTO cantidad_pieza;
                                            /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                            IF(cantidad_pieza > 0) THEN
                                                /*-----------PEDIR MATERIAL---------------------*/
                                                IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE") THEN
                                                    INSERT INTO pre_stockpile_details (pre_stockpile_id,item_id,quantity,price,warehouse_id) VALUES (solicitud_pedido,item_pieza,cantidad_pieza,precio_pieza,almacen);
                                                ELSE
                                                    UPDATE pre_stockpile_details SET quantity = (quantity + cantidad_pieza - cantidad_componente) WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE";
                                                END IF;
                                            END IF;
                                        END LOOP bucle_piezas;
                                    CLOSE cursor_piezas;
                                    /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                    SELECT 0 INTO pieza_final;
                                END;
                            END LOOP bucle_componentes;
                        CLOSE cursor_componentes;
                        /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                        SELECT 0 INTO componente_final;
                    END;
                END IF;
            END LOOP bucle_implementos;
        CLOSE cursor_implementos;
        /*----------ABRIR FECHA DE PEDIDO-------------------*/
        UPDATE pre_stockpile_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
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

--
-- Volcado de datos para la tabla `affected_movement`
--

INSERT INTO `affected_movement` (`id`, `operator_stock_id`, `operator_stock_detail_id`, `operator_assigned_stock_id`, `stock_id`) VALUES
(33, 22, 34, 33, 20),
(34, 23, 35, 34, 21),
(35, 24, 36, 35, 22),
(36, 25, 37, 36, 23),
(37, 26, 38, 37, 24),
(38, 27, 39, 38, 24),
(39, 28, 40, 39, 24),
(40, 29, 41, 40, 25),
(41, 30, 42, 41, 25),
(42, 31, 43, 42, 26),
(43, 32, 44, 43, 27),
(44, 33, 45, 44, 28),
(45, 34, 46, 45, 29),
(46, 35, 47, 46, 30),
(47, 36, 48, 47, 31),
(48, 37, 49, 48, 32),
(49, 38, 50, 49, 32),
(50, 39, 51, 50, 32),
(51, 40, 52, 51, 32),
(52, 41, 53, 52, 32),
(53, 42, 54, 53, 33),
(54, 43, 55, 54, 33),
(55, 44, 56, 55, 33),
(56, 45, 57, 56, 34),
(57, 46, 58, 57, 35),
(58, 47, 59, 58, 36),
(59, 48, 60, 59, 37),
(60, 49, 61, 60, 38),
(61, 50, 62, 61, 38),
(62, 51, 63, 62, 38),
(63, 52, 64, 63, 39),
(64, 53, 65, 64, 40),
(65, 54, 66, 65, 41),
(66, 55, 67, 66, 42),
(67, 56, 69, 67, 43),
(68, 57, 70, 68, 44),
(69, 59, 71, 69, 45),
(70, 59, 72, 70, 45);

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
(43, 'crossfire', '2022-07-01 20:48:48', '2022-07-01 20:48:48'),
(44, 'taito', '2022-07-09 23:15:43', '2022-07-09 23:15:43'),
(45, 'arduino', '2022-07-11 20:38:17', '2022-07-11 20:38:17');

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
  `warehouse_amount` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cecos`
--

INSERT INTO `cecos` (`id`, `code`, `description`, `location_id`, `amount`, `warehouse_amount`, `created_at`, `updated_at`) VALUES
(1, '584070', 'magni', 1, '2533.00', '4576.49', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '297800', 'distinctio', 1, '2086.00', '5005.28', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '421733', 'maxime', 2, '2139.00', '14963.28', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '771845', 'quasi', 2, '1028.00', '5855.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '057182', 'inventore', 3, '1134.00', '2050.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '797793', 'neque', 3, '2024.00', '3600.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '931896', 'exercitationem', 4, '1545.00', '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '647952', 'recusandae', 4, '2440.00', '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '182653', 'quam', 5, '2046.00', '4100.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(10, '983918', 'voluptas', 5, '1508.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(11, '690932', 'id', 6, '0.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '066884', 'ut', 6, '0.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '952893', 'quae', 7, '0.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '579950', 'consequatur', 7, '0.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(15, '790388', 'modi', 8, '0.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '236075', 'corrupti', 8, '0.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41');

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
(1, 1, '2533.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(2, 2, '2086.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(3, 3, '2139.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(4, 4, '1028.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(5, 5, '1134.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(6, 6, '2024.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(7, 7, '1545.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(8, 8, '2440.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(9, 9, '2046.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
(10, 10, '1508.00', 1, '2022-07-01', '2022-06-20 21:21:51', '2022-06-20 21:21:51'),
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
  `work_order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `component_implement`
--

INSERT INTO `component_implement` (`id`, `component_id`, `implement_id`, `hours`, `state`, `work_order_id`, `created_at`, `updated_at`) VALUES
(97, 28, 3, '807.50', 'PENDIENTE', NULL, '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(98, 8, 3, '807.50', 'PENDIENTE', NULL, '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(99, 20, 3, '807.50', 'PENDIENTE', NULL, '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(100, 28, 4, '467.50', 'PENDIENTE', NULL, '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(101, 8, 4, '467.50', 'PENDIENTE', NULL, '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(102, 20, 4, '467.50', 'PENDIENTE', NULL, '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(103, 28, 1, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:05:56', '2022-07-09 15:05:56'),
(104, 8, 1, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:07', '2022-07-09 15:42:07'),
(105, 20, 1, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(106, 28, 2, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(107, 8, 2, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(108, 20, 2, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(109, 20, 5, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(110, 19, 5, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(111, 22, 5, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(112, 20, 6, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(113, 19, 6, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(114, 22, 6, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(115, 20, 7, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(116, 19, 7, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(117, 22, 7, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(118, 20, 8, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(119, 19, 8, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(120, 22, 8, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(121, 10, 9, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(122, 5, 9, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(123, 21, 9, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(124, 10, 10, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(125, 5, 10, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(126, 21, 10, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(127, 10, 11, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(128, 5, 11, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(129, 21, 11, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(130, 10, 12, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(131, 5, 12, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(132, 21, 12, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(133, 28, 13, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(134, 27, 13, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(135, 22, 13, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:23', '2022-07-09 15:42:23'),
(136, 28, 14, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(137, 27, 14, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(138, 22, 14, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(139, 28, 15, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(140, 27, 15, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(141, 22, 15, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(142, 28, 16, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(143, 27, 16, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(144, 22, 16, '0.00', 'PENDIENTE', NULL, '2022-07-09 15:42:28', '2022-07-09 15:42:28');

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
(145, 97, 2, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(146, 97, 13, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(147, 97, 33, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(148, 98, 4, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(149, 98, 11, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(150, 98, 23, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(151, 99, 4, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(152, 99, 29, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(153, 99, 33, '807.50', 'PENDIENTE', '2022-07-09 15:03:09', '2022-07-09 15:03:09'),
(154, 100, 2, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(155, 100, 13, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(156, 100, 33, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(157, 101, 4, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(158, 101, 11, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(159, 101, 23, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(160, 102, 4, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(161, 102, 29, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(162, 102, 33, '467.50', 'PENDIENTE', '2022-07-09 15:04:02', '2022-07-09 15:04:53'),
(163, 103, 2, '0.00', 'PENDIENTE', '2022-07-09 15:05:56', '2022-07-09 15:05:56'),
(164, 103, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:07', '2022-07-09 15:42:07'),
(165, 103, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:07', '2022-07-09 15:42:07'),
(166, 104, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:07', '2022-07-09 15:42:07'),
(167, 104, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:07', '2022-07-09 15:42:07'),
(168, 104, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(169, 105, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(170, 105, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(171, 105, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(172, 106, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:08', '2022-07-09 15:42:08'),
(173, 106, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(174, 106, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(175, 107, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(176, 107, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(177, 107, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(178, 108, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(179, 108, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(180, 108, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:09', '2022-07-09 15:42:09'),
(181, 109, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(182, 109, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(183, 109, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(184, 110, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(185, 110, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(186, 110, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:12', '2022-07-09 15:42:12'),
(187, 111, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(188, 111, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(189, 111, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(190, 112, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(191, 112, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(192, 112, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(193, 113, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(194, 113, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(195, 113, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:13', '2022-07-09 15:42:13'),
(196, 114, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(197, 114, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(198, 114, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(199, 115, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(200, 115, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(201, 115, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:14', '2022-07-09 15:42:14'),
(202, 116, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(203, 116, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(204, 116, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(205, 117, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(206, 117, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(207, 117, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(208, 118, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(209, 118, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(210, 118, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:15', '2022-07-09 15:42:15'),
(211, 119, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(212, 119, 4, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(213, 119, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(214, 120, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(215, 120, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(216, 120, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:16', '2022-07-09 15:42:16'),
(217, 121, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(218, 121, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(219, 121, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(220, 122, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(221, 122, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(222, 122, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(223, 123, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(224, 123, 17, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(225, 123, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:17', '2022-07-09 15:42:17'),
(226, 124, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(227, 124, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(228, 124, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(229, 125, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(230, 125, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(231, 125, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(232, 126, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(233, 126, 17, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(234, 126, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:18', '2022-07-09 15:42:18'),
(235, 127, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(236, 127, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(237, 127, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(238, 128, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(239, 128, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(240, 128, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:19', '2022-07-09 15:42:19'),
(241, 129, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(242, 129, 17, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(243, 129, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(244, 130, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(245, 130, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(246, 130, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:20', '2022-07-09 15:42:20'),
(247, 131, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(248, 131, 7, '0.00', 'PENDIENTE', '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(249, 131, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(250, 132, 3, '0.00', 'PENDIENTE', '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(251, 132, 17, '0.00', 'PENDIENTE', '2022-07-09 15:42:21', '2022-07-09 15:42:21'),
(252, 132, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(253, 133, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(254, 133, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(255, 133, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(256, 134, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(257, 134, 30, '0.00', 'PENDIENTE', '2022-07-09 15:42:22', '2022-07-09 15:42:22'),
(258, 134, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:23', '2022-07-09 15:42:23'),
(259, 135, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:23', '2022-07-09 15:42:23'),
(260, 135, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:23', '2022-07-09 15:42:23'),
(261, 135, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:23', '2022-07-09 15:42:23'),
(262, 136, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(263, 136, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(264, 136, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(265, 137, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(266, 137, 30, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(267, 137, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:24', '2022-07-09 15:42:24'),
(268, 138, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(269, 138, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(270, 138, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(271, 139, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:25', '2022-07-09 15:42:25'),
(272, 139, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(273, 139, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(274, 140, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(275, 140, 30, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(276, 140, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(277, 141, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(278, 141, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:26', '2022-07-09 15:42:26'),
(279, 141, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(280, 142, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(281, 142, 13, '0.00', 'PENDIENTE', '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(282, 142, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(283, 143, 11, '0.00', 'PENDIENTE', '2022-07-09 15:42:27', '2022-07-09 15:42:27'),
(284, 143, 30, '0.00', 'PENDIENTE', '2022-07-09 15:42:28', '2022-07-09 15:42:28'),
(285, 143, 33, '0.00', 'PENDIENTE', '2022-07-09 15:42:28', '2022-07-09 15:42:28'),
(286, 144, 2, '0.00', 'PENDIENTE', '2022-07-09 15:42:28', '2022-07-09 15:42:28'),
(287, 144, 23, '0.00', 'PENDIENTE', '2022-07-09 15:42:28', '2022-07-09 15:42:28'),
(288, 144, 29, '0.00', 'PENDIENTE', '2022-07-09 15:42:29', '2022-07-09 15:42:29');

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
(1113, 1, 81),
(1130, 1, 82),
(1168, 1, 85),
(1185, 1, 86),
(1202, 1, 87),
(1219, 1, 88),
(1236, 1, 89),
(1250, 1, 90),
(1264, 1, 91),
(1278, 1, 92),
(1287, 1, 93),
(1301, 1, 94),
(1315, 1, 95),
(1329, 1, 96),
(1114, 2, 81),
(1131, 2, 82),
(1169, 2, 85),
(1186, 2, 86),
(1203, 2, 87),
(1220, 2, 88),
(1237, 2, 89),
(1251, 2, 90),
(1265, 2, 91),
(1279, 2, 92),
(1288, 2, 93),
(1302, 2, 94),
(1316, 2, 95),
(1330, 2, 96),
(1115, 3, 81),
(1132, 3, 82),
(1170, 3, 85),
(1187, 3, 86),
(1204, 3, 87),
(1221, 3, 88),
(1238, 3, 89),
(1252, 3, 90),
(1266, 3, 91),
(1280, 3, 92),
(1289, 3, 93),
(1303, 3, 94),
(1317, 3, 95),
(1331, 3, 96),
(1121, 4, 81),
(1138, 4, 82),
(1173, 4, 85),
(1190, 4, 86),
(1207, 4, 87),
(1224, 4, 88),
(1294, 4, 93),
(1308, 4, 94),
(1322, 4, 95),
(1336, 4, 96),
(1118, 5, 81),
(1135, 5, 82),
(1147, 5, 83),
(1155, 5, 84),
(1165, 5, 85),
(1182, 5, 86),
(1199, 5, 87),
(1216, 5, 88),
(1231, 5, 89),
(1245, 5, 90),
(1259, 5, 91),
(1273, 5, 92),
(1127, 6, 81),
(1144, 6, 82),
(1163, 6, 85),
(1180, 6, 86),
(1197, 6, 87),
(1214, 6, 88),
(1234, 6, 89),
(1248, 6, 90),
(1262, 6, 91),
(1276, 6, 92),
(1292, 6, 93),
(1306, 6, 94),
(1320, 6, 95),
(1334, 6, 96),
(1150, 7, 83),
(1158, 7, 84),
(1229, 7, 89),
(1243, 7, 90),
(1257, 7, 91),
(1271, 7, 92),
(1122, 8, 81),
(1139, 8, 82),
(1174, 8, 85),
(1191, 8, 86),
(1208, 8, 87),
(1225, 8, 88),
(1295, 8, 93),
(1309, 8, 94),
(1323, 8, 95),
(1337, 8, 96),
(1111, 9, 81),
(1128, 9, 82),
(1145, 9, 83),
(1153, 9, 84),
(1161, 9, 85),
(1178, 9, 86),
(1195, 9, 87),
(1212, 9, 88),
(1240, 9, 89),
(1254, 9, 90),
(1268, 9, 91),
(1282, 9, 92),
(1285, 9, 93),
(1299, 9, 94),
(1313, 9, 95),
(1327, 9, 96),
(1151, 10, 83),
(1159, 10, 84),
(1230, 10, 89),
(1244, 10, 90),
(1258, 10, 91),
(1272, 10, 92),
(1123, 11, 81),
(1140, 11, 82),
(1175, 11, 85),
(1192, 11, 86),
(1209, 11, 87),
(1226, 11, 88),
(1296, 11, 93),
(1310, 11, 94),
(1324, 11, 95),
(1338, 11, 96),
(1119, 12, 81),
(1136, 12, 82),
(1148, 12, 83),
(1156, 12, 84),
(1166, 12, 85),
(1183, 12, 86),
(1200, 12, 87),
(1217, 12, 88),
(1232, 12, 89),
(1246, 12, 90),
(1260, 12, 91),
(1274, 12, 92),
(1124, 13, 81),
(1141, 13, 82),
(1176, 13, 85),
(1193, 13, 86),
(1210, 13, 87),
(1227, 13, 88),
(1297, 13, 93),
(1311, 13, 94),
(1325, 13, 95),
(1339, 13, 96),
(1117, 14, 81),
(1134, 14, 82),
(1152, 14, 83),
(1160, 14, 84),
(1172, 14, 85),
(1189, 14, 86),
(1206, 14, 87),
(1223, 14, 88),
(1242, 14, 89),
(1256, 14, 90),
(1270, 14, 91),
(1284, 14, 92),
(1291, 14, 93),
(1305, 14, 94),
(1319, 14, 95),
(1333, 14, 96),
(1120, 15, 81),
(1137, 15, 82),
(1149, 15, 83),
(1157, 15, 84),
(1167, 15, 85),
(1184, 15, 86),
(1201, 15, 87),
(1218, 15, 88),
(1233, 15, 89),
(1247, 15, 90),
(1261, 15, 91),
(1275, 15, 92),
(1125, 16, 81),
(1142, 16, 82),
(1164, 16, 85),
(1181, 16, 86),
(1198, 16, 87),
(1215, 16, 88),
(1235, 16, 89),
(1249, 16, 90),
(1263, 16, 91),
(1277, 16, 92),
(1293, 16, 93),
(1307, 16, 94),
(1321, 16, 95),
(1335, 16, 96),
(1116, 18, 81),
(1133, 18, 82),
(1171, 18, 85),
(1188, 18, 86),
(1205, 18, 87),
(1222, 18, 88),
(1239, 18, 89),
(1253, 18, 90),
(1267, 18, 91),
(1281, 18, 92),
(1290, 18, 93),
(1304, 18, 94),
(1318, 18, 95),
(1332, 18, 96),
(1112, 19, 81),
(1129, 19, 82),
(1146, 19, 83),
(1154, 19, 84),
(1162, 19, 85),
(1179, 19, 86),
(1196, 19, 87),
(1213, 19, 88),
(1241, 19, 89),
(1255, 19, 90),
(1269, 19, 91),
(1283, 19, 92),
(1286, 19, 93),
(1300, 19, 94),
(1314, 19, 95),
(1328, 19, 96),
(1126, 20, 81),
(1143, 20, 82),
(1177, 20, 85),
(1194, 20, 86),
(1211, 20, 87),
(1228, 20, 88),
(1298, 20, 93),
(1312, 20, 94),
(1326, 20, 95),
(1340, 20, 96);

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
(3, 1, '6977', '1239.11', 3, 2, 3, '2022-06-20 21:21:59', '2022-07-09 15:03:09'),
(4, 1, '9149', '803.56', 4, 2, 4, '2022-06-20 21:21:59', '2022-07-09 15:04:53'),
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
(70, '4588563', 'mayuri', 43, 5, '156.00', 'FUNGIBLE', 1, '2022-07-02 18:16:04', '2022-07-02 18:16:04'),
(71, '632114', 'rem', 44, 2, '500.00', 'FUNGIBLE', 1, '2022-07-09 23:15:58', '2022-07-09 23:15:58'),
(72, '1255632', 'siesta 2.0', 44, 8, '30.00', 'FUNGIBLE', 1, '2022-07-11 12:12:51', '2022-07-11 12:12:51'),
(73, '3325633', 'arduino mega2560', 5, 3, '150.00', 'HERRAMIENTA', 1, '2022-07-11 12:13:43', '2022-07-11 12:13:43'),
(74, '5225', 'arduino mega 3560', 45, 7, '60.00', 'HERRAMIENTA', 1, '2022-07-11 20:38:40', '2022-07-11 20:38:40');

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
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('ASIGNADO','LIBERADO','ANULADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ASIGNADO',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `operator_assigned_stocks`
--

INSERT INTO `operator_assigned_stocks` (`id`, `user_id`, `item_id`, `quantity`, `price`, `warehouse_id`, `ceco_id`, `state`, `created_at`, `updated_at`) VALUES
(33, 1, 44, '1.00', '954.65', 7, 1, 'ASIGNADO', NULL, NULL),
(34, 1, 3, '1.00', '692.98', 7, 1, 'ASIGNADO', NULL, NULL),
(35, 1, 11, '1.00', '405.08', 7, 1, 'ASIGNADO', NULL, NULL),
(36, 1, 57, '4.00', '502.17', 7, 1, 'ASIGNADO', NULL, NULL),
(37, 1, 28, '1.00', '515.10', 7, 1, 'ASIGNADO', NULL, NULL),
(38, 2, 3, '1.00', '692.98', 7, 2, 'ASIGNADO', NULL, NULL),
(39, 2, 57, '5.00', '502.17', 7, 2, 'ASIGNADO', NULL, NULL),
(40, 2, 50, '1.00', '846.80', 7, 2, 'ASIGNADO', NULL, NULL),
(41, 2, 44, '1.00', '954.65', 7, 2, 'ASIGNADO', NULL, NULL),
(42, 3, 3, '2.00', '692.98', 6, 3, 'ASIGNADO', NULL, NULL),
(43, 3, 57, '12.00', '502.17', 6, 3, 'ASIGNADO', NULL, NULL),
(44, 3, 24, '1.00', '577.05', 6, 3, 'ASIGNADO', NULL, NULL),
(45, 3, 9, '2.00', '362.42', 6, 3, 'ASIGNADO', NULL, NULL),
(46, 3, 44, '3.00', '954.65', 6, 3, 'ASIGNADO', NULL, NULL),
(47, 3, 21, '1.00', '785.44', 6, 3, 'ASIGNADO', NULL, NULL),
(48, 3, 65, '1.00', '2600.00', 6, 3, 'ASIGNADO', NULL, NULL),
(49, 4, 3, '2.00', '200.00', 6, 4, 'ASIGNADO', NULL, NULL),
(50, 4, 21, '3.00', '200.00', 6, 4, 'ASIGNADO', NULL, NULL),
(51, 4, 9, '3.00', '300.00', 6, 4, 'ASIGNADO', NULL, NULL),
(52, 4, 57, '6.00', '100.00', 6, 4, 'ASIGNADO', NULL, NULL),
(53, 4, 52, '2.00', '200.00', 6, 4, 'ASIGNADO', NULL, NULL),
(54, 4, 44, '3.00', '100.00', 6, 4, 'ASIGNADO', NULL, NULL),
(55, 4, 24, '1.00', '500.00', 6, 4, 'ASIGNADO', NULL, NULL),
(56, 5, 72, '5.00', '30.00', 5, 5, 'ASIGNADO', NULL, NULL),
(57, 5, 3, '1.00', '900.00', 5, 5, 'ASIGNADO', NULL, NULL),
(58, 5, 57, '2.00', '500.00', 5, 5, 'ASIGNADO', NULL, NULL),
(59, 6, 73, '8.00', '150.00', 5, 6, 'ASIGNADO', NULL, NULL),
(60, 6, 44, '2.00', '200.00', 5, 6, 'ASIGNADO', NULL, NULL),
(61, 6, 3, '2.00', '700.00', 5, 6, 'ASIGNADO', NULL, NULL),
(62, 6, 57, '2.00', '300.00', 5, 6, 'ASIGNADO', NULL, NULL),
(63, 9, 57, '6.00', '400.00', 4, 9, 'ASIGNADO', NULL, NULL),
(64, 9, 29, '2.00', '400.00', 4, 9, 'ASIGNADO', NULL, NULL),
(65, 9, 3, '1.00', '900.00', 4, 9, 'ASIGNADO', NULL, NULL),
(66, 4, 51, '2.00', '200.00', 6, 4, 'ASIGNADO', NULL, NULL),
(67, 4, 72, '2.00', '75.00', 6, 4, 'ASIGNADO', NULL, NULL),
(68, 4, 73, '2.00', '60.00', 6, 4, 'ASIGNADO', NULL, NULL),
(69, 4, 66, '3.00', '45.00', 6, 4, 'ASIGNADO', NULL, NULL),
(70, 4, 51, '3.00', '450.00', 6, 4, 'ASIGNADO', NULL, NULL);

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
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `operator_stocks`
--

INSERT INTO `operator_stocks` (`id`, `user_id`, `item_id`, `quantity`, `price`, `warehouse_id`, `ceco_id`, `created_at`, `updated_at`) VALUES
(22, 1, 44, '1.00', '954.65', 7, 1, NULL, NULL),
(23, 1, 3, '1.00', '692.98', 7, 1, NULL, NULL),
(24, 1, 11, '1.00', '405.08', 7, 1, NULL, NULL),
(25, 1, 57, '4.00', '2008.68', 7, 1, NULL, NULL),
(26, 1, 28, '1.00', '515.10', 7, 1, NULL, NULL),
(27, 2, 3, '1.00', '692.98', 7, 2, NULL, NULL),
(28, 2, 57, '5.00', '2510.85', 7, 2, NULL, NULL),
(29, 2, 50, '1.00', '846.80', 7, 2, NULL, NULL),
(30, 2, 44, '1.00', '954.65', 7, 2, NULL, NULL),
(31, 3, 3, '2.00', '1385.96', 6, 3, NULL, NULL),
(32, 3, 57, '12.00', '6026.04', 6, 3, NULL, NULL),
(33, 3, 24, '1.00', '577.05', 6, 3, NULL, NULL),
(34, 3, 9, '2.00', '724.84', 6, 3, NULL, NULL),
(35, 3, 44, '3.00', '2863.95', 6, 3, NULL, NULL),
(36, 3, 21, '1.00', '785.44', 6, 3, NULL, NULL),
(37, 3, 65, '1.00', '2600.00', 6, 3, NULL, NULL),
(38, 4, 3, '2.00', '400.00', 6, 4, NULL, NULL),
(39, 4, 21, '3.00', '600.00', 6, 4, NULL, NULL),
(40, 4, 9, '3.00', '900.00', 6, 4, NULL, NULL),
(41, 4, 57, '6.00', '600.00', 6, 4, NULL, NULL),
(42, 4, 52, '2.00', '400.00', 6, 4, NULL, NULL),
(43, 4, 44, '3.00', '300.00', 6, 4, NULL, NULL),
(44, 4, 24, '1.00', '500.00', 6, 4, NULL, NULL),
(45, 5, 72, '5.00', '150.00', 5, 5, NULL, NULL),
(46, 5, 3, '1.00', '900.00', 5, 5, NULL, NULL),
(47, 5, 57, '2.00', '1000.00', 5, 5, NULL, NULL),
(48, 6, 73, '8.00', '1200.00', 5, 6, NULL, NULL),
(49, 6, 44, '2.00', '400.00', 5, 6, NULL, NULL),
(50, 6, 3, '2.00', '1400.00', 5, 6, NULL, NULL),
(51, 6, 57, '2.00', '600.00', 5, 6, NULL, NULL),
(52, 9, 57, '6.00', '2400.00', 4, 9, NULL, NULL),
(53, 9, 29, '2.00', '800.00', 4, 9, NULL, NULL),
(54, 9, 3, '1.00', '900.00', 4, 9, NULL, NULL),
(55, 4, 51, '5.00', '1750.00', 6, 4, NULL, NULL),
(56, 4, 72, '2.00', '150.00', 6, 4, NULL, NULL),
(57, 4, 73, '2.00', '120.00', 6, 4, NULL, NULL),
(59, 4, 66, '3.00', '135.00', 6, 4, NULL, NULL);

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
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('CONFIRMADO','ANULADO','LIBERADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_request_detail_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `operator_stock_details`
--

INSERT INTO `operator_stock_details` (`id`, `user_id`, `item_id`, `movement`, `quantity`, `price`, `warehouse_id`, `ceco_id`, `state`, `order_request_detail_id`, `created_at`, `updated_at`) VALUES
(34, 1, 44, 'INGRESO', '1.00', '954.65', 7, 1, 'CONFIRMADO', 74, '2022-07-11 12:43:37', '2022-07-11 12:43:37'),
(35, 1, 3, 'INGRESO', '1.00', '692.98', 7, 1, 'CONFIRMADO', 75, '2022-07-11 12:43:41', '2022-07-11 12:43:41'),
(36, 1, 11, 'INGRESO', '1.00', '405.08', 7, 1, 'CONFIRMADO', 76, '2022-07-11 12:43:44', '2022-07-11 12:43:44'),
(37, 1, 57, 'INGRESO', '4.00', '502.17', 7, 1, 'CONFIRMADO', 77, '2022-07-11 12:43:48', '2022-07-11 12:43:48'),
(38, 1, 28, 'INGRESO', '1.00', '515.10', 7, 1, 'CONFIRMADO', 78, '2022-07-11 12:43:51', '2022-07-11 12:43:51'),
(39, 2, 3, 'INGRESO', '1.00', '692.98', 7, 2, 'CONFIRMADO', 79, '2022-07-11 12:43:57', '2022-07-11 12:43:57'),
(40, 2, 57, 'INGRESO', '5.00', '502.17', 7, 2, 'CONFIRMADO', 80, '2022-07-11 12:44:00', '2022-07-11 12:44:00'),
(41, 2, 50, 'INGRESO', '1.00', '846.80', 7, 2, 'CONFIRMADO', 81, '2022-07-11 12:44:03', '2022-07-11 12:44:03'),
(42, 2, 44, 'INGRESO', '1.00', '954.65', 7, 2, 'CONFIRMADO', 82, '2022-07-11 12:44:06', '2022-07-11 12:44:06'),
(43, 3, 3, 'INGRESO', '2.00', '692.98', 6, 3, 'CONFIRMADO', 83, '2022-07-11 12:44:22', '2022-07-11 12:44:22'),
(44, 3, 57, 'INGRESO', '12.00', '502.17', 6, 3, 'CONFIRMADO', 84, '2022-07-11 12:44:26', '2022-07-11 12:44:26'),
(45, 3, 24, 'INGRESO', '1.00', '577.05', 6, 3, 'CONFIRMADO', 85, '2022-07-11 12:46:47', '2022-07-11 12:46:47'),
(46, 3, 9, 'INGRESO', '2.00', '362.42', 6, 3, 'CONFIRMADO', 86, '2022-07-11 12:46:50', '2022-07-11 12:46:50'),
(47, 3, 44, 'INGRESO', '3.00', '954.65', 6, 3, 'CONFIRMADO', 87, '2022-07-11 12:46:53', '2022-07-11 12:46:53'),
(48, 3, 21, 'INGRESO', '1.00', '785.44', 6, 3, 'CONFIRMADO', 88, '2022-07-11 12:46:56', '2022-07-11 12:46:56'),
(49, 3, 65, 'INGRESO', '1.00', '2600.00', 6, 3, 'CONFIRMADO', 89, '2022-07-11 12:46:58', '2022-07-11 12:46:58'),
(50, 4, 3, 'INGRESO', '2.00', '200.00', 6, 4, 'CONFIRMADO', 90, '2022-07-11 12:47:05', '2022-07-11 12:47:05'),
(51, 4, 21, 'INGRESO', '3.00', '200.00', 6, 4, 'CONFIRMADO', 92, '2022-07-11 12:47:08', '2022-07-11 12:47:08'),
(52, 4, 9, 'INGRESO', '3.00', '300.00', 6, 4, 'CONFIRMADO', 91, '2022-07-11 12:47:10', '2022-07-11 12:47:10'),
(53, 4, 57, 'INGRESO', '6.00', '100.00', 6, 4, 'CONFIRMADO', 93, '2022-07-11 12:47:13', '2022-07-11 12:47:13'),
(54, 4, 52, 'INGRESO', '2.00', '200.00', 6, 4, 'CONFIRMADO', 94, '2022-07-11 12:47:15', '2022-07-11 12:47:15'),
(55, 4, 44, 'INGRESO', '3.00', '100.00', 6, 4, 'CONFIRMADO', 95, '2022-07-11 12:47:17', '2022-07-11 12:47:17'),
(56, 4, 24, 'INGRESO', '1.00', '500.00', 6, 4, 'CONFIRMADO', 96, '2022-07-11 12:47:19', '2022-07-11 12:47:19'),
(57, 5, 72, 'INGRESO', '5.00', '30.00', 5, 5, 'CONFIRMADO', 98, '2022-07-11 12:47:32', '2022-07-11 12:47:32'),
(58, 5, 3, 'INGRESO', '1.00', '900.00', 5, 5, 'CONFIRMADO', 99, '2022-07-11 12:47:35', '2022-07-11 12:47:35'),
(59, 5, 57, 'INGRESO', '2.00', '500.00', 5, 5, 'CONFIRMADO', 100, '2022-07-11 12:47:37', '2022-07-11 12:47:37'),
(60, 6, 73, 'INGRESO', '8.00', '150.00', 5, 6, 'CONFIRMADO', 102, '2022-07-11 12:47:43', '2022-07-11 12:47:43'),
(61, 6, 44, 'INGRESO', '2.00', '200.00', 5, 6, 'CONFIRMADO', 103, '2022-07-11 12:47:46', '2022-07-11 12:47:46'),
(62, 6, 3, 'INGRESO', '2.00', '700.00', 5, 6, 'CONFIRMADO', 104, '2022-07-11 12:47:48', '2022-07-11 12:47:48'),
(63, 6, 57, 'INGRESO', '2.00', '300.00', 5, 6, 'CONFIRMADO', 105, '2022-07-11 12:47:50', '2022-07-11 12:47:50'),
(64, 9, 57, 'INGRESO', '6.00', '400.00', 4, 9, 'CONFIRMADO', 106, '2022-07-11 12:48:15', '2022-07-11 12:48:15'),
(65, 9, 29, 'INGRESO', '2.00', '400.00', 4, 9, 'CONFIRMADO', 107, '2022-07-11 12:48:18', '2022-07-11 12:48:18'),
(66, 9, 3, 'INGRESO', '1.00', '900.00', 4, 9, 'CONFIRMADO', 108, '2022-07-11 12:48:20', '2022-07-11 12:48:20'),
(67, 4, 51, 'INGRESO', '2.00', '200.00', 6, 4, 'CONFIRMADO', NULL, NULL, NULL),
(69, 4, 72, 'INGRESO', '2.00', '75.00', 6, 4, 'CONFIRMADO', NULL, NULL, NULL),
(70, 4, 73, 'INGRESO', '2.00', '60.00', 6, 4, 'CONFIRMADO', NULL, NULL, NULL),
(71, 4, 66, 'INGRESO', '3.00', '45.00', 6, 4, 'CONFIRMADO', NULL, NULL, NULL),
(72, 4, 51, 'INGRESO', '3.00', '450.00', 6, 4, 'CONFIRMADO', NULL, NULL, NULL);

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
UPDATE operator_assigned_stocks SET quantity = quantity - old.quantity, price = price - (old.price*old.quantity), state = "ANULADO" WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity - old.quantity, price = price - (old.price*old.quantity) WHERE id = stock;
/*------Anular aumento de la cantidad de almacen en el ceco--------------*/
UPDATE cecos c SET c.warehouse_amount = c.warehouse_amount - (new.quantity*new.price) WHERE c.id = new.ceco_id;
ELSE
/*----------ANULAR SALIDA-------*/
/*---------Anular en op_stock---------*/
UPDATE operator_stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = op_stock;
/*----Anular en operator_assigned_stocks--*/
UPDATE operator_assigned_stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = op_assigned;
/*-------Anular en stock general--------*/
UPDATE stocks SET quantity = quantity + old.quantity, price = price + (old.price*old.quantity) WHERE id = stock;
/*---------Anular disminuir MONTO EN EL ALMACEN Y MONTO DEL CECO--------------------------*/
UPDATE cecos c SET c.warehouse_amount = c.warehouse_amount + (new.quantity*new.price), c.amount = c.amount + (new.quantity*new.price) WHERE c.id = new.ceco_id;
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
INSERT INTO operator_stocks(user_id, item_id, quantity, price, warehouse_id,ceco_id) VALUES (new.user_id, new.item_id, new.quantity, (new.price*new.quantity), new.warehouse_id,new.ceco_id);
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
INSERT INTO operator_assigned_stocks(user_id, item_id, quantity, price, warehouse_id,ceco_id) VALUES (new.user_id, new.item_id, new.quantity, new.price, new.warehouse_id,new.ceco_id);
SELECT MAX(id) INTO op_assigned FROM operator_assigned_stocks;
/*-------Aumentar monto del almacen del respectivo ceco----------------*/
UPDATE cecos c SET c.warehouse_amount = c.warehouse_amount + (new.quantity*new.price) WHERE c.id = new.ceco_id;
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
/*---------DISMINUR MONTO EN EL ALMACEN Y MONTO DEL CECO--------------------------*/
UPDATE cecos c SET c.warehouse_amount = c.warehouse_amount - (new.quantity*new.price), c.amount = c.amount - (new.quantity*new.price) WHERE c.id = new.ceco_id;
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
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
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
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_requests`
--

INSERT INTO `order_requests` (`id`, `user_id`, `implement_id`, `state`, `validate_by`, `is_canceled`, `order_date_id`, `created_at`, `updated_at`) VALUES
(2, 1, 1, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 12:06:05'),
(3, 2, 2, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 12:06:23'),
(4, 3, 3, 'CERRADO', 4, 0, 1, NULL, '2022-07-11 12:06:50'),
(5, 4, 4, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 22:27:49'),
(6, 5, 5, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 12:13:15'),
(7, 6, 6, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 12:14:24'),
(8, 7, 7, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(9, 8, 8, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(10, 9, 9, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 12:15:09'),
(11, 10, 10, 'VALIDADO', 4, 0, 1, NULL, '2022-07-11 20:39:43'),
(12, 11, 11, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(13, 12, 12, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(14, 13, 13, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(15, 14, 14, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(16, 15, 15, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(17, 16, 16, 'PENDIENTE', NULL, 0, 1, NULL, NULL),
(18, 4, 4, 'CERRADO', NULL, 0, 1, '2022-07-13 01:37:38', '2022-07-13 01:48:11');

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
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_details`
--

INSERT INTO `order_request_details` (`id`, `order_request_id`, `item_id`, `quantity`, `estimated_price`, `state`, `observation`, `assigned_quantity`, `assigned_state`, `created_at`, `updated_at`) VALUES
(1, 2, 3, '1.00', '692.98', 'ACEPTADO', 'zzzx', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:07', '2022-07-11 12:05:54'),
(2, 2, 57, '4.00', '502.17', 'ACEPTADO', 'zxxz', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:07', '2022-07-11 12:05:59'),
(3, 2, 21, '0.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:08', '2022-07-09 23:09:39'),
(4, 2, 44, '1.00', '954.65', 'ACEPTADO', 'zxxx', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:08', '2022-07-11 11:14:26'),
(5, 3, 3, '1.00', '692.98', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:09', '2022-07-11 12:06:13'),
(6, 3, 57, '5.00', '502.17', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:09', '2022-07-11 12:06:16'),
(7, 3, 21, '0.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:09', '2022-07-09 23:10:29'),
(8, 3, 44, '1.00', '954.65', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:09', '2022-07-11 12:06:21'),
(9, 4, 3, '2.00', '692.98', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:31'),
(10, 4, 24, '1.00', '577.05', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:36'),
(11, 4, 57, '12.00', '502.17', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:34'),
(12, 4, 9, '2.00', '362.42', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:39'),
(13, 4, 21, '1.00', '785.44', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:44'),
(14, 4, 44, '3.00', '954.65', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-11 12:06:41'),
(15, 4, 52, '0.00', '216.64', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:10', '2022-07-09 23:11:06'),
(16, 5, 3, '2.00', '692.98', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:07:00'),
(17, 5, 24, '1.00', '577.05', 'ACEPTADO', 'SS', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:08:24'),
(18, 5, 57, '12.00', '502.17', 'MODIFICADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:08:02'),
(19, 5, 9, '3.00', '362.42', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:07:03'),
(20, 5, 21, '3.00', '785.44', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:07:07'),
(21, 5, 44, '4.00', '954.65', 'MODIFICADO', 'S', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:08:19'),
(22, 5, 52, '2.00', '216.64', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:11', '2022-07-11 12:07:12'),
(23, 6, 57, '2.00', '502.17', 'ACEPTADO', 'DS', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:12', '2022-07-11 12:13:04'),
(24, 6, 3, '1.00', '692.98', 'ACEPTADO', 'SD', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:13', '2022-07-11 12:12:58'),
(25, 6, 44, '0.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:13', '2022-07-09 23:07:31'),
(26, 7, 57, '2.00', '502.17', 'ACEPTADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:13', '2022-07-11 12:14:07'),
(27, 7, 3, '2.00', '692.98', 'ACEPTADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:14', '2022-07-11 12:14:00'),
(28, 7, 44, '2.00', '954.65', 'ACEPTADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:14', '2022-07-11 12:13:52'),
(29, 8, 57, '2.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:14', NULL),
(30, 8, 3, '2.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:15', NULL),
(31, 8, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:15', NULL),
(32, 9, 57, '2.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:15', NULL),
(33, 9, 3, '2.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:16', NULL),
(34, 9, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:16', NULL),
(35, 10, 57, '6.00', '502.17', 'ACEPTADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:17', '2022-07-11 12:14:46'),
(36, 10, 3, '1.00', '692.98', 'ACEPTADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:17', '2022-07-11 12:15:06'),
(37, 10, 29, '22.00', '378.24', 'MODIFICADO', 'D', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:17', '2022-07-11 12:14:57'),
(38, 11, 57, '1.00', '502.17', 'ACEPTADO', 'sd', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:18', '2022-07-11 20:39:05'),
(39, 11, 3, '1.00', '692.98', 'ACEPTADO', 'as', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:18', '2022-07-11 20:39:39'),
(40, 11, 29, '2.00', '378.24', 'RECHAZADO', 'as', '0.00', 'NO ASIGNADO', '2022-07-09 15:42:18', '2022-07-11 20:39:25'),
(41, 12, 57, '6.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:19', NULL),
(42, 12, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:19', NULL),
(43, 12, 29, '22.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:20', NULL),
(44, 13, 57, '6.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:20', NULL),
(45, 13, 3, '1.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:21', NULL),
(46, 13, 29, '22.00', '378.24', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:21', NULL),
(47, 14, 3, '3.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:22', NULL),
(48, 14, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:22', NULL),
(49, 14, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:22', NULL),
(50, 14, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:23', NULL),
(51, 15, 3, '3.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:24', NULL),
(52, 15, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:24', NULL),
(53, 15, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:24', NULL),
(54, 15, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:25', NULL),
(55, 16, 3, '3.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:25', NULL),
(56, 16, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:26', NULL),
(57, 16, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:26', NULL),
(58, 16, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:27', NULL),
(59, 17, 3, '3.00', '692.98', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:27', NULL),
(60, 17, 57, '4.00', '502.17', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:27', NULL),
(61, 17, 21, '2.00', '785.44', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:28', NULL),
(62, 17, 44, '2.00', '954.65', 'PENDIENTE', NULL, '0.00', 'NO ASIGNADO', '2022-07-09 15:42:28', NULL),
(63, 2, 11, '1.00', '405.08', 'ACEPTADO', 'zxzxzxz', '0.00', 'NO ASIGNADO', '2022-07-09 23:09:28', '2022-07-11 12:05:56'),
(64, 2, 28, '1.00', '515.10', 'ACEPTADO', 'xzz', '0.00', 'NO ASIGNADO', '2022-07-09 23:09:32', '2022-07-11 12:06:01'),
(65, 3, 50, '1.00', '846.80', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 23:10:35', '2022-07-11 12:06:18'),
(66, 4, 65, '1.00', '2600.00', 'ACEPTADO', 'A', '0.00', 'NO ASIGNADO', '2022-07-09 23:11:24', '2022-07-11 12:06:47'),
(67, 2, 71, '52.00', '500.00', 'RECHAZADO', 'x', '0.00', 'NO ASIGNADO', '2022-07-09 23:15:58', '2022-07-09 23:23:47'),
(74, 2, 44, '1.00', '954.65', 'VALIDADO', 'zxxx', '1.00', 'ASIGNADO', '2022-07-11 11:14:26', '2022-07-11 12:43:37'),
(75, 2, 3, '1.00', '692.98', 'VALIDADO', 'zzzx', '1.00', 'ASIGNADO', '2022-07-11 12:05:54', '2022-07-11 12:43:41'),
(76, 2, 11, '1.00', '405.08', 'VALIDADO', 'zxzxzxz', '1.00', 'ASIGNADO', '2022-07-11 12:05:56', '2022-07-11 12:43:44'),
(77, 2, 57, '4.00', '502.17', 'VALIDADO', 'zxxz', '4.00', 'ASIGNADO', '2022-07-11 12:05:59', '2022-07-11 12:43:48'),
(78, 2, 28, '1.00', '515.10', 'VALIDADO', 'xzz', '1.00', 'ASIGNADO', '2022-07-11 12:06:01', '2022-07-11 12:43:51'),
(79, 3, 3, '1.00', '692.98', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:13', '2022-07-11 12:43:57'),
(80, 3, 57, '5.00', '502.17', 'VALIDADO', 'A', '5.00', 'ASIGNADO', '2022-07-11 12:06:16', '2022-07-11 12:44:00'),
(81, 3, 50, '1.00', '846.80', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:18', '2022-07-11 12:44:03'),
(82, 3, 44, '1.00', '954.65', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:21', '2022-07-11 12:44:06'),
(83, 4, 3, '2.00', '692.98', 'VALIDADO', 'A', '2.00', 'ASIGNADO', '2022-07-11 12:06:31', '2022-07-11 12:44:22'),
(84, 4, 57, '12.00', '502.17', 'VALIDADO', 'A', '12.00', 'ASIGNADO', '2022-07-11 12:06:34', '2022-07-11 12:44:26'),
(85, 4, 24, '1.00', '577.05', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:36', '2022-07-11 12:46:47'),
(86, 4, 9, '2.00', '362.42', 'VALIDADO', 'A', '2.00', 'ASIGNADO', '2022-07-11 12:06:39', '2022-07-11 12:46:50'),
(87, 4, 44, '3.00', '954.65', 'VALIDADO', 'A', '3.00', 'ASIGNADO', '2022-07-11 12:06:41', '2022-07-11 12:46:53'),
(88, 4, 21, '1.00', '785.44', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:44', '2022-07-11 12:46:56'),
(89, 4, 65, '1.00', '2600.00', 'VALIDADO', 'A', '1.00', 'ASIGNADO', '2022-07-11 12:06:47', '2022-07-11 12:46:59'),
(90, 5, 3, '2.00', '200.00', 'VALIDADO', 'A', '2.00', 'ASIGNADO', '2022-07-11 12:07:00', '2022-07-11 12:47:05'),
(91, 5, 9, '3.00', '300.00', 'VALIDADO', 'A', '3.00', 'ASIGNADO', '2022-07-11 12:07:03', '2022-07-11 12:47:10'),
(92, 5, 21, '3.00', '200.00', 'VALIDADO', 'A', '3.00', 'ASIGNADO', '2022-07-11 12:07:07', '2022-07-11 12:47:08'),
(93, 5, 57, '6.00', '100.00', 'VALIDADO', 'A', '6.00', 'ASIGNADO', '2022-07-11 12:07:09', '2022-07-11 12:47:13'),
(94, 5, 52, '2.00', '200.00', 'VALIDADO', 'A', '2.00', 'ASIGNADO', '2022-07-11 12:07:12', '2022-07-11 12:47:15'),
(95, 5, 44, '3.00', '100.00', 'VALIDADO', 'S', '3.00', 'ASIGNADO', '2022-07-11 12:08:19', '2022-07-11 12:47:17'),
(96, 5, 24, '1.00', '500.00', 'VALIDADO', 'SS', '1.00', 'ASIGNADO', '2022-07-11 12:08:24', '2022-07-11 12:47:19'),
(97, 6, 72, '5.00', '30.00', 'ACEPTADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-11 12:12:51', '2022-07-11 12:12:51'),
(98, 6, 72, '5.00', '30.00', 'VALIDADO', NULL, '5.00', 'ASIGNADO', '2022-07-11 12:12:51', '2022-07-11 12:47:32'),
(99, 6, 3, '1.00', '900.00', 'VALIDADO', 'SD', '1.00', 'ASIGNADO', '2022-07-11 12:12:58', '2022-07-11 12:47:35'),
(100, 6, 57, '2.00', '500.00', 'VALIDADO', 'DS', '2.00', 'ASIGNADO', '2022-07-11 12:13:04', '2022-07-11 12:47:37'),
(101, 7, 73, '123.00', '150.00', 'MODIFICADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-11 12:13:43', '2022-07-11 12:13:43'),
(102, 7, 73, '8.00', '150.00', 'VALIDADO', 'D', '8.00', 'ASIGNADO', '2022-07-11 12:13:43', '2022-07-11 12:47:43'),
(103, 7, 44, '2.00', '200.00', 'VALIDADO', 'D', '2.00', 'ASIGNADO', '2022-07-11 12:13:52', '2022-07-11 12:47:46'),
(104, 7, 3, '2.00', '700.00', 'VALIDADO', 'D', '2.00', 'ASIGNADO', '2022-07-11 12:14:00', '2022-07-11 12:47:48'),
(105, 7, 57, '2.00', '300.00', 'VALIDADO', 'D', '2.00', 'ASIGNADO', '2022-07-11 12:14:07', '2022-07-11 12:47:50'),
(106, 10, 57, '6.00', '400.00', 'VALIDADO', 'D', '6.00', 'ASIGNADO', '2022-07-11 12:14:46', '2022-07-11 12:48:15'),
(107, 10, 29, '2.00', '400.00', 'VALIDADO', 'D', '2.00', 'ASIGNADO', '2022-07-11 12:14:57', '2022-07-11 12:48:18'),
(108, 10, 3, '1.00', '900.00', 'VALIDADO', 'D', '1.00', 'ASIGNADO', '2022-07-11 12:15:06', '2022-07-11 12:48:20'),
(109, 11, 74, '2.00', '60.00', 'ACEPTADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-11 20:38:40', '2022-07-11 20:38:40'),
(110, 11, 74, '2.00', '60.00', 'VALIDADO', NULL, '0.00', 'NO ASIGNADO', '2022-07-11 20:38:40', '2022-07-11 20:38:40'),
(111, 11, 57, '1.00', '502.17', 'VALIDADO', 'sd', '0.00', 'NO ASIGNADO', '2022-07-11 20:39:05', '2022-07-11 20:39:05'),
(112, 11, 3, '1.00', '692.98', 'VALIDADO', 'as', '0.00', 'NO ASIGNADO', '2022-07-11 20:39:39', '2022-07-11 20:39:39'),
(113, 18, 17, '2.00', '906.47', 'PENDIENTE', '', '0.00', 'NO ASIGNADO', '2022-07-13 01:37:38', '2022-07-13 01:38:44'),
(114, 18, 5, '2.00', '317.70', 'PENDIENTE', '', '0.00', 'NO ASIGNADO', '2022-07-13 01:38:37', '2022-07-13 01:38:41'),
(115, 18, 8, '2.00', '563.25', 'PENDIENTE', '', '0.00', 'NO ASIGNADO', '2022-07-13 01:40:37', '2022-07-13 01:40:45'),
(116, 18, 9, '0.00', '362.42', 'PENDIENTE', '', '0.00', 'NO ASIGNADO', '2022-07-13 01:42:11', '2022-07-13 01:42:23'),
(117, 18, 44, '0.00', '954.65', 'PENDIENTE', '', '0.00', 'NO ASIGNADO', '2022-07-13 01:42:14', '2022-07-13 01:42:26');

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
(23, 6, 'KOTORI', '1.00', 2, 'BANDAI', 'DAS', 'public/newMaterials/6IpsNOjWtQ8oA9tZNVkYr2t3Pwwi2sXZyCiuUrv4.jpg', 'RECHAZADO', NULL, '', '2022-07-09 20:51:03', '2022-07-11 12:12:22'),
(24, 6, 'Sore', '5.00', 4, 'SIESTA', '-sad\n-sad', 'public/newMaterials/VICNjGXJ7r0TB0uDqmk4hxmXjlBa76iMsBKXON0z.jpg', 'CREADO', 72, '', '2022-07-09 23:07:08', '2022-07-11 12:12:51'),
(25, 2, 'REM', '52.00', 2, 'Taito', '-ssa-\nassd-', 'public/newMaterials/clTFxIg4DpkVYC8VJxJrhhpcLW5b7AHKk8df6mXm.jpg', 'CREADO', 71, '', '2022-07-09 23:09:22', '2022-07-09 23:15:58'),
(26, 7, 'ARDUINO MEGA2560', '123.00', 3, 'ARUINO', '-1 CANTDAD MAS CABLES', 'public/newMaterials/BPcb3RhHbd7Ya2a02EDgZx7MAEVK3OKX297EwKP0.png', 'CREADO', 73, '', '2022-07-09 23:14:01', '2022-07-11 12:13:43'),
(27, 11, 'ARDUINO MEGA 2560', '2.00', 7, 'ARDUINO', '-2GB\n', 'public/newMaterials/2mEFPdLAN3Sa0yMu8Z7tLZ5WWdEDAeSJMJQK7GRp.png', 'CREADO', 74, '', '2022-07-11 20:36:09', '2022-07-11 20:38:40'),
(28, 18, 'Megumi Katou', '2.00', 1, 'Banpresto', '-Hermosa.\n-Bien detallada.', 'public/newMaterials/g7Kp8kbpMafFFCN0EV9OOqvjhYjEer8sV6Ss4mfR.jpg', 'PENDIENTE', NULL, '', '2022-07-13 01:46:30', '2022-07-13 01:48:00');

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
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','CERRADO','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `pre_stockpile_date_id` bigint(20) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `pre_stockpiles`
--

INSERT INTO `pre_stockpiles` (`id`, `user_id`, `implement_id`, `state`, `ceco_id`, `pre_stockpile_date_id`, `created_at`, `updated_at`) VALUES
(17, 1, 1, 'PENDIENTE', 1, 1, NULL, NULL),
(18, 2, 2, 'PENDIENTE', 2, 1, NULL, NULL),
(19, 3, 3, 'PENDIENTE', 3, 1, NULL, NULL),
(20, 4, 4, 'CERRADO', 4, 1, NULL, '2022-07-13 10:19:15'),
(21, 5, 5, 'PENDIENTE', 5, 1, NULL, NULL),
(22, 6, 6, 'PENDIENTE', 6, 1, NULL, NULL),
(23, 7, 7, 'PENDIENTE', 7, 1, NULL, NULL),
(24, 8, 8, 'PENDIENTE', 8, 1, NULL, NULL),
(25, 9, 9, 'PENDIENTE', 9, 1, NULL, NULL),
(26, 10, 10, 'PENDIENTE', 10, 1, NULL, NULL),
(27, 11, 11, 'PENDIENTE', 11, 1, NULL, NULL),
(28, 12, 12, 'PENDIENTE', 12, 1, NULL, NULL),
(29, 13, 13, 'PENDIENTE', 13, 1, NULL, NULL),
(30, 14, 14, 'PENDIENTE', 14, 1, NULL, NULL),
(31, 15, 15, 'PENDIENTE', 15, 1, NULL, NULL),
(32, 16, 16, 'PENDIENTE', 16, 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpile_dates`
--

CREATE TABLE `pre_stockpile_dates` (
  `id` bigint(20) NOT NULL,
  `open_pre_stockpile` date NOT NULL,
  `close_pre_stockpile` date NOT NULL,
  `pre_stockpile_date` date DEFAULT NULL,
  `state` enum('PENDIENTE','ABIERTO','CERRADO') NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `pre_stockpile_dates`
--

INSERT INTO `pre_stockpile_dates` (`id`, `open_pre_stockpile`, `close_pre_stockpile`, `pre_stockpile_date`, `state`, `created_at`, `updated_at`) VALUES
(1, '2022-07-09', '2022-07-10', '2022-07-01', 'ABIERTO', '2022-07-09 18:04:44', '2022-07-11 06:26:18'),
(2, '2022-08-08', '2022-08-09', '2022-08-01', 'PENDIENTE', '2022-07-09 18:04:44', '2022-07-11 00:05:52');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpile_details`
--

CREATE TABLE `pre_stockpile_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pre_stockpile_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `state` enum('PENDIENTE','ACEPTADO','MODIFICADO','RECHAZADO','VALIDADO','INCOMPLETO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `used_quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `pre_stockpile_details`
--

INSERT INTO `pre_stockpile_details` (`id`, `pre_stockpile_id`, `item_id`, `quantity`, `price`, `state`, `used_quantity`, `warehouse_id`, `created_at`, `updated_at`) VALUES
(23, 17, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 7, NULL, NULL),
(24, 18, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 7, NULL, NULL),
(25, 19, 3, '1.00', '692.98', 'PENDIENTE', '0.00', 6, NULL, NULL),
(26, 19, 24, '1.00', '577.05', 'PENDIENTE', '0.00', 6, NULL, NULL),
(27, 19, 57, '6.00', '502.17', 'PENDIENTE', '0.00', 6, NULL, NULL),
(28, 19, 9, '3.00', '362.42', 'PENDIENTE', '0.00', 6, NULL, NULL),
(29, 19, 21, '2.00', '785.44', 'PENDIENTE', '0.00', 6, NULL, NULL),
(30, 19, 44, '2.00', '954.65', 'PENDIENTE', '0.00', 6, NULL, NULL),
(31, 19, 52, '2.00', '216.64', 'PENDIENTE', '0.00', 6, NULL, NULL),
(35, 20, 9, '1.00', '362.42', 'PENDIENTE', '0.00', 6, NULL, '2022-07-13 09:58:54'),
(37, 20, 44, '1.00', '954.65', 'PENDIENTE', '0.00', 6, NULL, '2022-07-13 09:58:58'),
(38, 20, 52, '1.00', '216.64', 'PENDIENTE', '0.00', 6, NULL, '2022-07-13 09:57:45'),
(39, 25, 29, '10.00', '378.24', 'PENDIENTE', '0.00', 4, NULL, NULL),
(40, 26, 29, '10.00', '378.24', 'PENDIENTE', '0.00', 4, NULL, NULL),
(41, 27, 29, '10.00', '378.24', 'PENDIENTE', '0.00', 8, NULL, NULL),
(42, 28, 29, '10.00', '378.24', 'PENDIENTE', '0.00', 8, NULL, NULL),
(43, 29, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 3, NULL, NULL),
(44, 30, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 3, NULL, NULL),
(45, 31, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 1, NULL, NULL),
(46, 32, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 1, NULL, NULL),
(50, 20, 57, '6.00', '502.17', 'PENDIENTE', '0.00', 6, '2022-07-13 03:43:48', '2022-07-13 09:59:16'),
(51, 20, 3, '1.00', '692.98', 'PENDIENTE', '0.00', 6, '2022-07-13 03:45:08', '2022-07-13 09:58:49'),
(53, 20, 72, '0.00', '30.00', 'PENDIENTE', '0.00', 6, '2022-07-13 04:34:19', '2022-07-13 09:57:59'),
(54, 20, 21, '1.00', '785.44', 'PENDIENTE', '0.00', 6, '2022-07-13 06:26:28', '2022-07-13 09:58:20'),
(55, 20, 73, '0.00', '150.00', 'PENDIENTE', '0.00', 6, '2022-07-13 06:28:08', '2022-07-13 09:51:18'),
(57, 20, 24, '1.00', '577.05', 'PENDIENTE', '0.00', 6, '2022-07-13 06:35:09', '2022-07-13 09:59:06'),
(58, 20, 51, '0.00', '368.41', 'PENDIENTE', '0.00', 6, '2022-07-13 06:56:25', '2022-07-13 09:58:14');

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
('Yg3rdyflKsccyMw4xIzoh4NIH1p8C9C83LPPaoAA', 4, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.114 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWTBSOFJ3WnprTllpY2c0MHNaOUJQZHlSUGE3bVBBdFRWbjZmcWZlUyI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDA6Imh0dHA6Ly9zaXN0ZW1hLnRlc3Qvb3BlcmF0b3IvUHJlLXJlc2VydmEiO31zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTo0O30=', 1657689555);

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
(20, 44, '2.00', '1909.30', 7, NULL, NULL),
(21, 3, '2.00', '1385.96', 7, NULL, NULL),
(22, 11, '1.00', '405.08', 7, NULL, NULL),
(23, 57, '9.00', '4519.53', 7, NULL, NULL),
(24, 28, '1.00', '515.10', 7, NULL, NULL),
(25, 50, '1.00', '846.80', 7, NULL, NULL),
(26, 3, '4.00', '1785.96', 6, NULL, NULL),
(27, 57, '18.00', '6626.04', 6, NULL, NULL),
(28, 24, '2.00', '1077.05', 6, NULL, NULL),
(29, 9, '5.00', '1624.84', 6, NULL, NULL),
(30, 44, '6.00', '3163.95', 6, NULL, NULL),
(31, 21, '4.00', '1385.44', 6, NULL, NULL),
(32, 65, '1.00', '2600.00', 6, NULL, NULL),
(33, 52, '2.00', '400.00', 6, NULL, NULL),
(34, 72, '5.00', '150.00', 5, NULL, NULL),
(35, 3, '3.00', '2300.00', 5, NULL, NULL),
(36, 57, '4.00', '1600.00', 5, NULL, NULL),
(37, 73, '8.00', '1200.00', 5, NULL, NULL),
(38, 44, '2.00', '400.00', 5, NULL, NULL),
(39, 57, '6.00', '2400.00', 4, NULL, NULL),
(40, 29, '2.00', '800.00', 4, NULL, NULL),
(41, 3, '1.00', '900.00', 4, NULL, NULL),
(42, 51, '5.00', '1750.00', 6, NULL, NULL),
(43, 72, '2.00', '150.00', 6, NULL, NULL),
(44, 73, '2.00', '120.00', 6, NULL, NULL),
(45, 66, '3.00', '135.00', 6, NULL, NULL);

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
(3, 1, '65116', '1700.00', 2, '2022-06-20 21:22:04', '2022-07-09 15:03:09'),
(4, 1, '76977', '1350.00', 2, '2022-06-20 21:22:04', '2022-07-09 15:04:53'),
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
(9, 3, 3, 2, '24121363', '2022-07-08', 'MAÑANA', 3, '750.00', '1700.00', '950.00', 'adsad', 3, 0, '2022-07-09 20:03:09', '2022-07-09 20:03:09'),
(10, 4, 4, 4, '45322833', '2022-07-08', 'NOCHE', 4, '800.00', '1350.00', '550.00', 'asas', 3, 0, '2022-07-09 20:04:02', '2022-07-09 20:04:53');

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
(8, 6, 1, 5, 5, '2022-07-10', 'MAÑANA', 6, 0, '2022-07-09 20:01:13', '2022-07-09 20:01:13'),
(9, 5, 4, 5, 5, '2022-07-10', 'MAÑANA', 6, 0, '2022-07-09 20:01:23', '2022-07-09 20:01:23'),
(10, 7, 2, 7, 7, '2022-07-10', 'NOCHE', 7, 0, '2022-07-09 20:01:41', '2022-07-09 20:01:58'),
(11, 8, 4, 8, 7, '2022-07-10', 'MAÑANA', 7, 1, '2022-07-09 20:01:52', '2022-07-09 20:02:02');

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
(1, '777269', 'Mr. Ford Vandervort', 'Kunze', 1, 'roob.brianne@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'nFhY4qi4tZD0LCwogwnPuqxUUqdv6dKDOgtKw2AIE9H35lHtvlCCwZ5Tnmiw', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '213312', 'Birdie Waelchi', 'Walker', 1, 'ernser.caden@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'CH5a14s3lYlYb4FhejjGVMjThqJqwEipakGBMIwD5doNHUluQ2dgFRakvM7k', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '109931', 'Randi Leuschke', 'Cormier', 2, 'amaya.feeney@example.org', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'tT4wc3FGZMgNxvTJCyrWeyYHkHPxt9RchcpUiGo6RyoInl1gQLZ96iS18V1R', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '854140', 'Dr. Levi Feest', 'Ondricka', 2, 'woodrow.bogan@example.com', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'PNxYjVl9JOGrq8S2VV8bKJlUnVY6nZgSxtE8VjsVGhoXiG5zsADIJKp8mEyl', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '912055', 'Erwin Green', 'Heidenreich', 3, 'hbeatty@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '0v37tsYVj0FVEUOEiByFpQoesb78gFUIUuvugw9TaIOWxFWFaCm8J6Y71EtL', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '502387', 'Bella Block', 'Bashirian', 3, 'sibyl08@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'n3wqWMahCOBtaxLTld7QtaDsqeJhRAmBLhGsOolvdzHlZskQGSnPnYkZ3nm9', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '981787', 'Jaylon Prosacco', 'Langosh', 4, 'pleuschke@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'rc7GJRvdk8Hja3W1jLepIOIhBPkUfcaM2TtoYLw1sJTXXmjxVBy2kQtGm8t1', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '588440', 'Irving Strosin', 'Langosh', 4, 'mercedes57@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'Xz2S4RCr9v6EVwxQhozRejcp04TFyIs2GCHh2Tfl34GSok2M0yzbvy4gDfuv', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '454006', 'Margarett Heller', 'Cruickshank', 5, 'oconner.sydnie@example.org', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'yy14ZVjsNaQLhhKXXAGP6fxeGY28MwPWIQgy3S7RDNGLs8JAxhpa1ugk64fO', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(10, '916293', 'Dr. Ryder Gutmann V', 'McLaughlin', 5, 'dprice@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '6asVBO6pjosFw4Qqz0y2G3EHNAZQ0jmscpsuYiXp9fVcAZzNuufoavxUkN0w', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
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
(81, 1, 1, 1, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:28', '2022-07-11 15:48:28'),
(82, 2, 2, 1, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:33', '2022-07-11 15:48:33'),
(83, 3, 3, 2, '2022-07-14', '1', 'NO VALIDADO', 0, '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(84, 4, 4, 2, '2022-07-14', '1', 'NO VALIDADO', 0, '2022-07-11 15:48:42', '2022-07-11 15:48:43'),
(85, 5, 5, 3, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:47', '2022-07-11 15:48:47'),
(86, 6, 6, 3, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:50', '2022-07-11 15:48:50'),
(87, 7, 7, 4, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:53', '2022-07-11 15:48:53'),
(88, 8, 8, 4, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:56', '2022-07-11 15:48:56'),
(89, 9, 9, 5, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:48:59', '2022-07-11 15:48:59'),
(90, 10, 10, 5, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:01', '2022-07-11 15:49:01'),
(91, 11, 11, 6, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:02', '2022-07-11 15:49:02'),
(92, 12, 12, 6, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:04', '2022-07-11 15:49:04'),
(93, 13, 13, 7, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:06', '2022-07-11 15:49:06'),
(94, 14, 14, 7, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:07', '2022-07-11 15:49:07'),
(95, 15, 15, 8, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:09', '2022-07-11 15:49:09'),
(96, 16, 16, 8, '2022-07-14', '1', 'PENDIENTE', 0, '2022-07-11 15:49:11', '2022-07-11 15:49:11');

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
(1266, 81, 95, 'ACEPTADO', 0, 103, NULL, NULL, NULL, NULL),
(1267, 81, 4, 'ACEPTADO', 0, NULL, 163, NULL, NULL, NULL),
(1268, 81, 35, 'ACEPTADO', 0, NULL, 163, NULL, NULL, NULL),
(1269, 81, 88, 'ACEPTADO', 0, NULL, 164, NULL, NULL, NULL),
(1270, 81, 96, 'ACEPTADO', 0, NULL, 165, NULL, NULL, NULL),
(1271, 81, 1, 'ACEPTADO', 0, 104, NULL, NULL, NULL, NULL),
(1272, 81, 23, 'ACEPTADO', 0, 104, NULL, NULL, NULL, NULL),
(1273, 81, 31, 'ACEPTADO', 0, 104, NULL, NULL, NULL, NULL),
(1274, 81, 84, 'ACEPTADO', 0, NULL, 166, NULL, NULL, NULL),
(1275, 81, 87, 'ACEPTADO', 0, NULL, 167, NULL, NULL, NULL),
(1276, 81, 18, 'ACEPTADO', 0, NULL, 168, NULL, NULL, NULL),
(1277, 81, 39, 'ACEPTADO', 0, NULL, 168, NULL, NULL, NULL),
(1278, 81, 90, 'ACEPTADO', 0, 105, NULL, NULL, NULL, NULL),
(1279, 81, 84, 'ACEPTADO', 0, NULL, 169, NULL, NULL, NULL),
(1280, 81, 32, 'ACEPTADO', 0, NULL, 170, NULL, NULL, NULL),
(1281, 81, 96, 'ACEPTADO', 0, NULL, 171, NULL, NULL, NULL),
(1282, 82, 95, 'ACEPTADO', 0, 106, NULL, NULL, NULL, NULL),
(1283, 82, 4, 'ACEPTADO', 0, NULL, 172, NULL, NULL, NULL),
(1284, 82, 35, 'ACEPTADO', 0, NULL, 172, NULL, NULL, NULL),
(1285, 82, 88, 'ACEPTADO', 0, NULL, 173, NULL, NULL, NULL),
(1286, 82, 96, 'ACEPTADO', 0, NULL, 174, NULL, NULL, NULL),
(1287, 82, 1, 'ACEPTADO', 0, 107, NULL, NULL, NULL, NULL),
(1288, 82, 23, 'ACEPTADO', 0, 107, NULL, NULL, NULL, NULL),
(1289, 82, 31, 'ACEPTADO', 0, 107, NULL, NULL, NULL, NULL),
(1290, 82, 84, 'ACEPTADO', 0, NULL, 175, NULL, NULL, NULL),
(1291, 82, 87, 'ACEPTADO', 0, NULL, 176, NULL, NULL, NULL),
(1292, 82, 18, 'ACEPTADO', 0, NULL, 177, NULL, NULL, NULL),
(1293, 82, 39, 'ACEPTADO', 0, NULL, 177, NULL, NULL, NULL),
(1294, 82, 90, 'ACEPTADO', 0, 108, NULL, NULL, NULL, NULL),
(1295, 82, 84, 'ACEPTADO', 0, NULL, 178, NULL, NULL, NULL),
(1296, 82, 32, 'ACEPTADO', 0, NULL, 179, NULL, NULL, NULL),
(1297, 82, 96, 'ACEPTADO', 0, NULL, 180, NULL, NULL, NULL),
(1298, 83, 95, 'ACEPTADO', 0, 97, NULL, NULL, NULL, NULL),
(1299, 83, 51, 'RECOMENDADO', 0, NULL, 145, NULL, NULL, NULL),
(1300, 83, 62, 'RECOMENDADO', 0, NULL, 146, NULL, NULL, NULL),
(1301, 83, 82, 'RECOMENDADO', 0, NULL, 147, NULL, NULL, NULL),
(1302, 83, 1, 'ACEPTADO', 0, 98, NULL, NULL, NULL, NULL),
(1303, 83, 23, 'ACEPTADO', 0, 98, NULL, NULL, NULL, NULL),
(1304, 83, 31, 'ACEPTADO', 0, 98, NULL, NULL, NULL, NULL),
(1305, 83, 53, 'RECOMENDADO', 0, NULL, 148, NULL, NULL, NULL),
(1306, 83, 60, 'RECOMENDADO', 0, NULL, 149, NULL, NULL, NULL),
(1307, 83, 72, 'RECOMENDADO', 0, NULL, 150, NULL, NULL, NULL),
(1308, 83, 90, 'ACEPTADO', 0, 99, NULL, NULL, NULL, NULL),
(1309, 83, 53, 'RECOMENDADO', 0, NULL, 151, NULL, NULL, NULL),
(1310, 83, 78, 'RECOMENDADO', 0, NULL, 152, NULL, NULL, NULL),
(1311, 83, 82, 'RECOMENDADO', 0, NULL, 153, NULL, NULL, NULL),
(1312, 84, 95, 'ACEPTADO', 0, 100, NULL, NULL, NULL, NULL),
(1313, 84, 51, 'RECOMENDADO', 0, NULL, 154, NULL, NULL, NULL),
(1314, 84, 62, 'RECOMENDADO', 0, NULL, 155, NULL, NULL, NULL),
(1315, 84, 82, 'RECOMENDADO', 0, NULL, 156, NULL, NULL, NULL),
(1316, 84, 1, 'ACEPTADO', 0, 101, NULL, NULL, NULL, NULL),
(1317, 84, 23, 'ACEPTADO', 0, 101, NULL, NULL, NULL, NULL),
(1318, 84, 31, 'ACEPTADO', 0, 101, NULL, NULL, NULL, NULL),
(1319, 84, 53, 'RECOMENDADO', 0, NULL, 157, NULL, NULL, NULL),
(1320, 84, 60, 'RECOMENDADO', 0, NULL, 158, NULL, NULL, NULL),
(1321, 84, 72, 'RECOMENDADO', 0, NULL, 159, NULL, NULL, NULL),
(1322, 84, 90, 'ACEPTADO', 0, 102, NULL, NULL, NULL, NULL),
(1323, 84, 53, 'RECOMENDADO', 0, NULL, 160, NULL, NULL, NULL),
(1324, 84, 78, 'RECOMENDADO', 0, NULL, 161, NULL, NULL, NULL),
(1325, 84, 82, 'RECOMENDADO', 0, NULL, 162, NULL, NULL, NULL),
(1326, 85, 90, 'ACEPTADO', 0, 109, NULL, NULL, NULL, NULL),
(1327, 85, 84, 'ACEPTADO', 0, NULL, 181, NULL, NULL, NULL),
(1328, 85, 32, 'ACEPTADO', 0, NULL, 182, NULL, NULL, NULL),
(1329, 85, 96, 'ACEPTADO', 0, NULL, 183, NULL, NULL, NULL),
(1330, 85, 27, 'ACEPTADO', 0, 110, NULL, NULL, NULL, NULL),
(1331, 85, 8, 'ACEPTADO', 0, NULL, 184, NULL, NULL, NULL),
(1332, 85, 84, 'ACEPTADO', 0, NULL, 185, NULL, NULL, NULL),
(1333, 85, 88, 'ACEPTADO', 0, NULL, 186, NULL, NULL, NULL),
(1334, 85, 14, 'ACEPTADO', 0, 111, NULL, NULL, NULL, NULL),
(1335, 85, 4, 'ACEPTADO', 0, NULL, 187, NULL, NULL, NULL),
(1336, 85, 35, 'ACEPTADO', 0, NULL, 187, NULL, NULL, NULL),
(1337, 85, 18, 'ACEPTADO', 0, NULL, 188, NULL, NULL, NULL),
(1338, 85, 39, 'ACEPTADO', 0, NULL, 188, NULL, NULL, NULL),
(1339, 85, 32, 'ACEPTADO', 0, NULL, 189, NULL, NULL, NULL),
(1340, 86, 90, 'ACEPTADO', 0, 112, NULL, NULL, NULL, NULL),
(1341, 86, 84, 'ACEPTADO', 0, NULL, 190, NULL, NULL, NULL),
(1342, 86, 32, 'ACEPTADO', 0, NULL, 191, NULL, NULL, NULL),
(1343, 86, 96, 'ACEPTADO', 0, NULL, 192, NULL, NULL, NULL),
(1344, 86, 27, 'ACEPTADO', 0, 113, NULL, NULL, NULL, NULL),
(1345, 86, 8, 'ACEPTADO', 0, NULL, 193, NULL, NULL, NULL),
(1346, 86, 84, 'ACEPTADO', 0, NULL, 194, NULL, NULL, NULL),
(1347, 86, 88, 'ACEPTADO', 0, NULL, 195, NULL, NULL, NULL),
(1348, 86, 14, 'ACEPTADO', 0, 114, NULL, NULL, NULL, NULL),
(1349, 86, 4, 'ACEPTADO', 0, NULL, 196, NULL, NULL, NULL),
(1350, 86, 35, 'ACEPTADO', 0, NULL, 196, NULL, NULL, NULL),
(1351, 86, 18, 'ACEPTADO', 0, NULL, 197, NULL, NULL, NULL),
(1352, 86, 39, 'ACEPTADO', 0, NULL, 197, NULL, NULL, NULL),
(1353, 86, 32, 'ACEPTADO', 0, NULL, 198, NULL, NULL, NULL),
(1354, 87, 90, 'ACEPTADO', 0, 115, NULL, NULL, NULL, NULL),
(1355, 87, 84, 'ACEPTADO', 0, NULL, 199, NULL, NULL, NULL),
(1356, 87, 32, 'ACEPTADO', 0, NULL, 200, NULL, NULL, NULL),
(1357, 87, 96, 'ACEPTADO', 0, NULL, 201, NULL, NULL, NULL),
(1358, 87, 27, 'ACEPTADO', 0, 116, NULL, NULL, NULL, NULL),
(1359, 87, 8, 'ACEPTADO', 0, NULL, 202, NULL, NULL, NULL),
(1360, 87, 84, 'ACEPTADO', 0, NULL, 203, NULL, NULL, NULL),
(1361, 87, 88, 'ACEPTADO', 0, NULL, 204, NULL, NULL, NULL),
(1362, 87, 14, 'ACEPTADO', 0, 117, NULL, NULL, NULL, NULL),
(1363, 87, 4, 'ACEPTADO', 0, NULL, 205, NULL, NULL, NULL),
(1364, 87, 35, 'ACEPTADO', 0, NULL, 205, NULL, NULL, NULL),
(1365, 87, 18, 'ACEPTADO', 0, NULL, 206, NULL, NULL, NULL),
(1366, 87, 39, 'ACEPTADO', 0, NULL, 206, NULL, NULL, NULL),
(1367, 87, 32, 'ACEPTADO', 0, NULL, 207, NULL, NULL, NULL),
(1368, 88, 90, 'ACEPTADO', 0, 118, NULL, NULL, NULL, NULL),
(1369, 88, 84, 'ACEPTADO', 0, NULL, 208, NULL, NULL, NULL),
(1370, 88, 32, 'ACEPTADO', 0, NULL, 209, NULL, NULL, NULL),
(1371, 88, 96, 'ACEPTADO', 0, NULL, 210, NULL, NULL, NULL),
(1372, 88, 27, 'ACEPTADO', 0, 119, NULL, NULL, NULL, NULL),
(1373, 88, 8, 'ACEPTADO', 0, NULL, 211, NULL, NULL, NULL),
(1374, 88, 84, 'ACEPTADO', 0, NULL, 212, NULL, NULL, NULL),
(1375, 88, 88, 'ACEPTADO', 0, NULL, 213, NULL, NULL, NULL),
(1376, 88, 14, 'ACEPTADO', 0, 120, NULL, NULL, NULL, NULL),
(1377, 88, 4, 'ACEPTADO', 0, NULL, 214, NULL, NULL, NULL),
(1378, 88, 35, 'ACEPTADO', 0, NULL, 214, NULL, NULL, NULL),
(1379, 88, 18, 'ACEPTADO', 0, NULL, 215, NULL, NULL, NULL),
(1380, 88, 39, 'ACEPTADO', 0, NULL, 215, NULL, NULL, NULL),
(1381, 88, 32, 'ACEPTADO', 0, NULL, 216, NULL, NULL, NULL),
(1382, 89, 10, 'ACEPTADO', 0, 121, NULL, NULL, NULL, NULL),
(1383, 89, 29, 'ACEPTADO', 0, 121, NULL, NULL, NULL, NULL),
(1384, 89, 9, 'ACEPTADO', 0, NULL, 217, NULL, NULL, NULL),
(1385, 89, 21, 'ACEPTADO', 0, NULL, 217, NULL, NULL, NULL),
(1386, 89, 22, 'ACEPTADO', 0, NULL, 217, NULL, NULL, NULL),
(1387, 89, 24, 'ACEPTADO', 0, NULL, 217, NULL, NULL, NULL),
(1388, 89, 32, 'ACEPTADO', 0, NULL, 218, NULL, NULL, NULL),
(1389, 89, 96, 'ACEPTADO', 0, NULL, 219, NULL, NULL, NULL),
(1390, 89, 85, 'ACEPTADO', 0, 122, NULL, NULL, NULL, NULL),
(1391, 89, 4, 'ACEPTADO', 0, NULL, 220, NULL, NULL, NULL),
(1392, 89, 35, 'ACEPTADO', 0, NULL, 220, NULL, NULL, NULL),
(1393, 89, 9, 'ACEPTADO', 0, NULL, 221, NULL, NULL, NULL),
(1394, 89, 21, 'ACEPTADO', 0, NULL, 221, NULL, NULL, NULL),
(1395, 89, 22, 'ACEPTADO', 0, NULL, 221, NULL, NULL, NULL),
(1396, 89, 24, 'ACEPTADO', 0, NULL, 221, NULL, NULL, NULL),
(1397, 89, 88, 'ACEPTADO', 0, NULL, 222, NULL, NULL, NULL),
(1398, 89, 25, 'ACEPTADO', 0, 123, NULL, NULL, NULL, NULL),
(1399, 89, 8, 'ACEPTADO', 0, NULL, 223, NULL, NULL, NULL),
(1400, 89, 33, 'ACEPTADO', 0, NULL, 224, NULL, NULL, NULL),
(1401, 89, 96, 'ACEPTADO', 0, NULL, 225, NULL, NULL, NULL),
(1402, 90, 10, 'ACEPTADO', 0, 124, NULL, NULL, NULL, NULL),
(1403, 90, 29, 'ACEPTADO', 0, 124, NULL, NULL, NULL, NULL),
(1404, 90, 9, 'ACEPTADO', 0, NULL, 226, NULL, NULL, NULL),
(1405, 90, 21, 'ACEPTADO', 0, NULL, 226, NULL, NULL, NULL),
(1406, 90, 22, 'ACEPTADO', 0, NULL, 226, NULL, NULL, NULL),
(1407, 90, 24, 'ACEPTADO', 0, NULL, 226, NULL, NULL, NULL),
(1408, 90, 32, 'ACEPTADO', 0, NULL, 227, NULL, NULL, NULL),
(1409, 90, 96, 'ACEPTADO', 0, NULL, 228, NULL, NULL, NULL),
(1410, 90, 85, 'ACEPTADO', 0, 125, NULL, NULL, NULL, NULL),
(1411, 90, 4, 'ACEPTADO', 0, NULL, 229, NULL, NULL, NULL),
(1412, 90, 35, 'ACEPTADO', 0, NULL, 229, NULL, NULL, NULL),
(1413, 90, 9, 'ACEPTADO', 0, NULL, 230, NULL, NULL, NULL),
(1414, 90, 21, 'ACEPTADO', 0, NULL, 230, NULL, NULL, NULL),
(1415, 90, 22, 'ACEPTADO', 0, NULL, 230, NULL, NULL, NULL),
(1416, 90, 24, 'ACEPTADO', 0, NULL, 230, NULL, NULL, NULL),
(1417, 90, 88, 'ACEPTADO', 0, NULL, 231, NULL, NULL, NULL),
(1418, 90, 25, 'ACEPTADO', 0, 126, NULL, NULL, NULL, NULL),
(1419, 90, 8, 'ACEPTADO', 0, NULL, 232, NULL, NULL, NULL),
(1420, 90, 33, 'ACEPTADO', 0, NULL, 233, NULL, NULL, NULL),
(1421, 90, 96, 'ACEPTADO', 0, NULL, 234, NULL, NULL, NULL),
(1422, 91, 10, 'ACEPTADO', 0, 127, NULL, NULL, NULL, NULL),
(1423, 91, 29, 'ACEPTADO', 0, 127, NULL, NULL, NULL, NULL),
(1424, 91, 9, 'ACEPTADO', 0, NULL, 235, NULL, NULL, NULL),
(1425, 91, 21, 'ACEPTADO', 0, NULL, 235, NULL, NULL, NULL),
(1426, 91, 22, 'ACEPTADO', 0, NULL, 235, NULL, NULL, NULL),
(1427, 91, 24, 'ACEPTADO', 0, NULL, 235, NULL, NULL, NULL),
(1428, 91, 32, 'ACEPTADO', 0, NULL, 236, NULL, NULL, NULL),
(1429, 91, 96, 'ACEPTADO', 0, NULL, 237, NULL, NULL, NULL),
(1430, 91, 85, 'ACEPTADO', 0, 128, NULL, NULL, NULL, NULL),
(1431, 91, 4, 'ACEPTADO', 0, NULL, 238, NULL, NULL, NULL),
(1432, 91, 35, 'ACEPTADO', 0, NULL, 238, NULL, NULL, NULL),
(1433, 91, 9, 'ACEPTADO', 0, NULL, 239, NULL, NULL, NULL),
(1434, 91, 21, 'ACEPTADO', 0, NULL, 239, NULL, NULL, NULL),
(1435, 91, 22, 'ACEPTADO', 0, NULL, 239, NULL, NULL, NULL),
(1436, 91, 24, 'ACEPTADO', 0, NULL, 239, NULL, NULL, NULL),
(1437, 91, 88, 'ACEPTADO', 0, NULL, 240, NULL, NULL, NULL),
(1438, 91, 25, 'ACEPTADO', 0, 129, NULL, NULL, NULL, NULL),
(1439, 91, 8, 'ACEPTADO', 0, NULL, 241, NULL, NULL, NULL),
(1440, 91, 33, 'ACEPTADO', 0, NULL, 242, NULL, NULL, NULL),
(1441, 91, 96, 'ACEPTADO', 0, NULL, 243, NULL, NULL, NULL),
(1442, 92, 10, 'ACEPTADO', 0, 130, NULL, NULL, NULL, NULL),
(1443, 92, 29, 'ACEPTADO', 0, 130, NULL, NULL, NULL, NULL),
(1444, 92, 9, 'ACEPTADO', 0, NULL, 244, NULL, NULL, NULL),
(1445, 92, 21, 'ACEPTADO', 0, NULL, 244, NULL, NULL, NULL),
(1446, 92, 22, 'ACEPTADO', 0, NULL, 244, NULL, NULL, NULL),
(1447, 92, 24, 'ACEPTADO', 0, NULL, 244, NULL, NULL, NULL),
(1448, 92, 32, 'ACEPTADO', 0, NULL, 245, NULL, NULL, NULL),
(1449, 92, 96, 'ACEPTADO', 0, NULL, 246, NULL, NULL, NULL),
(1450, 92, 85, 'ACEPTADO', 0, 131, NULL, NULL, NULL, NULL),
(1451, 92, 4, 'ACEPTADO', 0, NULL, 247, NULL, NULL, NULL),
(1452, 92, 35, 'ACEPTADO', 0, NULL, 247, NULL, NULL, NULL),
(1453, 92, 9, 'ACEPTADO', 0, NULL, 248, NULL, NULL, NULL),
(1454, 92, 21, 'ACEPTADO', 0, NULL, 248, NULL, NULL, NULL),
(1455, 92, 22, 'ACEPTADO', 0, NULL, 248, NULL, NULL, NULL),
(1456, 92, 24, 'ACEPTADO', 0, NULL, 248, NULL, NULL, NULL),
(1457, 92, 88, 'ACEPTADO', 0, NULL, 249, NULL, NULL, NULL),
(1458, 92, 25, 'ACEPTADO', 0, 132, NULL, NULL, NULL, NULL),
(1459, 92, 8, 'ACEPTADO', 0, NULL, 250, NULL, NULL, NULL),
(1460, 92, 33, 'ACEPTADO', 0, NULL, 251, NULL, NULL, NULL),
(1461, 92, 96, 'ACEPTADO', 0, NULL, 252, NULL, NULL, NULL),
(1462, 93, 95, 'ACEPTADO', 0, 133, NULL, NULL, NULL, NULL),
(1463, 93, 4, 'ACEPTADO', 0, NULL, 253, NULL, NULL, NULL),
(1464, 93, 35, 'ACEPTADO', 0, NULL, 253, NULL, NULL, NULL),
(1465, 93, 88, 'ACEPTADO', 0, NULL, 254, NULL, NULL, NULL),
(1466, 93, 96, 'ACEPTADO', 0, NULL, 255, NULL, NULL, NULL),
(1467, 93, 94, 'ACEPTADO', 0, 134, NULL, NULL, NULL, NULL),
(1468, 93, 87, 'ACEPTADO', 0, NULL, 256, NULL, NULL, NULL),
(1469, 93, 38, 'ACEPTADO', 0, NULL, 257, NULL, NULL, NULL),
(1470, 93, 96, 'ACEPTADO', 0, NULL, 258, NULL, NULL, NULL),
(1471, 93, 14, 'ACEPTADO', 0, 135, NULL, NULL, NULL, NULL),
(1472, 93, 4, 'ACEPTADO', 0, NULL, 259, NULL, NULL, NULL),
(1473, 93, 35, 'ACEPTADO', 0, NULL, 259, NULL, NULL, NULL),
(1474, 93, 18, 'ACEPTADO', 0, NULL, 260, NULL, NULL, NULL),
(1475, 93, 39, 'ACEPTADO', 0, NULL, 260, NULL, NULL, NULL),
(1476, 93, 32, 'ACEPTADO', 0, NULL, 261, NULL, NULL, NULL),
(1477, 94, 95, 'ACEPTADO', 0, 136, NULL, NULL, NULL, NULL),
(1478, 94, 4, 'ACEPTADO', 0, NULL, 262, NULL, NULL, NULL),
(1479, 94, 35, 'ACEPTADO', 0, NULL, 262, NULL, NULL, NULL),
(1480, 94, 88, 'ACEPTADO', 0, NULL, 263, NULL, NULL, NULL),
(1481, 94, 96, 'ACEPTADO', 0, NULL, 264, NULL, NULL, NULL),
(1482, 94, 94, 'ACEPTADO', 0, 137, NULL, NULL, NULL, NULL),
(1483, 94, 87, 'ACEPTADO', 0, NULL, 265, NULL, NULL, NULL),
(1484, 94, 38, 'ACEPTADO', 0, NULL, 266, NULL, NULL, NULL),
(1485, 94, 96, 'ACEPTADO', 0, NULL, 267, NULL, NULL, NULL),
(1486, 94, 14, 'ACEPTADO', 0, 138, NULL, NULL, NULL, NULL),
(1487, 94, 4, 'ACEPTADO', 0, NULL, 268, NULL, NULL, NULL),
(1488, 94, 35, 'ACEPTADO', 0, NULL, 268, NULL, NULL, NULL),
(1489, 94, 18, 'ACEPTADO', 0, NULL, 269, NULL, NULL, NULL),
(1490, 94, 39, 'ACEPTADO', 0, NULL, 269, NULL, NULL, NULL),
(1491, 94, 32, 'ACEPTADO', 0, NULL, 270, NULL, NULL, NULL),
(1492, 95, 95, 'ACEPTADO', 0, 139, NULL, NULL, NULL, NULL),
(1493, 95, 4, 'ACEPTADO', 0, NULL, 271, NULL, NULL, NULL),
(1494, 95, 35, 'ACEPTADO', 0, NULL, 271, NULL, NULL, NULL),
(1495, 95, 88, 'ACEPTADO', 0, NULL, 272, NULL, NULL, NULL),
(1496, 95, 96, 'ACEPTADO', 0, NULL, 273, NULL, NULL, NULL),
(1497, 95, 94, 'ACEPTADO', 0, 140, NULL, NULL, NULL, NULL),
(1498, 95, 87, 'ACEPTADO', 0, NULL, 274, NULL, NULL, NULL),
(1499, 95, 38, 'ACEPTADO', 0, NULL, 275, NULL, NULL, NULL),
(1500, 95, 96, 'ACEPTADO', 0, NULL, 276, NULL, NULL, NULL),
(1501, 95, 14, 'ACEPTADO', 0, 141, NULL, NULL, NULL, NULL),
(1502, 95, 4, 'ACEPTADO', 0, NULL, 277, NULL, NULL, NULL),
(1503, 95, 35, 'ACEPTADO', 0, NULL, 277, NULL, NULL, NULL),
(1504, 95, 18, 'ACEPTADO', 0, NULL, 278, NULL, NULL, NULL),
(1505, 95, 39, 'ACEPTADO', 0, NULL, 278, NULL, NULL, NULL),
(1506, 95, 32, 'ACEPTADO', 0, NULL, 279, NULL, NULL, NULL),
(1507, 96, 95, 'ACEPTADO', 0, 142, NULL, NULL, NULL, NULL),
(1508, 96, 4, 'ACEPTADO', 0, NULL, 280, NULL, NULL, NULL),
(1509, 96, 35, 'ACEPTADO', 0, NULL, 280, NULL, NULL, NULL),
(1510, 96, 88, 'ACEPTADO', 0, NULL, 281, NULL, NULL, NULL),
(1511, 96, 96, 'ACEPTADO', 0, NULL, 282, NULL, NULL, NULL),
(1512, 96, 94, 'ACEPTADO', 0, 143, NULL, NULL, NULL, NULL),
(1513, 96, 87, 'ACEPTADO', 0, NULL, 283, NULL, NULL, NULL),
(1514, 96, 38, 'ACEPTADO', 0, NULL, 284, NULL, NULL, NULL),
(1515, 96, 96, 'ACEPTADO', 0, NULL, 285, NULL, NULL, NULL),
(1516, 96, 14, 'ACEPTADO', 0, 144, NULL, NULL, NULL, NULL),
(1517, 96, 4, 'ACEPTADO', 0, NULL, 286, NULL, NULL, NULL),
(1518, 96, 35, 'ACEPTADO', 0, NULL, 286, NULL, NULL, NULL),
(1519, 96, 18, 'ACEPTADO', 0, NULL, 287, NULL, NULL, NULL),
(1520, 96, 39, 'ACEPTADO', 0, NULL, 287, NULL, NULL, NULL),
(1521, 96, 32, 'ACEPTADO', 0, NULL, 288, NULL, NULL, NULL);

--
-- Disparadores `work_order_details`
--
DELIMITER $$
CREATE TRIGGER `componente_ordenado` AFTER UPDATE ON `work_order_details` FOR EACH ROW BEGIN
IF new.state = "ACEPTADO" THEN
	IF new.component_part_id IS NULL THEN
    	UPDATE component_implement SET state = "ORDENADO" WHERE id = new.component_implement_id;
    ELSE
    UPDATE component_part SET state = "ORDENADO" WHERE id = new.component_part_id;
    END IF;
END IF;
END
$$
DELIMITER ;
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
(1619, 81, 1, '2.00', '2022-07-11 15:48:28', '2022-07-11 15:48:28'),
(1620, 81, 5, '2.00', '2022-07-11 15:48:28', '2022-07-11 15:48:28'),
(1621, 81, 7, '4.00', '2022-07-11 15:48:28', '2022-07-11 15:48:29'),
(1622, 81, 22, '1.00', '2022-07-11 15:48:29', '2022-07-11 15:48:29'),
(1623, 81, 16, '1.00', '2022-07-11 15:48:29', '2022-07-11 15:48:29'),
(1624, 81, 12, '6.00', '2022-07-11 15:48:29', '2022-07-11 15:48:30'),
(1625, 81, 6, '1.00', '2022-07-11 15:48:30', '2022-07-11 15:48:30'),
(1626, 81, 8, '2.00', '2022-07-11 15:48:30', '2022-07-11 15:48:30'),
(1627, 81, 11, '2.00', '2022-07-11 15:48:30', '2022-07-11 15:48:30'),
(1628, 81, 31, '6.00', '2022-07-11 15:48:30', '2022-07-11 15:48:33'),
(1629, 81, 41, '6.00', '2022-07-11 15:48:30', '2022-07-11 15:48:33'),
(1630, 81, 49, '6.00', '2022-07-11 15:48:30', '2022-07-11 15:48:33'),
(1631, 81, 50, '12.00', '2022-07-11 15:48:30', '2022-07-11 15:48:33'),
(1632, 81, 28, '4.00', '2022-07-11 15:48:31', '2022-07-11 15:48:32'),
(1633, 81, 30, '8.00', '2022-07-11 15:48:31', '2022-07-11 15:48:32'),
(1634, 82, 1, '2.00', '2022-07-11 15:48:33', '2022-07-11 15:48:34'),
(1635, 82, 5, '2.00', '2022-07-11 15:48:33', '2022-07-11 15:48:34'),
(1636, 82, 7, '4.00', '2022-07-11 15:48:33', '2022-07-11 15:48:34'),
(1637, 82, 22, '1.00', '2022-07-11 15:48:34', '2022-07-11 15:48:34'),
(1638, 82, 16, '1.00', '2022-07-11 15:48:34', '2022-07-11 15:48:34'),
(1639, 82, 12, '6.00', '2022-07-11 15:48:34', '2022-07-11 15:48:35'),
(1640, 82, 6, '1.00', '2022-07-11 15:48:34', '2022-07-11 15:48:34'),
(1641, 82, 8, '2.00', '2022-07-11 15:48:34', '2022-07-11 15:48:35'),
(1642, 82, 11, '2.00', '2022-07-11 15:48:35', '2022-07-11 15:48:35'),
(1643, 82, 31, '6.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1644, 82, 41, '6.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1645, 82, 49, '6.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1646, 82, 50, '12.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1647, 82, 28, '4.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1648, 82, 30, '8.00', '2022-07-11 15:48:36', '2022-07-11 15:48:38'),
(1649, 83, 1, '2.00', '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(1650, 83, 5, '2.00', '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(1651, 83, 7, '4.00', '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(1652, 83, 3, '1.00', '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(1653, 83, 24, '1.00', '2022-07-11 15:48:39', '2022-07-11 15:48:39'),
(1654, 83, 57, '6.00', '2022-07-11 15:48:39', '2022-07-11 15:48:42'),
(1655, 83, 22, '1.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1656, 83, 16, '1.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1657, 83, 12, '6.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1658, 83, 6, '1.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1659, 83, 8, '2.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1660, 83, 11, '2.00', '2022-07-11 15:48:40', '2022-07-11 15:48:40'),
(1661, 83, 9, '3.00', '2022-07-11 15:48:41', '2022-07-11 15:48:42'),
(1662, 83, 21, '1.00', '2022-07-11 15:48:41', '2022-07-11 15:48:41'),
(1663, 83, 44, '2.00', '2022-07-11 15:48:41', '2022-07-11 15:48:41'),
(1664, 83, 28, '4.00', '2022-07-11 15:48:41', '2022-07-11 15:48:42'),
(1665, 83, 30, '8.00', '2022-07-11 15:48:41', '2022-07-11 15:48:42'),
(1666, 83, 52, '2.00', '2022-07-11 15:48:42', '2022-07-11 15:48:42'),
(1667, 84, 1, '2.00', '2022-07-11 15:48:42', '2022-07-11 15:48:43'),
(1668, 84, 5, '2.00', '2022-07-11 15:48:42', '2022-07-11 15:48:43'),
(1669, 84, 7, '4.00', '2022-07-11 15:48:42', '2022-07-11 15:48:43'),
(1670, 84, 3, '1.00', '2022-07-11 15:48:43', '2022-07-11 15:48:43'),
(1671, 84, 24, '1.00', '2022-07-11 15:48:43', '2022-07-11 15:48:43'),
(1672, 84, 57, '6.00', '2022-07-11 15:48:43', '2022-07-11 15:48:47'),
(1673, 84, 22, '1.00', '2022-07-11 15:48:44', '2022-07-11 15:48:44'),
(1674, 84, 16, '1.00', '2022-07-11 15:48:44', '2022-07-11 15:48:44'),
(1675, 84, 12, '6.00', '2022-07-11 15:48:44', '2022-07-11 15:48:45'),
(1676, 84, 6, '1.00', '2022-07-11 15:48:44', '2022-07-11 15:48:44'),
(1677, 84, 8, '2.00', '2022-07-11 15:48:44', '2022-07-11 15:48:44'),
(1678, 84, 11, '2.00', '2022-07-11 15:48:44', '2022-07-11 15:48:44'),
(1679, 84, 9, '3.00', '2022-07-11 15:48:45', '2022-07-11 15:48:47'),
(1680, 84, 21, '1.00', '2022-07-11 15:48:45', '2022-07-11 15:48:45'),
(1681, 84, 44, '2.00', '2022-07-11 15:48:45', '2022-07-11 15:48:45'),
(1682, 84, 28, '4.00', '2022-07-11 15:48:45', '2022-07-11 15:48:46'),
(1683, 84, 30, '8.00', '2022-07-11 15:48:45', '2022-07-11 15:48:47'),
(1684, 84, 52, '2.00', '2022-07-11 15:48:46', '2022-07-11 15:48:47'),
(1685, 85, 28, '2.00', '2022-07-11 15:48:47', '2022-07-11 15:48:47'),
(1686, 85, 30, '4.00', '2022-07-11 15:48:47', '2022-07-11 15:48:48'),
(1687, 85, 31, '4.00', '2022-07-11 15:48:48', '2022-07-11 15:48:49'),
(1688, 85, 41, '4.00', '2022-07-11 15:48:48', '2022-07-11 15:48:49'),
(1689, 85, 49, '4.00', '2022-07-11 15:48:48', '2022-07-11 15:48:49'),
(1690, 85, 50, '8.00', '2022-07-11 15:48:48', '2022-07-11 15:48:49'),
(1691, 86, 28, '2.00', '2022-07-11 15:48:51', '2022-07-11 15:48:51'),
(1692, 86, 30, '4.00', '2022-07-11 15:48:51', '2022-07-11 15:48:51'),
(1693, 86, 31, '4.00', '2022-07-11 15:48:51', '2022-07-11 15:48:52'),
(1694, 86, 41, '4.00', '2022-07-11 15:48:51', '2022-07-11 15:48:52'),
(1695, 86, 49, '4.00', '2022-07-11 15:48:51', '2022-07-11 15:48:53'),
(1696, 86, 50, '8.00', '2022-07-11 15:48:51', '2022-07-11 15:48:53'),
(1697, 87, 28, '2.00', '2022-07-11 15:48:53', '2022-07-11 15:48:53'),
(1698, 87, 30, '4.00', '2022-07-11 15:48:53', '2022-07-11 15:48:54'),
(1699, 87, 31, '4.00', '2022-07-11 15:48:54', '2022-07-11 15:48:55'),
(1700, 87, 41, '4.00', '2022-07-11 15:48:54', '2022-07-11 15:48:55'),
(1701, 87, 49, '4.00', '2022-07-11 15:48:54', '2022-07-11 15:48:55'),
(1702, 87, 50, '8.00', '2022-07-11 15:48:54', '2022-07-11 15:48:55'),
(1703, 88, 28, '2.00', '2022-07-11 15:48:56', '2022-07-11 15:48:57'),
(1704, 88, 30, '4.00', '2022-07-11 15:48:56', '2022-07-11 15:48:57'),
(1705, 88, 31, '4.00', '2022-07-11 15:48:57', '2022-07-11 15:48:58'),
(1706, 88, 41, '4.00', '2022-07-11 15:48:57', '2022-07-11 15:48:59'),
(1707, 88, 49, '4.00', '2022-07-11 15:48:57', '2022-07-11 15:48:59'),
(1708, 88, 50, '8.00', '2022-07-11 15:48:57', '2022-07-11 15:48:59'),
(1709, 93, 1, '2.00', '2022-07-11 15:49:06', '2022-07-11 15:49:06'),
(1710, 93, 5, '2.00', '2022-07-11 15:49:06', '2022-07-11 15:49:06'),
(1711, 93, 7, '4.00', '2022-07-11 15:49:06', '2022-07-11 15:49:06'),
(1712, 94, 1, '2.00', '2022-07-11 15:49:07', '2022-07-11 15:49:08'),
(1713, 94, 5, '2.00', '2022-07-11 15:49:07', '2022-07-11 15:49:08'),
(1714, 94, 7, '4.00', '2022-07-11 15:49:07', '2022-07-11 15:49:08'),
(1715, 95, 1, '2.00', '2022-07-11 15:49:09', '2022-07-11 15:49:10'),
(1716, 95, 5, '2.00', '2022-07-11 15:49:09', '2022-07-11 15:49:10'),
(1717, 95, 7, '4.00', '2022-07-11 15:49:10', '2022-07-11 15:49:10'),
(1718, 96, 1, '2.00', '2022-07-11 15:49:11', '2022-07-11 15:49:11'),
(1719, 96, 5, '2.00', '2022-07-11 15:49:11', '2022-07-11 15:49:11'),
(1720, 96, 7, '4.00', '2022-07-11 15:49:11', '2022-07-11 15:49:12');

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
  ADD KEY `component_implement_implement_id_foreign` (`implement_id`),
  ADD KEY `component_implement_work_order_id_foreign` (`work_order_id`);

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
  ADD KEY `operator_assigned_stocks_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `operator_assigned_stocks_ceco_id_foreign` (`ceco_id`);

--
-- Indices de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_stocks_user_id_foreign` (`user_id`),
  ADD KEY `operator_stocks_item_id_foreign` (`item_id`),
  ADD KEY `operator_stocks_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `operator_stocks_ceco_id_foreign` (`ceco_id`);

--
-- Indices de la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_stock_details_user_id_foreign` (`user_id`),
  ADD KEY `operator_stock_details_item_id_foreign` (`item_id`),
  ADD KEY `operator_stock_details_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `operator_stock_details_order_request_detail_id_foreign` (`order_request_detail_id`),
  ADD KEY `operator_stock_details_ceco_id_foreign` (`ceco_id`);

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
  ADD KEY `pre_stockpiles_implement_foreign` (`implement_id`),
  ADD KEY `pre_stockpiles_pre_stockpile_date_id_foreign` (`pre_stockpile_date_id`);

--
-- Indices de la tabla `pre_stockpile_dates`
--
ALTER TABLE `pre_stockpile_dates`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pre_stockpile_details_pre_stockpile_foreign` (`pre_stockpile_id`),
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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT de la tabla `brands`
--
ALTER TABLE `brands`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=145;

--
-- AUTO_INCREMENT de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `component_part`
--
ALTER TABLE `component_part`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=289;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1341;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=75;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT de la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;

--
-- AUTO_INCREMENT de la tabla `order_dates`
--
ALTER TABLE `order_dates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `order_requests`
--
ALTER TABLE `order_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `order_request_details`
--
ALTER TABLE `order_request_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=118;

--
-- AUTO_INCREMENT de la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_dates`
--
ALTER TABLE `pre_stockpile_dates`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT de la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1522;

--
-- AUTO_INCREMENT de la tabla `work_order_required_materials`
--
ALTER TABLE `work_order_required_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1721;

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
  ADD CONSTRAINT `component_implement_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `component_implement_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

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
  ADD CONSTRAINT `operator_assigned_stocks_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
  ADD CONSTRAINT `operator_assigned_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_assigned_stocks_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `operator_assigned_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD CONSTRAINT `operator_stocks_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
  ADD CONSTRAINT `operator_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_stocks_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `operator_stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `operator_stock_details`
--
ALTER TABLE `operator_stock_details`
  ADD CONSTRAINT `operator_stock_details_ceco_id_foreign` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
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
  ADD CONSTRAINT `pre_stockpiles_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `pre_stockpiles_pre_stockpile_date_id_foreign` FOREIGN KEY (`pre_stockpile_date_id`) REFERENCES `pre_stockpile_dates` (`id`),
  ADD CONSTRAINT `pre_stockpiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  ADD CONSTRAINT `pre_stockpile_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `pre_stockpile_details_pre_stockpile_foreign` FOREIGN KEY (`pre_stockpile_id`) REFERENCES `pre_stockpiles` (`id`),
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

CREATE DEFINER=`root`@`localhost` EVENT `asignar_monto_ceco` ON SCHEDULE EVERY 1 MONTH STARTS '2022-06-01 00:00:00' ON COMPLETION NOT PRESERVE DISABLE DO UPDATE ceco_allocation_amounts SET is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

CREATE DEFINER=`root`@`localhost` EVENT `Listar_materiales_pedido` ON SCHEDULE EVERY 1 DAY STARTS '2022-06-27 00:00:00' ON COMPLETION PRESERVE DISABLE DO BEGIN
    /*-------Variables para la fecha para abrir el pedido--------*/
    DECLARE fecha_solicitud INT;
    DECLARE fecha_abrir_solicitud DATE;
    /*-------Obtener la fecha para abrir el pedido-------*/
    SELECT id,open_request INTO fecha_solicitud, fecha_abrir_solicitud FROM order_dates r WHERE r.state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
    IF(fecha_abrir_solicitud <= NOW()) THEN
        BEGIN
        /*-----------VARIABLES PARA DETENER CICLOS--------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_final INT DEFAULT 0;
        DECLARE pieza_final INT DEFAULT 0;
        /*--------------VARIABLES CABECERA SOLICITUD DE PEDIDO-------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        /*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
        DECLARE solicitud_pedido INT;
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
        DECLARE precio_componente DECIMAL(8,2);
        /*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
        DECLARE pieza INT;
        DECLARE horas_pieza DECIMAL(8,2);
        DECLARE tiempo_vida_pieza DECIMAL(8,2);
        DECLARE cantidad_pieza INT;
        DECLARE item_pieza INT;
        DECLARE precio_pieza DECIMAL(8,2);
        /*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
        DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id FROM implements;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        /*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
        OPEN cursor_implementos;
            bucle_implementos:LOOP
                IF implemento_final = 1 THEN
                    LEAVE bucle_implementos;
                END IF;
            /*-----------------------------------OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ---------------------------*/
                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
            /*-----------CREAR LA CABECERA DE LA SOLICITUD DE PEDIDO SI NO EXISTE EN LA FECHA ASIGNADA---------------*/
                IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND order_date_id = fecha_solicitud) THEN
                    INSERT INTO order_requests(user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
                /*-----------OBTENER ID DE LA CABECERA DE LA SOLICITUD DE PEDIDO-------------------*/
                    SELECT id INTO solicitud_pedido FROM order_requests WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND order_date_id = fecha_solicitud;
            /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
                    BEGIN
                        DECLARE cursor_componentes CURSOR FOR SELECT cim.component_id,i.estimated_price FROM component_implement_model cim INNER JOIN components c ON c.id = cim.component_id INNER JOIN items i ON i.id = c.item_id WHERE cim.implement_model_id = modelo_del_implemento;
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                        /*------------ABRIR CURSOR COMPONENTES---------------*/
                        OPEN cursor_componentes;
                            bucle_componentes:LOOP
                                IF componente_final = 1 THEN
                                    LEAVE bucle_componentes;
                                END IF;
                                /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                                FETCH cursor_componentes INTO componente,precio_componente;
                                /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                                IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                                    INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                                END IF;
                                /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                                SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                                SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                                IF horas_componente >= tiempo_vida_componente THEN
                                    SELECT tiempo_vida_componente INTO horas_componente;
                                END IF;
                                /*---------------CALCULAR CUANTOS RECAMBIOS NECESITARÁ EN 2 MESES-----------------------------------*/
                                SELECT FLOOR((horas_componente+336)/tiempo_vida_componente) INTO cantidad_componente;
                                /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                IF(cantidad_componente > 0) THEN
                                    /*-----------PEDIR MATERIAL---------------------*/
                                    IF NOT EXISTS(SELECT * FROM order_request_details WHERE order_request_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE") THEN
                                        INSERT INTO order_request_details (order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_componente,cantidad_componente,precio_componente);
                                    ELSE
                                        UPDATE order_request_details SET quantity = quantity + cantidad_componente WHERE order_request_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE";
                                    END IF;
                                END IF;
                                    /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                                BEGIN
                                    DECLARE cursor_piezas CURSOR FOR SELECT cpm.part,i.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items i ON i.id = c.item_id WHERE cpm.component = componente;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                    /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                    OPEN cursor_piezas;
                                        bucle_piezas:LOOP
                                            IF pieza_final = 1 THEN
                                                LEAVE bucle_piezas;
                                            END IF;
                                                /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                            FETCH cursor_piezas INTO pieza,precio_pieza;
                                                /*----------------COMPROBAR SI EXISTE LA PIEZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                            IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                            END IF;
                                            /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                            SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                            /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                            SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                            IF(horas_pieza >= tiempo_vida_pieza)THEN
                                                SELECT tiempo_vida_pieza INTO horas_pieza;
                                            END IF;
                                            /*---------------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES-----------------------------------*/
                                            SELECT FLOOR((horas_pieza+336)/tiempo_vida_pieza) INTO cantidad_pieza;
                                            /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                            IF(cantidad_pieza > 0) THEN
                                                /*-----------PEDIR MATERIAL---------------------*/
                                                IF NOT EXISTS(SELECT * FROM order_request_details WHERE order_request_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE") THEN
                                                    INSERT INTO order_request_details (order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,(cantidad_pieza-cantidad_componente),precio_pieza);
                                                ELSE
                                                    UPDATE order_request_details SET quantity = (quantity + cantidad_pieza - cantidad_componente) WHERE order_request_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE";
                                                END IF;
                                            END IF;
                                        END LOOP bucle_piezas;
                                    CLOSE cursor_piezas;
                                    /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                    SELECT 0 INTO pieza_final;
                                END;
                            END LOOP bucle_componentes;
                        CLOSE cursor_componentes;
                        /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                        SELECT 0 INTO componente_final;
                    END;
                END IF;
            END LOOP bucle_implementos;
        CLOSE cursor_implementos;
        /*----------ABRIR FECHA DE PEDIDO-------------------*/
        UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
        END;
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
                        IF horas_componente >= tiempo_vida_componente THEN
                            SELECT tiempo_vida_componente INTO horas_componente;
                        END IF;
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
                            IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_componente) THEN
                                INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                            ELSE
                                UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_componente;
                            END IF;
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
                                                        /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                                        IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_componente) THEN
                                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_componente);
                                                        ELSE
                                                            UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_componente;
                                                        END IF;
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
                                        IF horas_pieza >= tiempo_vida_pieza THEN
                                            SELECT tiempo_vida_pieza INTO horas_pieza;
                                        END IF;
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
                                            IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_pieza) THEN
                                                INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                            ELSE
                                                UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_pieza;
                                            END IF;
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
                                                                        /*------------PONER EL MATERIAL REQUERIDO----------------------------------------*/
                                                                        IF NOT EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = orden_trabajo AND item_id = item_pieza) THEN
                                                                            INSERT INTO work_order_required_materials(work_order_id,item_id) VALUES (orden_trabajo,item_pieza);
                                                                        ELSE
                                                                            UPDATE work_order_required_materials SET quantity = quantity + 1 WHERE work_order_id = orden_trabajo AND item_id = item_pieza;
                                                                        END IF;
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

CREATE DEFINER=`root`@`localhost` EVENT `Listar_prereserva` ON SCHEDULE EVERY 1 DAY STARTS '2022-06-27 00:00:00' ON COMPLETION NOT PRESERVE DISABLE DO BEGIN
    /*-------Variables para la fecha para abrir el pedido--------*/
    DECLARE fecha_solicitud INT;
    DECLARE fecha_abrir_solicitud DATE;
    /*-------Obtener la fecha para abrir el pedido-------*/
    SELECT id,open_pre_stockpile INTO fecha_solicitud, fecha_abrir_solicitud FROM pre_stockpile_dates WHERE state = "PENDIENTE" ORDER BY open_pre_stockpile ASC LIMIT 1;
    IF(fecha_abrir_solicitud <= NOW()) THEN
        BEGIN
        /*-----------VARIABLES PARA DETENER CICLOS--------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_final INT DEFAULT 0;
        DECLARE pieza_final INT DEFAULT 0;
        /*--------------VARIABLES CABECERA SOLICITUD DE PEDIDO-------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        DECLARE ceco INT;
        DECLARE almacen INT;
        /*--------------VARIABLES PARA EL DETALLE DE ORDEN DE TRABAJO---------*/
        DECLARE solicitud_pedido INT;
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
        DECLARE precio_componente DECIMAL(8,2);
        /*-------------VARIABLES PARA ALMCENAR DATOS DE LA PIEZA--------------*/
        DECLARE pieza INT;
        DECLARE horas_pieza DECIMAL(8,2);
        DECLARE tiempo_vida_pieza DECIMAL(8,2);
        DECLARE cantidad_pieza INT;
        DECLARE item_pieza INT;
        DECLARE precio_pieza DECIMAL(8,2);
        /*-------------CURSOR PARA ITERAR LOS IMPLEMENTO------*/
        DECLARE cursor_implementos CURSOR FOR SELECT i.id,i.implement_model_id,i.user_id,i.ceco_id,w.id FROM implements i INNER JOIN warehouses w ON w.location_id = i.location_id;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        /*-------------ABRIR CURSOR DE IMPLEMENTOS------------*/
        OPEN cursor_implementos;
            bucle_implementos:LOOP
                IF implemento_final = 1 THEN
                    LEAVE bucle_implementos;
                END IF;
            /*-----------------------------------OBTENER EL ID Y EL MODELO DEL IMPLEMENTO ---------------------------*/
                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable,ceco,almacen;
            /*-----------CREAR LA CABECERA DE LA SOLICITUD DE PEDIDO SI NO EXISTE EN LA FECHA ASIGNADA---------------*/
                IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_solicitud) THEN
                    INSERT INTO pre_stockpiles(user_id,implement_id,ceco_id,pre_stockpile_date_id) VALUES (responsable,implemento,ceco,fecha_solicitud);
                /*-----------OBTENER ID DE LA CABECERA DE LA SOLICITUD DE PEDIDO-------------------*/
                    SELECT id INTO solicitud_pedido FROM pre_stockpiles WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_solicitud;
            /*--------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO-------*/
                    BEGIN
                        DECLARE cursor_componentes CURSOR FOR SELECT cim.component_id,i.estimated_price FROM component_implement_model cim INNER JOIN components c ON c.id = cim.component_id INNER JOIN items i ON i.id = c.item_id WHERE cim.implement_model_id = modelo_del_implemento;
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                        /*------------ABRIR CURSOR COMPONENTES---------------*/
                        OPEN cursor_componentes;
                            bucle_componentes:LOOP
                                IF componente_final = 1 THEN
                                    LEAVE bucle_componentes;
                                END IF;
                                /*--------------------OBTENER EL COMPONENTE DEL IMPLEMENTO-------------------------*/
                                FETCH cursor_componentes INTO componente,precio_componente;
                                /*----------------COMPROBAR SI EXISTE EL COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_implement-------------*/
                                IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE") THEN
                                    INSERT INTO component_implement (component_id,implement_id) VALUES (componente,implemento);
                                END IF;
                                /*---------------OBTENER HORAS DEL COMPONENTE--------------------------*/
                                SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                /*---------------OBTENER EL TIEMPO DE VIDA DEL COMPONENTE------------------------*/
                                SELECT lifespan,item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                                IF horas_componente >= tiempo_vida_componente THEN
                                    SELECT tiempo_vida_componente INTO horas_componente;
                                END IF;
                                /*---------------CALCULAR CUANTOS RECAMBIOS NECESITARÁ EN 2 MESES-----------------------------------*/
                                SELECT FLOOR((horas_componente+168)/tiempo_vida_componente) INTO cantidad_componente;
                                /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                IF(cantidad_componente > 0) THEN
                                    /*-----------PEDIR MATERIAL---------------------*/
                                    IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE") THEN
                                        INSERT INTO pre_stockpile_details (pre_stockpile_id,item_id,quantity,price,warehouse_id) VALUES (solicitud_pedido,item_componente,cantidad_componente,precio_componente,almacen);
                                    ELSE
                                        UPDATE pre_stockpile_details SET quantity = quantity + cantidad_componente WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_componente AND state = "PENDIENTE";
                                    END IF;
                                END IF;
                                    /*-------------CURSOR PARA ITERAR POR CADA PIEZA DEL COMPONENTE-----------------------*/
                                BEGIN
                                    DECLARE cursor_piezas CURSOR FOR SELECT cpm.part,i.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items i ON i.id = c.item_id WHERE cpm.component = componente;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                    /*---------ABRIR CURSOR DE LAS PIEZAS DEL COMPONENTE--------------------*/
                                    OPEN cursor_piezas;
                                        bucle_piezas:LOOP
                                            IF pieza_final = 1 THEN
                                                LEAVE bucle_piezas;
                                            END IF;
                                                /*----OBTENER PIEZAS DEL COMPONENTE----------------------------*/
                                            FETCH cursor_piezas INTO pieza,precio_pieza;
                                                /*----------------COMPROBAR SI EXISTE LA PIEZA CON SU COMPONENTE CON SU IMPLEMENTO EN LA TABLA component_parts-------------*/
                                            IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                            END IF;
                                            /*---------------OBTENER HORAS DE LA PIEZA--------------------------*/
                                            SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                            /*---------------OBTENER EL TIEMPO DE VIDA DE LA PIEZA------------------------*/
                                            SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                            IF(horas_pieza >= tiempo_vida_pieza)THEN
                                                SELECT tiempo_vida_pieza INTO horas_pieza;
                                            END IF;
                                            /*---------------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES-----------------------------------*/
                                            SELECT FLOOR((horas_pieza+168)/tiempo_vida_pieza) INTO cantidad_pieza;
                                            /*---------------PEDIR LOS MATERIALES NECESARIOS PARA LOS DOS MESES-------------------------------*/
                                            IF(cantidad_pieza > 0) THEN
                                                /*-----------PEDIR MATERIAL---------------------*/
                                                IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE") THEN
                                                    INSERT INTO pre_stockpile_details (pre_stockpile_id,item_id,quantity,price,warehouse_id) VALUES (solicitud_pedido,item_pieza,cantidad_pieza,precio_pieza,almacen);
                                                ELSE
                                                    UPDATE pre_stockpile_details SET quantity = (quantity + cantidad_pieza - cantidad_componente) WHERE pre_stockpile_id = solicitud_pedido AND item_id = item_pieza AND state = "PENDIENTE";
                                                END IF;
                                            END IF;
                                        END LOOP bucle_piezas;
                                    CLOSE cursor_piezas;
                                    /*--------------------PONER PIEZA FINAL A 0-------------------*/
                                    SELECT 0 INTO pieza_final;
                                END;
                            END LOOP bucle_componentes;
                        CLOSE cursor_componentes;
                        /*--------------------PONER COMPONENTE FINAL A 0-------------------*/
                        SELECT 0 INTO componente_final;
                    END;
                END IF;
            END LOOP bucle_implementos;
        CLOSE cursor_implementos;
        /*----------ABRIR FECHA DE PEDIDO-------------------*/
        UPDATE pre_stockpile_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
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

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
