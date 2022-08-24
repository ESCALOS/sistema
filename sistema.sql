-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 24-08-2022 a las 08:09:57
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `CerrarPreReserva` ()   BEGIN
/*---Variables para la fecha para cerrar el pedido----------*/
DECLARE fecha_pre_reserva INT;
DECLARE fecha_cerrar_pre_reserva DATE;
/*-------Obtener la fecha para cerrar el pedido-------*/
SELECT id,close_pre_stockpile INTO fecha_pre_reserva, fecha_cerrar_pre_reserva FROM pre_stockpile_dates r WHERE r.state = "ABIERTO" ORDER BY open_request ASC LIMIT 1;
/*----Validar la fecha de cierre de pedido-----------*/
IF(fecha_cerrar_pre_reserva <= NOW()) THEN
/*--------Cerrar pedido----------------*/
UPDATE pre_stockpile_dates SET state = "CERRADO" WHERE state = "ABIERTO" LIMIT 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_frecuencia_mantenimientos` ()   BEGIN
DECLARE componente INT;
DECLARE tiempo_vida DECIMAL(8,2);
DECLARE comp_final INT DEFAULT 0;
DECLARE cur_comp CURSOR FOR SELECT c.id,c.lifespan FROM components c;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET comp_final = 1;
OPEN cur_comp;
	bucle:LOOP
    	IF comp_final = 1 THEN
        	LEAVE bucle;
        END IF;
        FETCH cur_comp INTO componente,tiempo_vida;
        INSERT INTO preventive_maintenance_frequencies(component_id,frequency) VALUES (componente,(tiempo_vida)/4);
    END LOOP bucle;
CLOSE cur_comp;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_rutinario` ()   BEGIN
	DECLARE programacion_tractor INT;
    DECLARE implemento INT;
    DECLARE usuario INT;
	DECLARE programado_final INT DEFAULT 0;
    DECLARE cursor_programacion CURSOR FOR SELECT ts.id,ts.implement_id,ts.user_id FROM tractor_schedulings ts WHERE DATE(ts.date) = DATE(NOW());
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET programado_final = 1;
    	OPEN cursor_programacion;
        	bucle_programacion:LOOP
            	IF programado_final = 1 THEN
                	LEAVE bucle_programacion;
                END IF;
                FETCH cursor_programacion INTO programacion_tractor,implemento,usuario;
                IF NOT EXISTS(SELECT * FROM routine_tasks WHERE implement_id = implemento AND date = DATE(NOW())) THEN
                	INSERT INTO routine_tasks (tractor_scheduling_id, implement_id, user_id, date) VALUES (programacion_tractor,implemento,usuario,NOW());
                END IF;
            END LOOP bucle_programacion;
        CLOSE cursor_programacion;
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
                                                /*------------MARCAR COMO NO VALIDADO HASTA QUE EL SUPERVISOR LO APRUEBE O LO RECHACE-------------*/
                                                IF NOT EXISTS(SELECT * FROM work_orders WHERE id = orden_trabajo AND state = "NO VALIDADO") THEN
                                                    UPDATE work_orders SET state = "NO VALIDADO" WHERE id = orden_trabajo;
                                                END IF;
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
    /*---------VARIABLES PARA LA ALMACENAR LA FECHA PARA ABRIR EL PEDIDO-----------------------------*/
        DECLARE fecha_solicitud INT;
        DECLARE fecha_abrir_solicitud DATE;
    /*---------OBTENER LA FECHA DE APERTURA DEL PEDIDO MÁS CERCANO-----------------------------------*/
        SELECT id,open_request INTO fecha_solicitud,fecha_abrir_solicitud FROM order_dates WHERE state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
    /*---------HACER EN CASO SEA FECHA DE ABRIR EL PEDIDO-----------------------------------------*/
        IF(fecha_abrir_solicitud <= NOW()) THEN
            BEGIN
                /*-----------VARIABLES PARA DETENER LOS CICLOS------------------------------*/
                    DECLARE implemento_final INT DEFAULT 0;
                    DECLARE componente_final INT DEFAULT 0;
                    DECLARE pieza_final INT DEFAULT 0;
                    DECLARE tarea_final INT DEFAULT 0;
                    DECLARE material_final INT DEFAULT 0;
                /*-----------VARIABLES PARA LA CABECERA DE LA SOLICITUD DE PEDIDO-----------*/
                    DECLARE implemento INT;
                    DECLARE responsable INT;
                /*-----------VARIABLES PARA EL DETALLE DE LA SOLICITUD DEL PEDIDO-----------*/
                    DECLARE solicitud_pedido INT;
                    DECLARE componente_del_implemento INT;
                    DECLARE pieza_del_componente INT;
                /*-----------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO---------------*/
                    DECLARE modelo_del_implemento INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE------------------*/
                    DECLARE componente INT;
                    DECLARE horas_componente DECIMAL(8,2);
                    DECLARE tiempo_vida_componente DECIMAL(8,2);
                    DECLARE cantidad_componente_recambio DECIMAL(8,2);
                    DECLARE cantidad_componente_preventivo DECIMAL(8,2);
                    DECLARE item_componente INT;
                    DECLARE precio_componente DECIMAL(8,2);
                    DECLARE frecuencia_componente DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_componente DECIMAL(8,2);
                    DECLARE tarea_componente INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA---------------------*/
                    DECLARE pieza INT;
                    DECLARE horas_pieza DECIMAL(8,2);
                    DECLARE tiempo_vida_pieza DECIMAL(8,2);
                    DECLARE cantidad_pieza_recambio DECIMAL(8,2);
                    DECLARE cantidad_pieza_preventivo DECIMAL(8,2);
                    DECLARE item_pieza INT;
                    DECLARE precio_pieza DECIMAL(8,2);
                    DECLARE frecuencia_pieza DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_pieza DECIMAL(8,2);
                    DECLARE tarea_pieza INT;
                /*-----------VARIABLES PARA MATERIAL-----------------------*/
                    DECLARE material INT;
                /*-----------CURSOR PARA ITERAR CADA IMPLEMENTO-----------------------------*/
                    DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id FROM implements;
                    DECLARE CONTINUE HANDLER for NOT FOUND SET implemento_final = 1;
                /*-----------ABRIR CURSOR DE LOS IMPLEMENTOS--------------------------------*/
                    OPEN cursor_implementos;
                        bucle_implementos:LOOP
                            /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS-------------*/
                                IF implemento_final = 1 THEN
                                    LEAVE bucle_implementos;
                                END IF;
                            /*---------OBTENER LOS DATOS DEL IMPLEMENTO DEL CICLO-----------------------*/
                                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
                            /*---------HACER EN CASO LA SOLICITUD DE PEDIDO SI NO ESTÁ CREADA AÚN-------*/
                                IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud) THEN
                                    /*----------------------CREAR CABECERA DE LA SOLICITUD DE PEDIDO---------------------------------*/
                                        INSERT INTO order_requests (user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
                                    /*----------------------OBTENER ID DE LA CABECERA DEL PEDIDO-------------------------------------*/
                                        SELECT id INTO solicitud_pedido FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud;
                                    /*----------------------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO DEL CICLO--------------*/
                                        BEGIN
                                            DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                                            /*--------------ABRIR CURSOR DE LOS COMPONENTES--------------------------------------------*/
                                                OPEN cursor_componentes;
                                                    bucle_componentes:LOOP
                                                        /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS COMPONENTES----------------------------------------*/
                                                            IF componente_final = 1 THEN
                                                                LEAVE bucle_componentes;
                                                            END IF;
                                                        /*---------OBTENER LOS DATOS DEL COMPONENTE DEL CICLO--------------------------------------------------*/
                                                            FETCH cursor_componentes INTO componente;
                                                        /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------------*/
                                                            IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento) THEN
                                                                /*-----------CREAR REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------*/
                                                                    INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
                                                            END IF;
                                                        /*---------OBTENER EL ID Y HORAS DEL COMPONENTE DEL IMPLEMENTO ----------------------------------------*/
                                                            SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                                        /*---------OBTENER TIEMPO DE VIDA Y EL ID DEL ITEM DEL COMPONENTE -------------------------------------*/
                                                            SELECT c.lifespan,c.item_id,i.estimated_price INTO tiempo_vida_componente,item_componente,precio_componente FROM components c INNER JOIN items i ON i.id = c.item_id WHERE c.id = componente;
                                                        /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DEL COMPONENTE--------------------------------*/
                                                            IF horas_componente > tiempo_vida_componente THEN
                                                                /*-----------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS-----------------------------------*/
                                                                SELECT tiempo_vida_componente INTO horas_componente;
                                                            END IF;
                                                        /*---------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES--------------------------------------------*/
                                                            SELECT FLOOR((horas_componente+336)/tiempo_vida_componente) INTO cantidad_componente_recambio;
                                                        /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------------*/
                                                            SELECT frequency INTO frecuencia_componente FROM preventive_maintenance_frequencies WHERE component_id = componente;
                                                        /*---------OBTENER HORAS DEL ÚLTIMO MANTENIMIENTO DEL COMPONENTE EN CASO HUBIERA-----------------------*/
                                                            IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_implement_id = componente_del_implemento AND t.type = "PREVENTIVO") THEN
                                                                SELECT component_hours INTO horas_ultimo_mantenimiento_componente FROM work_order_details WHERE component_implement_id = componente_del_implemento AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                            ELSE
                                                                SELECT 0 INTO horas_ultimo_mantenimiento_componente;
                                                            END IF;
                                                        /*---------HACER EN CASO NECESITE RECAMBIO-------------------------------------------------------------*/
                                                            IF cantidad_componente_recambio > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_componente_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "RECAMBIO";
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                            OPEN cursor_componente_tareas_recambio;
                                                                                bucle_componente_tareas_recambio:LOOP
                                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                        IF tarea_final = 1 THEN
                                                                                            LEAVE bucle_componente_tareas_recambio;
                                                                                        END IF;
                                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                        FETCH cursor_componente_tareas_recambio INTO tarea_componente;
                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                OPEN cursor_materiales_recambio;
                                                                                                    bucle_materiales:LOOP
                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                            IF material_final = 1 THEN
                                                                                                                LEAVE bucle_materiales;
                                                                                                            END IF;
                                                                                                        /*----------OBTENER EL MATERIAL DE LA TAREA----------------------------*/
                                                                                                            FETCH cursor_materiales_recambio INTO item_componente,cantidad_componente_recambio;
                                                                                                        /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                            IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_componente AND order_request_id = solicitud_pedido) THEN
                                                                                                                INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price,quantity_to_use) VALUES (solicitud_pedido,item_componente,cantidad_componente_recambio,precio_componente,cantidad_componente_recambio);
                                                                                                            ELSE
                                                                                                                UPDATE order_request_details SET quantity = quantity + cantidad_componente_recambio, quantity_to_use = quantity_to_use + cantidad_componente_recambio WHERE order_request_id = solicitud_pedido AND item_id = item_componente;
                                                                                                            END IF;
                                                                                                    END LOOP bucle_materiales;
                                                                                                CLOSE cursor_materiales_recambio;
                                                                                            /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                SELECT 0 INTO material_final;
                                                                                        END;
                                                                                END LOOP bucle_componente_tareas_recambio;
                                                                            CLOSE cursor_componente_tareas_recambio;
                                                                        /*--------RESETEAR CONTADOR DE TAREAS----------------------------------------------*/
                                                                            SELECT 0 INTO tarea_final;
                                                                    END;
                                                            ELSE
                                                                /*---------CALCULAR MANTENIMIENTO PREVENTIVOS----------------------------------------------------------*/
                                                                    SELECT (FLOOR((horas_ultimo_mantenimiento_componente+336)/frecuencia_componente) - cantidad_componente_recambio) INTO cantidad_componente_preventivo;
                                                                /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------------*/
                                                                    IF cantidad_componente_preventivo > 0 THEN
                                                                        /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------*/
                                                                            BEGIN
                                                                                DECLARE cursor_componente_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "PREVENTIVO";
                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                                    OPEN cursor_componente_tareas_preventivo;
                                                                                        bucle_componente_tareas_preventino:LOOP
                                                                                            /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                IF tarea_final = 1 THEN
                                                                                                    LEAVE bucle_componente_tareas_preventino;
                                                                                                END IF;
                                                                                            /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                                FETCH cursor_componente_tareas_preventivo INTO tarea_componente;
                                                                                            /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                                BEGIN
                                                                                                    DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                    /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                        OPEN cursor_materiales_preventivo;
                                                                                                            bucle_materiales:LOOP
                                                                                                                /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                    IF material_final = 1 THEN
                                                                                                                        LEAVE bucle_materiales;
                                                                                                                    END IF;
                                                                                                                /*----------OBTENER EL MATERIAL DE LA TAREA-----------------------------*/
                                                                                                                    FETCH cursor_materiales_preventivo INTO item_componente,cantidad_componente_preventivo;
                                                                                                                /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                                    IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_componente AND order_request_id = solicitud_pedido) THEN
                                                                                                                        INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price,quantity_to_use) VALUES (solicitud_pedido,item_componente,cantidad_componente_preventivo,precio_componente,cantidad_componente_preventivo);
                                                                                                                    ELSE
                                                                                                                        UPDATE order_request_details SET quantity = quantity + cantidad_componente_preventivo, quantity_to_use = quantity_to_use + cantidad_componente_preventivo WHERE order_request_id = solicitud_pedido AND item_id = item_componente;
                                                                                                                    END IF;
                                                                                                            END LOOP bucle_materiales;
                                                                                                        CLOSE cursor_materiales_preventivo;
                                                                                                    /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                        SELECT 0 INTO material_final;
                                                                                                END;
                                                                                        END LOOP bucle_componente_tareas_preventino;
                                                                                    CLOSE cursor_componente_tareas_preventivo;
                                                                                /*--------RESETEAR CONTADOR TAREAS-----------------------------------------------------------*/
                                                                                    SELECT 0 INTO tarea_final;
                                                                            END;
                                                                    END IF;
                                                                /*---------CURSOR PARA ITERAR CADA PIEZA DEL COMPONENTE-------------------------------------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_piezas CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                                                        /*---------ABRIR CURSOR PARA LAS PIEZAS--------------------------------------------------*/
                                                                            OPEN cursor_piezas;
                                                                                bucle_piezas:LOOP
                                                                                    /*---------DETENER CICLO CUANDO NO SE ENCUENTREN MAS PIEZAS---------------------------------------*/
                                                                                        IF pieza_final = 1 THEN
                                                                                            LEAVE bucle_piezas;
                                                                                        END IF;
                                                                                    /*---------OBTENER LOS DATOS DE LA PIEZA DEL CICLO------------------------------------------------*/
                                                                                        FETCH cursor_piezas INTO pieza;
                                                                                    /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DE LA PIEZA DEL COMPONENTE DEL IMPLEMENTO----*/
                                                                                        IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                                                            INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                                                                        END IF;
                                                                                    /*---------OBTENER ID Y HORAS DE LA PIEZA DEL COMPONENTE------------------------------------------*/
                                                                                        SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                                                                    /*---------OBTENER EL TIEMPO DE VIDA Y EL ID DEL ALMACEN DE LA PIEZA------------------------------*/
                                                                                        SELECT c.lifespan,c.item_id,i.estimated_price INTO tiempo_vida_pieza,item_pieza,precio_pieza FROM components c INNER JOIN items i ON i.id = c.item_id WHERE c.id = pieza;
                                                                                    /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DE LA PIEZA------------------------------*/
                                                                                        IF horas_pieza >= tiempo_vida_pieza THEN
                                                                                            /*---------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS----------*/
                                                                                                SELECT tiempo_vida_pieza INTO horas_pieza;
                                                                                        END IF;
                                                                                    /*---------CALCULAR SI NECESITA RECAMBIO DENTRO DE 2 MESES----------------------------------------*/
                                                                                        SELECT FLOOR((horas_pieza+336)/tiempo_vida_pieza) INTO cantidad_pieza_recambio;
                                                                                    /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DE LA PIEZA-----------------------------*/
                                                                                        SELECT frequency INTO frecuencia_pieza FROM preventive_maintenance_frequencies WHERE component_id = pieza;
                                                                                    /*---------OBTENER HORAS DEL ÚLTIMO MATENIMIENTO DE LA PIEZA EN CASO HUBIERA----------------------*/
                                                                                        IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1) THEN
                                                                                                SELECT wod.component_hours INTO horas_ultimo_mantenimiento_pieza FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                                                            ELSE
                                                                                                SELECT 0 INTO horas_ultimo_mantenimiento_pieza;
                                                                                            END IF;
                                                                                    /*---------HACER EN CASO NECESITE RECAMBIO--------------------------------------------------------*/
                                                                                        IF(cantidad_pieza_recambio > 0) THEN
                                                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                                                    BEGIN
                                                                                                        DECLARE cursor_pieza_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "RECAMBIO";
                                                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                                                            OPEN cursor_pieza_tareas_recambio;
                                                                                                                bucle_pieza_tareas_recambio:LOOP
                                                                                                                    /*----------DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                                        IF tarea_final = 1 THEN
                                                                                                                            LEAVE bucle_pieza_tareas_recambio;
                                                                                                                        END IF;
                                                                                                                    /*----------OBTENER LA TAREA DE LA PIEZA--------------------------------*/
                                                                                                                        FETCH cursor_pieza_tareas_recambio INTO tarea_pieza;
                                                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA---------------*/
                                                                                                                        BEGIN
                                                                                                                            DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                                OPEN cursor_materiales_recambio;
                                                                                                                                    bucle_materiales:LOOP
                                                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                            IF material_final = 1 THEN
                                                                                                                                                LEAVE bucle_materiales;
                                                                                                                                            END IF;
                                                                                                                                        /*----------OBTENER EL MATERIAL DE LA TAREA-------------------------------------*/
                                                                                                                                            FETCH cursor_materiales_recambio INTO item_pieza,cantidad_pieza_recambio;
                                                                                                                                        /*----------PONER MATERIALES PARA PEDIDO----------------------------------------*/
                                                                                                                                            IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_pieza AND order_request_id = solicitud_pedido) THEN
                                                                                                                                                INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price,quantity_to_use) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_recambio,precio_pieza,cantidad_pieza_recambio);
                                                                                                                                            ELSE
                                                                                                                                                UPDATE order_request_details SET quantity = quantity + cantidad_pieza_recambio, quantity_to_use = quantity_to_use + cantidad_pieza_recambio WHERE order_request_id = solicitud_pedido AND item_id = item_pieza;
                                                                                                                                            END IF;
                                                                                                                                    END LOOP bucle_materiales;
                                                                                                                                CLOSE cursor_materiales_recambio;
                                                                                                                            /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                                                SELECT 0 INTO material_final;
                                                                                                                        END;
                                                                                                                END LOOP bucle_pieza_tareas_recambio;
                                                                                                            CLOSE cursor_pieza_tareas_recambio;
                                                                                                        /*----------RESETEAR CONTADOR DE TAREAS----------------------------*/
                                                                                                            SELECT 0 INTO tarea_final;
                                                                                                    END;
                                                                                        END IF;
                                                                                    /*---------CALCULAR MANTENIMIENTO PREVENTIVOS-----------------------------------------------------*/
                                                                                        SELECT (FLOOR((horas_ultimo_mantenimiento_pieza+336)/frecuencia_pieza) - cantidad_pieza_recambio) INTO cantidad_pieza_preventivo;
                                                                                    /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS----------------------*/
                                                                                        IF cantidad_pieza_preventivo > 0 THEN
                                                                                            /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DE LA PIEZA-------------------------*/
                                                                                                BEGIN
                                                                                                    DECLARE cursor_pieza_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "PREVENTIVO";
                                                                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                                    /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LAS PIEZAS------------------------*/
                                                                                                        OPEN cursor_pieza_tareas_preventivo;
                                                                                                            bucle_pieza_tareas_preventivo:LOOP
                                                                                                                /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                                    IF tarea_final = 1 THEN
                                                                                                                        LEAVE bucle_pieza_tareas_preventivo;
                                                                                                                    END IF;
                                                                                                                /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                                                    FETCH cursor_pieza_tareas_preventivo INTO tarea_pieza;
                                                                                                                /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                                                    BEGIN
                                                                                                                        DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                        /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                            OPEN cursor_materiales_preventivo;
                                                                                                                                bucle_materiales:LOOP
                                                                                                                                    /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                        IF material_final = 1 THEN
                                                                                                                                            LEAVE bucle_materiales;
                                                                                                                                        END IF;
                                                                                                                                    /*----------OBTENER EL MATERIAL DE LA TAREA---------------------------*/
                                                                                                                                        FETCH cursor_materiales_preventivo INTO item_pieza,cantidad_pieza_preventivo;
                                                                                                                                    /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                                                        IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_pieza AND order_request_id = solicitud_pedido) THEN
                                                                                                                                            INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price,quantity_to_use) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_preventivo,precio_pieza,cantidad_pieza_preventivo);
                                                                                                                                        ELSE
                                                                                                                                            UPDATE order_request_details SET quantity = quantity + cantidad_pieza_preventivo, quantity_to_use = quantity_to_use + cantidad_pieza_preventivo WHERE order_request_id = solicitud_pedido AND item_id = item_pieza;
                                                                                                                                        END IF;
                                                                                                                                END LOOP bucle_materiales;
                                                                                                                            CLOSE cursor_materiales_preventivo;
                                                                                                                        /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                                            SELECT 0 INTO material_final;
                                                                                                                    END;
                                                                                                            END LOOP bucle_pieza_tareas_preventivo;
                                                                                                        CLOSE cursor_pieza_tareas_preventivo;
                                                                                                    /*----------------RESETEAR CONTADOR TAREAS----------------------------------------------*/
                                                                                                        SELECT 0 INTO tarea_final;
                                                                                                END;
                                                                                        END IF;
                                                                                END LOOP bucle_piezas;
                                                                            CLOSE cursor_piezas;
                                                                            /*--------RESETEAR CONTADOR DE PIEZAS-------------------------*/
                                                                                SELECT 0 INTO pieza_final;
                                                                    END;
                                                            END IF;
                                                        END LOOP bucle_componentes;
                                                CLOSE cursor_componentes;
                                            /*------------RESETEAR CONTADOR COMPONENTES-------------------*/
                                                SELECT 0 INTO componente_final;
                                        END;
                                END IF;
                        END LOOP bucle_implementos;
                    CLOSE cursor_implementos;
                /*---------RESETEAR CONTADOR IMPLEMENTOS---------------*/
                    SELECT 0 INTO implemento_final;
                /*---------ABRIR SOLICITUD DE PEDIDO-------------------*/
                    UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
            END;
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_prereserva` ()   BEGIN
    /*---------VARIABLES PARA LA ALMACENAR LA FECHA PARA ABRIR LA PRE-RESERVA-----------------------------*/
        DECLARE fecha_pre_reserva INT;
        DECLARE fecha_abrir_pre_reserva DATE;
    /*---------OBTENER LA FECHA DE APERTURA DE LA PRE-RESERVA MÁS CERCANA-----------------------------------*/
        SELECT id,open_pre_stockpile INTO fecha_pre_reserva,fecha_abrir_pre_reserva FROM pre_stockpile_dates WHERE state = "PENDIENTE" ORDER BY open_pre_stockpile ASC LIMIT 1;
    /*---------HACER EN CASO SEA FECHA DE ABRIR LA PRE-RESERVA-----------------------------------------*/
        IF(fecha_abrir_pre_reserva <= NOW()) THEN
            BEGIN
                /*-----------VARIABLES PARA DETENER LOS CICLOS------------------------------*/
                    DECLARE implemento_final INT DEFAULT 0;
                    DECLARE componente_final INT DEFAULT 0;
                    DECLARE pieza_final INT DEFAULT 0;
                    DECLARE tarea_final INT DEFAULT 0;
                    DECLARE material_final INT DEFAULT 0;
                /*-----------VARIABLES PARA LA CABECERA DE LA PRE-RESERVA-------------------*/
                    DECLARE implemento INT;
                    DECLARE responsable INT;
                /*-----------VARIABLES PARA EL DETALLE DE LA PRE-RESERVA--------------------*/
                    DECLARE pre_reserva INT;
                    DECLARE componente_del_implemento INT;
                    DECLARE pieza_del_componente INT;
                /*-----------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO---------------*/
                    DECLARE modelo_del_implemento INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE------------------*/
                    DECLARE componente INT;
                    DECLARE horas_componente DECIMAL(8,2);
                    DECLARE tiempo_vida_componente DECIMAL(8,2);
                    DECLARE cantidad_componente_recambio DECIMAL(8,2);
                    DECLARE cantidad_componente_preventivo DECIMAL(8,2);
                    DECLARE item_componente INT;
                    DECLARE frecuencia_componente DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_componente DECIMAL(8,2);
                    DECLARE tarea_componente INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA---------------------*/
                    DECLARE pieza INT;
                    DECLARE horas_pieza DECIMAL(8,2);
                    DECLARE tiempo_vida_pieza DECIMAL(8,2);
                    DECLARE cantidad_pieza_recambio DECIMAL(8,2);
                    DECLARE cantidad_pieza_preventivo DECIMAL(8,2);
                    DECLARE item_pieza INT;
                    DECLARE frecuencia_pieza DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_pieza DECIMAL(8,2);
                    DECLARE tarea_pieza INT;
                /*-----------VARIABLES PARA MATERIAL----------------------------------------*/
                    DECLARE material INT;
                /*-----------CURSOR PARA ITERAR CADA IMPLEMENTO-----------------------------*/
                    DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id FROM implements;
                    DECLARE CONTINUE HANDLER for NOT FOUND SET implemento_final = 1;
                /*-----------ABRIR CURSOR DE LOS IMPLEMENTOS--------------------------------*/
                    OPEN cursor_implementos;
                        bucle_implementos:LOOP
                            /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS-------------*/
                                IF implemento_final = 1 THEN
                                    LEAVE bucle_implementos;
                                END IF;
                            /*---------OBTENER LOS DATOS DEL IMPLEMENTO DEL CICLO-----------------------*/
                                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
                            /*---------HACER EN CASO LA PRE-RESERVA SI NO ESTÁ CREADA AÚN---------------*/
                                IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva) THEN
                                    /*----------------------CREAR CABECERA DE LA PRE-RESERVA---------------------------------*/
                                        INSERT INTO pre_stockpiles (user_id,implement_id,pre_stockpile_date_id) VALUES (responsable,implemento,fecha_pre_reserva);
                                    /*----------------------OBTENER ID DE LA CABECERA DE LA PRE-RESERVA-------------------------------------*/
                                        SELECT id INTO pre_reserva FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva;
                                    /*----------------------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO DEL CICLO--------------*/
                                        BEGIN
                                            DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                                            /*--------------ABRIR CURSOR DE LOS COMPONENTES--------------------------------------------*/
                                                OPEN cursor_componentes;
                                                    bucle_componentes:LOOP
                                                        /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS COMPONENTES----------------------------------------*/
                                                            IF componente_final = 1 THEN
                                                                LEAVE bucle_componentes;
                                                            END IF;
                                                        /*---------OBTENER LOS DATOS DEL COMPONENTE DEL CICLO--------------------------------------------------*/
                                                            FETCH cursor_componentes INTO componente;
                                                        /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------------*/
                                                            IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento) THEN
                                                                /*-----------CREAR REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------*/
                                                                    INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
                                                            END IF;
                                                        /*---------OBTENER EL ID Y HORAS DEL COMPONENTE DEL IMPLEMENTO ----------------------------------------*/
                                                            SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                                        /*---------OBTENER TIEMPO DE VIDA Y EL ID DEL ITEM DEL COMPONENTE -------------------------------------*/
                                                            SELECT lifespan, item_id INTO tiempo_vida_componente,item_componente FROM components WHERE id = componente;
                                                        /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DEL COMPONENTE--------------------------------*/
                                                            IF horas_componente > tiempo_vida_componente THEN
                                                                /*-----------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS-----------------------------------*/
                                                                SELECT tiempo_vida_componente INTO horas_componente;
                                                            END IF;
                                                        /*---------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES--------------------------------------------*/
                                                            SELECT FLOOR((horas_componente+168)/tiempo_vida_componente) INTO cantidad_componente_recambio;
                                                        /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------------*/
                                                            SELECT frequency INTO frecuencia_componente FROM preventive_maintenance_frequencies WHERE component_id = componente;
                                                        /*---------OBTENER HORAS DEL ÚLTIMO MANTENIMIENTO DEL COMPONENTE EN CASO HUBIERA-----------------------*/
                                                            IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_implement_id = componente_del_implemento AND t.type = "PREVENTIVO") THEN
                                                                SELECT component_hours INTO horas_ultimo_mantenimiento_componente FROM work_order_details WHERE component_implement_id = componente_del_implemento AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                            ELSE
                                                                SELECT 0 INTO horas_ultimo_mantenimiento_componente;
                                                            END IF;
                                                        /*---------HACER EN CASO NECESITE RECAMBIO-------------------------------------------------------------*/
                                                            IF cantidad_componente_recambio > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_componente_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "RECAMBIO";
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                            OPEN cursor_componente_tareas_recambio;
                                                                                bucle_componente_tareas_recambio:LOOP
                                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                        IF tarea_final = 1 THEN
                                                                                            LEAVE bucle_componente_tareas_recambio;
                                                                                        END IF;
                                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                        FETCH cursor_componente_tareas_recambio INTO tarea_componente;
                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                OPEN cursor_materiales_recambio;
                                                                                                    bucle_materiales:LOOP
                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                            IF material_final = 1 THEN
                                                                                                                LEAVE bucle_materiales;
                                                                                                            END IF;
                                                                                                        /*----------OBTENER EL MATERIAL DE LA TAREA----------------------------*/
                                                                                                            FETCH cursor_materiales_recambio INTO item_componente,cantidad_componente_recambio;
                                                                                                        /*----------PONER MATERIALES PARA PRE-RESERVA------------------------------*/
                                                                                                            IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE item_id = item_componente AND pre_stockpile_id = pre_reserva) THEN
                                                                                                                INSERT INTO pre_stockpile_details(pre_stockpile_id,item_id,quantity,quantity_to_use) VALUES (pre_reserva,item_componente,cantidad_componente_recambio,cantidad_componente_recambio);
                                                                                                            ELSE
                                                                                                                UPDATE pre_stockpile_details SET quantity = quantity + cantidad_componente_recambio, quantity_to_use = quantity_to_use + cantidad_componente_recambio WHERE pre_stockpile_id = pre_reserva AND item_id = item_componente;
                                                                                                            END IF;
                                                                                                    END LOOP bucle_materiales;
                                                                                                CLOSE cursor_materiales_recambio;
                                                                                            /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                SELECT 0 INTO material_final;
                                                                                        END;
                                                                                END LOOP bucle_componente_tareas_recambio;
                                                                            CLOSE cursor_componente_tareas_recambio;
                                                                        /*--------RESETEAR CONTADOR DE TAREAS----------------------------------------------*/
                                                                            SELECT 0 INTO tarea_final;
                                                                    END;
                                                            END IF;
                                                        /*---------CALCULAR MANTENIMIENTO PREVENTIVOS----------------------------------------------------------*/
                                                            SELECT (FLOOR((horas_ultimo_mantenimiento_componente+168)/frecuencia_componente) - cantidad_componente_recambio) INTO cantidad_componente_preventivo;
                                                        /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------------*/
                                                            IF cantidad_componente_preventivo > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_componente_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "PREVENTIVO";
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                            OPEN cursor_componente_tareas_preventivo;
                                                                                bucle_componente_tareas_preventino:LOOP
                                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                        IF tarea_final = 1 THEN
                                                                                            LEAVE bucle_componente_tareas_preventino;
                                                                                        END IF;
                                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                        FETCH cursor_componente_tareas_preventivo INTO tarea_componente;
                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                OPEN cursor_materiales_preventivo;
                                                                                                    bucle_materiales:LOOP
                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                            IF material_final = 1 THEN
                                                                                                                LEAVE bucle_materiales;
                                                                                                            END IF;
                                                                                                        /*----------OBTENER EL MATERIAL DE LA TAREA-----------------------------*/
                                                                                                            FETCH cursor_materiales_preventivo INTO item_componente,cantidad_componente_preventivo;
                                                                                                        /*----------PONER MATERIALES PARA PRE-RESERVA------------------------------*/
                                                                                                            IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE item_id = item_componente AND pre_stockpile_id = pre_reserva) THEN
                                                                                                                INSERT INTO pre_stockpile_details(pre_stockpile_id,item_id,quantity,quantity_to_use) VALUES (pre_reserva,item_componente,cantidad_componente_preventivo,cantidad_componente_preventivo);
                                                                                                            ELSE
                                                                                                                UPDATE pre_stockpile_details SET quantity = quantity + cantidad_componente_preventivo, quantity_to_use = quantity_to_use + cantidad_componente_preventivo WHERE pre_stockpile_id = pre_reserva AND item_id = item_componente;
                                                                                                            END IF;
                                                                                                    END LOOP bucle_materiales;
                                                                                                CLOSE cursor_materiales_preventivo;
                                                                                            /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                SELECT 0 INTO material_final;
                                                                                        END;
                                                                                END LOOP bucle_componente_tareas_preventino;
                                                                            CLOSE cursor_componente_tareas_preventivo;
                                                                        /*--------RESETEAR CONTADOR TAREAS-----------------------------------------------------------*/
                                                                            SELECT 0 INTO tarea_final;
                                                                    END;
                                                            END IF;
                                                        /*---------CURSOR PARA ITERAR CADA PIEZA DEL COMPONENTE-------------------------------------------------*/
                                                            BEGIN
                                                                DECLARE cursor_piezas CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                                                /*---------ABRIR CURSOR PARA LAS PIEZAS--------------------------------------------------*/
                                                                    OPEN cursor_piezas;
                                                                        bucle_piezas:LOOP
                                                                            /*---------DETENER CICLO CUANDO NO SE ENCUENTREN MAS PIEZAS---------------------------------------*/
                                                                                IF pieza_final = 1 THEN
                                                                                    LEAVE bucle_piezas;
                                                                                END IF;
                                                                            /*---------OBTENER LOS DATOS DE LA PIEZA DEL CICLO------------------------------------------------*/
                                                                                FETCH cursor_piezas INTO pieza;
                                                                            /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DE LA PIEZA DEL COMPONENTE DEL IMPLEMENTO----*/
                                                                                IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                                                    INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                                                                END IF;
                                                                            /*---------OBTENER ID Y HORAS DE LA PIEZA DEL COMPONENTE------------------------------------------*/
                                                                                SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                                                            /*---------OBTENER EL TIEMPO DE VIDA Y EL ID DEL ALMACEN DE LA PIEZA------------------------------*/
                                                                                SELECT lifespan, item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                                                            /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DE LA PIEZA------------------------------*/
                                                                                IF horas_pieza >= tiempo_vida_pieza THEN
                                                                                    /*---------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS----------*/
                                                                                        SELECT tiempo_vida_pieza INTO horas_pieza;
                                                                                END IF;
                                                                            /*---------CALCULAR SI NECESITA RECAMBIO DENTRO DE 2 MESES----------------------------------------*/
                                                                                SELECT FLOOR((horas_pieza+168)/tiempo_vida_pieza) INTO cantidad_pieza_recambio;
                                                                            /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DE LA PIEZA-----------------------------*/
                                                                                SELECT frequency INTO frecuencia_pieza FROM preventive_maintenance_frequencies WHERE component_id = pieza;
                                                                            /*---------OBTENER HORAS DEL ÚLTIMO MATENIMIENTO DE LA PIEZA EN CASO HUBIERA----------------------*/
                                                                                IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1) THEN
                                                                                        SELECT wod.component_hours INTO horas_ultimo_mantenimiento_pieza FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                                                    ELSE
                                                                                        SELECT 0 INTO horas_ultimo_mantenimiento_pieza;
                                                                                    END IF;
                                                                            /*---------HACER EN CASO NECESITE RECAMBIO--------------------------------------------------------*/
                                                                                IF(cantidad_pieza_recambio > 0) THEN
                                                                                        /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                                            BEGIN
                                                                                                DECLARE cursor_pieza_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "RECAMBIO";
                                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                                /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                                                    OPEN cursor_pieza_tareas_recambio;
                                                                                                        bucle_pieza_tareas_recambio:LOOP
                                                                                                            /*----------DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                                IF tarea_final = 1 THEN
                                                                                                                    LEAVE bucle_pieza_tareas_recambio;
                                                                                                                END IF;
                                                                                                            /*----------OBTENER LA TAREA DE LA PIEZA--------------------------------*/
                                                                                                                FETCH cursor_pieza_tareas_recambio INTO tarea_pieza;
                                                                                                            /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA---------------*/
                                                                                                                BEGIN
                                                                                                                    DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                    /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                        OPEN cursor_materiales_recambio;
                                                                                                                            bucle_materiales:LOOP
                                                                                                                                /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                    IF material_final = 1 THEN
                                                                                                                                        LEAVE bucle_materiales;
                                                                                                                                    END IF;
                                                                                                                                /*----------OBTENER EL MATERIAL DE LA TAREA-------------------------------------*/
                                                                                                                                    FETCH cursor_materiales_recambio INTO item_pieza,cantidad_pieza_recambio;
                                                                                                                                /*----------PONER MATERIALES PARA PRE-RESERVA----------------------------------------*/
                                                                                                                                    IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE item_id = item_pieza AND pre_stockpile_id = pre_reserva) THEN
                                                                                                                                        INSERT INTO pre_stockpile_details(pre_stockpile_id,item_id,quantity,quantity_to_use) VALUES (pre_reserva,item_pieza,cantidad_pieza_recambio,cantidad_pieza_recambio);
                                                                                                                                    ELSE
                                                                                                                                        UPDATE pre_stockpile_details SET quantity = quantity + cantidad_pieza_recambio, quantity_to_use = quantity_to_use + cantidad_pieza_recambio WHERE pre_stockpile_id = pre_reserva AND item_id = item_pieza;
                                                                                                                                    END IF;
                                                                                                                            END LOOP bucle_materiales;
                                                                                                                        CLOSE cursor_materiales_recambio;
                                                                                                                    /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                                        SELECT 0 INTO material_final;
                                                                                                                END;
                                                                                                        END LOOP bucle_pieza_tareas_recambio;
                                                                                                    CLOSE cursor_pieza_tareas_recambio;
                                                                                                /*----------RESETEAR CONTADOR DE TAREAS----------------------------*/
                                                                                                    SELECT 0 INTO tarea_final;
                                                                                            END;
                                                                                END IF;
                                                                            /*---------CALCULAR MANTENIMIENTO PREVENTIVOS-----------------------------------------------------*/
                                                                                SELECT (FLOOR((horas_ultimo_mantenimiento_pieza+168)/frecuencia_pieza) - cantidad_pieza_recambio) INTO cantidad_pieza_preventivo;
                                                                            /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS----------------------*/
                                                                                IF cantidad_pieza_preventivo > 0 THEN
                                                                                    /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DE LA PIEZA-------------------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_pieza_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "PREVENTIVO";
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                            /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LAS PIEZAS------------------------*/
                                                                                                OPEN cursor_pieza_tareas_preventivo;
                                                                                                    bucle_pieza_tareas_preventivo:LOOP
                                                                                                        /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                            IF tarea_final = 1 THEN
                                                                                                                LEAVE bucle_pieza_tareas_preventivo;
                                                                                                            END IF;
                                                                                                        /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                                            FETCH cursor_pieza_tareas_preventivo INTO tarea_pieza;
                                                                                                        /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                                            BEGIN
                                                                                                                DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                    OPEN cursor_materiales_preventivo;
                                                                                                                        bucle_materiales:LOOP
                                                                                                                            /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                IF material_final = 1 THEN
                                                                                                                                    LEAVE bucle_materiales;
                                                                                                                                END IF;
                                                                                                                            /*----------OBTENER EL MATERIAL DE LA TAREA---------------------------*/
                                                                                                                                FETCH cursor_materiales_preventivo INTO item_pieza,cantidad_pieza_preventivo;
                                                                                                                            /*----------PONER MATERIALES PARA PRE-RESERVA------------------------------*/
                                                                                                                                IF NOT EXISTS(SELECT * FROM pre_stockpile_details WHERE item_id = item_pieza AND pre_stockpile_id = pre_reserva) THEN
                                                                                                                                    INSERT INTO pre_stockpile_details(pre_stockpile_id,item_id,quantity,quantity_to_use) VALUES (pre_reserva,item_pieza,cantidad_pieza_preventivo,cantidad_pieza_preventivo);
                                                                                                                                ELSE
                                                                                                                                    UPDATE pre_stockpile_details SET quantity = quantity + cantidad_pieza_preventivo, quantity_to_use = quantity_to_use + cantidad_pieza_preventivo WHERE pre_stockpile_id = pre_reserva AND item_id = item_pieza;
                                                                                                                                END IF;
                                                                                                                        END LOOP bucle_materiales;
                                                                                                                    CLOSE cursor_materiales_preventivo;
                                                                                                                /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                                    SELECT 0 INTO material_final;
                                                                                                            END;
                                                                                                    END LOOP bucle_pieza_tareas_preventivo;
                                                                                                CLOSE cursor_pieza_tareas_preventivo;
                                                                                            /*----------------RESETEAR CONTADOR TAREAS----------------------------------------------*/
                                                                                                SELECT 0 INTO tarea_final;
                                                                                        END;
                                                                                END IF;
                                                                        END LOOP bucle_piezas;
                                                                    CLOSE cursor_piezas;
                                                                    /*--------RESETEAR CONTADOR DE PIEZAS-------------------------*/
                                                                        SELECT 0 INTO pieza_final;
                                                            END;
                                                    END LOOP bucle_componentes;
                                                CLOSE cursor_componentes;
                                            /*------------RESETEAR CONTADOR COMPONENTES-------------------*/
                                                SELECT 0 INTO componente_final;
                                        END;
                                END IF;
                        END LOOP bucle_implementos;
                    CLOSE cursor_implementos;
                /*---------RESETEAR CONTADOR IMPLEMENTOS---------------*/
                    SELECT 0 INTO implemento_final;
                /*---------ABRIR PRE-RESERVA-------------------*/
                    UPDATE pre_stockpile_dates SET state = "ABIERTO" WHERE id = fecha_pre_reserva;
            END;
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rutinario` ()   BEGIN
	DECLARE programacion_tractor INT;
    DECLARE implemento INT;
    DECLARE usuario INT;
	DECLARE programado_final INT DEFAULT 0;
    DECLARE fecha DATE;
    DECLARE cursor_programacion CURSOR FOR SELECT ts.id,ts.implement_id,ts.user_id,ts.date FROM tractor_schedulings ts;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET programado_final = 1;
    	OPEN cursor_programacion;
        	bucle_programacion:LOOP
            	IF programado_final = 1 THEN
                	LEAVE bucle_programacion;
                END IF;
                FETCH cursor_programacion INTO programacion_tractor,implemento,usuario,fecha;
                IF NOT EXISTS(SELECT * FROM routine_tasks WHERE implement_id = implemento AND date = fecha) THEN
                	INSERT INTO routine_tasks (tractor_scheduling_id, implement_id, user_id, date) VALUES (programacion_tractor,implemento,usuario,fecha);
                END IF;
            END LOOP bucle_programacion;
        CLOSE cursor_programacion;
END$$

DELIMITER ;

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
(1, '584070', 'magni', 1, '4000.00', '0.00', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '297800', 'distinctio', 1, '4000.00', '0.00', '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '421733', 'maxime', 2, '4000.00', '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '771845', 'quasi', 2, '4000.00', '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '057182', 'inventore', 3, '4000.00', '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '797793', 'neque', 3, '4000.00', '0.00', '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '931896', 'exercitationem', 4, '4000.00', '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '647952', 'recusandae', 4, '4000.00', '0.00', '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '182653', 'quam', 5, '4000.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(10, '983918', 'voluptas', 5, '4000.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(11, '690932', 'id', 6, '4000.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '066884', 'ut', 6, '4000.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '952893', 'quae', 7, '4000.00', '0.00', '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '579950', 'consequatur', 7, '4000.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(15, '790388', 'modi', 8, '4000.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '236075', 'corrupti', 8, '4000.00', '0.00', '2022-06-20 21:21:41', '2022-06-20 21:21:41');

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
,`sku` varchar(15)
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
(34, 59, 'qvjzldtw', 3, 0, '2974.00', NULL, NULL),
(37, 87, 'VÁLVULA', NULL, 0, '105.00', NULL, NULL),
(38, 88, 'BUJIA', NULL, 1, '272.00', NULL, NULL),
(40, 136, 'PERNO 1/2', NULL, 1, '494.00', NULL, NULL);

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
(145, 28, 1, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:01', '2022-08-12 16:20:01'),
(146, 8, 1, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(147, 20, 1, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(148, 28, 2, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(149, 8, 2, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(150, 20, 2, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(151, 28, 3, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(152, 8, 3, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(153, 20, 3, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(154, 28, 4, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(155, 8, 4, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(156, 20, 4, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(157, 20, 5, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(158, 19, 5, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(159, 22, 5, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(160, 20, 6, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(161, 19, 6, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(162, 22, 6, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(163, 20, 7, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(164, 19, 7, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(165, 22, 7, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(166, 20, 8, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(167, 19, 8, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(168, 22, 8, '0.00', 'PENDIENTE', NULL, '2022-08-12 16:20:05', '2022-08-12 16:20:05');

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
(289, 145, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:01', '2022-08-12 16:20:01'),
(290, 145, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:01', '2022-08-12 16:20:01'),
(291, 145, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:01', '2022-08-12 16:20:01'),
(292, 146, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(293, 146, 11, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(294, 146, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(295, 147, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(296, 147, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(297, 147, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(298, 148, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(299, 148, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(300, 148, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(301, 149, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(302, 149, 11, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(303, 149, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(304, 150, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(305, 150, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(306, 150, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:02', '2022-08-12 16:20:02'),
(307, 151, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(308, 151, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(309, 151, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(310, 152, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(311, 152, 11, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(312, 152, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(313, 153, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(314, 153, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(315, 153, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(316, 154, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(317, 154, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(318, 154, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(319, 155, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(320, 155, 11, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(321, 155, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(322, 156, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(323, 156, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(324, 156, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:03', '2022-08-12 16:20:03'),
(325, 157, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(326, 157, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(327, 157, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(328, 158, 3, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(329, 158, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(330, 158, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(331, 159, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(332, 159, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(333, 159, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(334, 160, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(335, 160, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(336, 160, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(337, 161, 3, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(338, 161, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(339, 161, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(340, 162, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(341, 162, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(342, 162, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(343, 163, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(344, 163, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(345, 163, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:04', '2022-08-12 16:20:04'),
(346, 164, 3, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(347, 164, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(348, 164, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(349, 165, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(350, 165, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(351, 165, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(352, 166, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(353, 166, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(354, 166, 33, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(355, 167, 3, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(356, 167, 4, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(357, 167, 13, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(358, 168, 2, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(359, 168, 23, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05'),
(360, 168, 29, '0.00', 'PENDIENTE', '2022-08-12 16:20:05', '2022-08-12 16:20:05');

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
-- Estructura de tabla para la tabla `general_order_requests`
--

CREATE TABLE `general_order_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `quantity_to_arrive` decimal(8,2) NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `sede_id` bigint(20) UNSIGNED NOT NULL,
  `order_date_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `general_order_requests`
--

INSERT INTO `general_order_requests` (`id`, `item_id`, `quantity`, `quantity_to_arrive`, `price`, `sede_id`, `order_date_id`, `created_at`, `updated_at`) VALUES
(100, 52, '17.00', '0.00', '120.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(101, 44, '40.00', '0.00', '45.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(102, 21, '45.00', '0.00', '25.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(103, 9, '37.00', '0.00', '25.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(104, 57, '144.00', '0.00', '15.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(105, 3, '24.00', '0.00', '50.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(106, 24, '13.00', '0.00', '130.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(107, 1, '26.00', '0.00', '450.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(108, 140, '4.00', '0.00', '150.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(109, 141, '2.00', '0.00', '200.00', 1, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(110, 44, '40.00', '0.00', '45.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(111, 3, '48.00', '0.00', '50.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(112, 24, '24.00', '0.00', '130.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(113, 4, '12.00', '0.00', '45.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(114, 57, '48.00', '0.00', '15.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(115, 52, '40.00', '0.00', '120.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(116, 9, '48.00', '0.00', '25.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04'),
(117, 142, '2.00', '0.00', '36.00', 2, 2, '2022-08-15 17:55:38', '2022-08-15 19:04:04');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `general_stocks`
--

CREATE TABLE `general_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `sede_id` bigint(20) UNSIGNED NOT NULL,
  `quantity_to_reserve` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `general_stocks`
--

INSERT INTO `general_stocks` (`id`, `item_id`, `quantity`, `price`, `sede_id`, `quantity_to_reserve`, `created_at`, `updated_at`) VALUES
(136, 52, '17.00', '2040.00', 1, '1.00', '2022-08-15 17:58:14', '2022-08-17 13:40:52'),
(137, 44, '40.00', '1800.00', 1, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:40:50'),
(138, 21, '45.00', '1125.00', 1, '1.00', '2022-08-15 17:58:14', '2022-08-17 13:40:48'),
(139, 9, '37.00', '925.00', 1, '2.00', '2022-08-15 17:58:14', '2022-08-17 13:40:45'),
(140, 57, '144.00', '2160.00', 1, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:40:43'),
(141, 3, '24.00', '1200.00', 1, '1.00', '2022-08-15 17:58:14', '2022-08-17 13:40:38'),
(142, 24, '13.00', '1690.00', 1, '1.00', '2022-08-15 17:58:14', '2022-08-17 13:40:40'),
(143, 1, '26.00', '11700.00', 1, '10.00', '2022-08-15 17:58:14', '2022-08-17 13:40:36'),
(144, 140, '4.00', '600.00', 1, '4.00', '2022-08-15 17:58:14', '2022-08-15 19:04:04'),
(145, 141, '2.00', '400.00', 1, '2.00', '2022-08-15 17:58:14', '2022-08-17 13:39:08'),
(146, 44, '40.00', '1800.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:21'),
(147, 3, '48.00', '2400.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:19'),
(148, 24, '24.00', '3120.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:17'),
(149, 4, '12.00', '540.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:10'),
(150, 57, '48.00', '720.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:15'),
(151, 52, '40.00', '4800.00', 2, '0.00', '2022-08-15 17:58:14', '2022-08-17 13:51:13'),
(152, 9, '48.00', '1200.00', 2, '25.00', '2022-08-15 17:58:14', '2022-08-17 13:51:07'),
(153, 142, '2.00', '72.00', 2, '1.00', '2022-08-15 17:58:14', '2022-08-17 13:51:25');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `general_stock_details`
--

CREATE TABLE `general_stock_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `movement` enum('INGRESO','SALIDA') NOT NULL DEFAULT 'INGRESO',
  `quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `quantity_to_use` decimal(8,2) NOT NULL DEFAULT 0.00,
  `quantity_to_reserve` decimal(8,2) NOT NULL DEFAULT 0.00,
  `sede_id` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `order_date_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `general_stock_details`
--

INSERT INTO `general_stock_details` (`id`, `item_id`, `movement`, `quantity`, `price`, `quantity_to_use`, `quantity_to_reserve`, `sede_id`, `is_canceled`, `order_date_id`, `created_at`, `updated_at`) VALUES
(360, 52, 'INGRESO', '16.00', '120.00', '16.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:52'),
(361, 44, 'INGRESO', '39.00', '45.00', '39.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:50'),
(362, 21, 'INGRESO', '44.00', '25.00', '44.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:48'),
(363, 9, 'INGRESO', '36.00', '25.00', '36.00', '1.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:45'),
(364, 57, 'INGRESO', '143.00', '15.00', '143.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:43'),
(365, 3, 'INGRESO', '23.00', '50.00', '23.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:38'),
(366, 24, 'INGRESO', '12.00', '130.00', '12.00', '0.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:40'),
(367, 1, 'INGRESO', '25.00', '450.00', '25.00', '9.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:40:36'),
(368, 140, 'INGRESO', '3.00', '150.00', '3.00', '3.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-15 22:58:14'),
(369, 141, 'INGRESO', '1.00', '200.00', '1.00', '1.00', 1, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:39:08'),
(370, 44, 'INGRESO', '39.00', '45.00', '39.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:21'),
(371, 3, 'INGRESO', '47.00', '50.00', '47.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:19'),
(372, 24, 'INGRESO', '23.00', '130.00', '23.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:17'),
(373, 4, 'INGRESO', '11.00', '45.00', '11.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:10'),
(374, 57, 'INGRESO', '47.00', '15.00', '47.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:15'),
(375, 52, 'INGRESO', '39.00', '120.00', '39.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:13'),
(376, 9, 'INGRESO', '47.00', '25.00', '47.00', '24.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:07'),
(377, 142, 'INGRESO', '1.00', '36.00', '1.00', '0.00', 2, 0, 2, '2022-08-15 22:58:14', '2022-08-17 13:51:25'),
(378, 44, 'INGRESO', '1.00', '45.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:21'),
(379, 3, 'INGRESO', '1.00', '50.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:19'),
(380, 24, 'INGRESO', '1.00', '130.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:17'),
(381, 4, 'INGRESO', '1.00', '45.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:10'),
(382, 57, 'INGRESO', '1.00', '15.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:15'),
(383, 52, 'INGRESO', '1.00', '120.00', '1.00', '0.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:51:13'),
(384, 9, 'INGRESO', '1.00', '25.00', '1.00', '1.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(385, 142, 'INGRESO', '1.00', '36.00', '1.00', '1.00', 2, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(386, 52, 'INGRESO', '1.00', '120.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(387, 44, 'INGRESO', '1.00', '45.00', '1.00', '0.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:40:22'),
(388, 21, 'INGRESO', '1.00', '25.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(389, 9, 'INGRESO', '1.00', '25.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(390, 57, 'INGRESO', '1.00', '15.00', '1.00', '0.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:40:16'),
(391, 3, 'INGRESO', '1.00', '50.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-17 13:40:11'),
(392, 24, 'INGRESO', '1.00', '130.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(393, 1, 'INGRESO', '1.00', '450.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(394, 140, 'INGRESO', '1.00', '150.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04'),
(395, 141, 'INGRESO', '1.00', '200.00', '1.00', '1.00', 1, 0, 2, '2022-08-16 00:04:04', '2022-08-16 00:04:04');

--
-- Disparadores `general_stock_details`
--
DELIMITER $$
CREATE TRIGGER `actualizar_movimiento_stock_general` AFTER UPDATE ON `general_stock_details` FOR EACH ROW BEGIN
	IF new.is_canceled AND new.is_canceled <> old.is_canceled THEN
    /*-------Descontar del stock general-----------------*/
		UPDATE general_stocks SET quantity = quantity - new.quantity, price = price - (new.price*new.quantity), quantity_to_reserve = quantity_to_reserve - new.quantity  WHERE item_id = new.item_id AND sede_id = new.sede_id;
    /*-------Aumentar en la cantidad por llegar------------*/
        IF (new.order_date_id IS NOT NULL) THEN
        	UPDATE general_order_requests SET quantity_to_arrive = quantity_to_arrive + new.quantity WHERE item_id = new.item_id AND sede_id = new.sede_id AND order_date_id = new.order_date_id LIMIT 1;
    	END IF;
    ELSE
    	/*-------Actualizar cantidad a reservada------------------*/
    	IF new.quantity_to_reserve <> old.quantity_to_reserve THEN
    		UPDATE general_stocks SET quantity_to_reserve = quantity_to_reserve - old.quantity_to_reserve + new.quantity_to_reserve WHERE item_id = new.item_id AND sede_id = new.sede_id;
    	END IF;
        /*------Actualizar cantidad del stock---------------------*/
        IF new.quantity_to_use <> old.quantity_to_use THEN
        	UPDATE general_stocks SET quantity = quantity - old.quantity_to_use + new.quantity_to_use, price = price - new.price*(old.quantity_to_use - new.quantity_to_use) WHERE item_id = new.item_id AND sede_id = new.sede_id;
        END IF;
	END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insertar_movimiento_stock_general` AFTER INSERT ON `general_stock_details` FOR EACH ROW BEGIN
	IF EXISTS(SELECT * FROM general_stocks WHERE item_id = new.item_id AND sede_id = new.sede_id) THEN
        UPDATE general_stocks SET quantity = quantity + new.quantity, price = price + (new.price*new.quantity), quantity_to_reserve = quantity_to_reserve + new.quantity WHERE item_id = new.item_id AND sede_id = new.sede_id;
	ELSE
    	INSERT INTO general_stocks (item_id, quantity, price, sede_id,quantity_to_reserve) VALUES (new.item_id, new.quantity, new.price*new.quantity, new.sede_id,new.quantity);
    END IF;
    IF (new.order_date_id IS NOT NULL) THEN
        	UPDATE general_order_requests SET quantity_to_arrive = quantity_to_arrive - new.quantity WHERE item_id = new.item_id AND sede_id = new.sede_id AND order_date_id = new.order_date_id LIMIT 1;
    END IF;
END
$$
DELIMITER ;

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
(1, 1, '5243', '701.05', 1, 1, 1, '2022-06-20 21:21:59', '2022-07-21 19:26:53'),
(2, 1, '2399', '1478.44', 2, 1, 2, '2022-06-20 21:21:59', '2022-07-21 19:26:17'),
(3, 1, '6977', '1239.11', 3, 2, 3, '2022-06-20 21:21:59', '2022-07-09 15:03:09'),
(4, 1, '9149', '803.56', 4, 2, 4, '2022-06-20 21:21:59', '2022-07-09 15:04:53'),
(5, 2, '3513', '43.59', 5, 3, 5, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(6, 2, '6295', '21.92', 6, 3, 6, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(7, 2, '4375', '91.21', 7, 4, 7, '2022-06-20 21:21:59', '2022-06-20 21:21:59'),
(8, 2, '6477', '28.34', 8, 4, 8, '2022-06-20 21:21:59', '2022-06-20 21:21:59');

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

INSERT INTO `items` (`id`, `sku`, `item`, `measurement_unit_id`, `estimated_price`, `type`, `is_active`, `created_at`, `updated_at`) VALUES
(1, '55268423', 'emibwyfg', 1, '450.00', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-08-13 21:53:34'),
(2, '93430686', 'fenphxjv', 8, '328.66', 'COMPONENTE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(3, '80410193', 'uodoiizm', 15, '50.00', 'PIEZA', 1, '2022-06-20 21:21:55', '2022-08-13 21:55:22'),
(4, '32172961', 'inqxlhvr', 25, '45.00', 'PIEZA', 0, '2022-06-20 21:21:55', '2022-08-13 21:55:18'),
(5, '24557228', 'ajshyciq', 35, '45.00', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-07-24 00:14:50'),
(6, '54017263', 'lsbacktu', 6, '353.62', 'FUNGIBLE', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(7, '88284457', 'kuvozafk', 12, '500.00', 'HERRAMIENTA', 0, '2022-06-20 21:21:55', '2022-07-21 22:57:15'),
(8, '44888932', 'hlfqhqzs', 36, '563.25', 'HERRAMIENTA', 0, '2022-06-20 21:21:55', '2022-06-20 21:21:55'),
(9, '63566827', 'ynxsloty', 13, '25.00', 'PIEZA', 1, '2022-06-20 21:21:55', '2022-08-13 21:55:29'),
(10, '76748747', 'vdmjztzo', 46, '255.15', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(11, '56684879', 'exitexcs', 7, '405.08', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(12, '79831941', 'vgldtuea', 1, '289.01', 'HERRAMIENTA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(13, '33326523', 'xazvmvok', 2, '892.36', 'COMPONENTE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(14, '80675228', 'nsknjzug', 16, '861.84', 'FUNGIBLE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(15, '26685018', 'malgbbvu', 34, '958.75', 'PIEZA', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(16, '60201284', 'mfduollm', 31, '934.97', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(17, '09000210', 'iinqimeg', 1, '906.47', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(18, '06619500', 'jrnuwort', 2, '276.26', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(19, '21102998', 'glqsvril', 7, '488.01', 'COMPONENTE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(20, '47215073', 'avpaglsu', 24, '642.75', 'HERRAMIENTA', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(21, '81323780', 'qrrmsgax', 15, '25.00', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-08-13 21:53:27'),
(22, '39157590', 'ybyvnshl', 2, '391.84', 'FUNGIBLE', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(23, '98004376', 'tqgvkyjd', 12, '973.03', 'COMPONENTE', 1, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(24, '36059421', 'hnvixqmu', 47, '130.00', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-08-13 21:55:20'),
(25, '95868526', 'nnxqjpih', 25, '289.79', 'PIEZA', 0, '2022-06-20 21:21:56', '2022-06-20 21:21:56'),
(26, '48468841', 'ztypliaa', 13, '228.07', 'PIEZA', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(27, '42247040', 'uufgzlwz', 29, '888.74', 'COMPONENTE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(28, '86544233', 'boemtgom', 31, '515.10', 'HERRAMIENTA', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(29, '89960915', 'sjepvnhk', 18, '4.00', 'PIEZA', 0, '2022-06-20 21:21:57', '2022-07-22 21:40:09'),
(30, '33672732', 'gjsfgooc', 32, '630.61', 'FUNGIBLE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(31, '86587497', 'xldizthx', 23, '315.89', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(32, '27197936', 'vzjkkcej', 27, '307.03', 'PIEZA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(33, '67302155', 'qyltgffe', 37, '819.03', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(34, '74638099', 'oozarwvm', 22, '797.90', 'COMPONENTE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(35, '42255844', 'ppqwbfqs', 24, '340.23', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(36, '51228546', 'jmgoppan', 48, '772.61', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(37, '98829047', 'gunhazga', 29, '364.29', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(38, '85574668', 'emdbfexa', 49, '920.70', 'FUNGIBLE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(39, '04366084', 'uydbihgf', 46, '305.84', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(40, '30753700', 'kcikmfjy', 2, '247.13', 'FUNGIBLE', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(41, '55132606', 'sxuwykmm', 40, '803.68', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(42, '19702921', 'ytqwfjkt', 13, '75.00', 'HERRAMIENTA', 1, '2022-06-20 21:21:57', '2022-07-21 23:36:33'),
(43, '91153538', 'pvphmrrt', 13, '984.46', 'COMPONENTE', 0, '2022-06-20 21:21:57', '2022-06-20 21:21:57'),
(44, '88209620', 'odzxmwyq', 3, '45.00', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-08-13 21:55:26'),
(45, '23261667', 'spnpzerr', 22, '894.30', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(46, '01253032', 'abqkzfka', 14, '697.98', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(47, '10226033', 'tdtlgqur', 32, '245.22', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(48, '54714028', 'omzaqrnd', 47, '521.61', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(49, '42080919', 'tkszkird', 34, '945.11', 'HERRAMIENTA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(50, '20962715', 'sncjkzkm', 10, '846.80', 'FUNGIBLE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(51, '35177831', 'igkjtofr', 11, '200.00', 'COMPONENTE', 0, '2022-06-20 21:21:58', '2022-07-21 22:56:38'),
(52, '13254575', 'lxlrfbxf', 2, '120.00', 'PIEZA', 0, '2022-06-20 21:21:58', '2022-08-13 21:55:27'),
(53, '34323256', 'tjhhvizw', 13, '952.16', 'PIEZA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(54, '36718680', 'fubvgxmw', 16, '675.23', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(55, '01411861', 'upvgdrsm', 29, '586.61', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(56, '63768263', 'uezoavoy', 1, '918.22', 'HERRAMIENTA', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(57, '66196453', 'peorviek', 46, '15.00', 'PIEZA', 1, '2022-06-20 21:21:58', '2022-08-13 21:55:24'),
(58, '85923667', 'qwieldov', 1, '483.13', 'HERRAMIENTA', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(59, '55183394', 'qvjzldtw', 50, '375.49', 'COMPONENTE', 1, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(60, '88387187', 'ouenaesm', 25, '473.77', 'FUNGIBLE', 0, '2022-06-20 21:21:58', '2022-06-20 21:21:58'),
(63, '35214885', 'shino', 9, '560.00', 'FUNGIBLE', 1, '2022-07-01 09:28:01', '2022-07-01 09:28:01'),
(64, '35214884', 'ruka', 3, '7850.00', 'HERRAMIENTA', 1, '2022-07-01 09:30:29', '2022-07-01 09:30:29'),
(65, '4522126', 'yami', 3, '260.00', 'HERRAMIENTA', 1, '2022-07-01 09:38:12', '2022-07-21 22:57:22'),
(66, '1485236', 'kotori', 1, '69.50', 'FUNGIBLE', 1, '2022-07-01 20:49:10', '2022-07-01 20:49:10'),
(67, '4588856', 'siesta', 1, '150.00', 'FUNGIBLE', 1, '2022-07-01 21:14:02', '2022-07-01 21:14:02'),
(68, '458225', 'kurumi tokisaki', 1, '36.00', 'FUNGIBLE', 1, '2022-07-01 21:41:08', '2022-07-01 21:41:08'),
(69, '522544', 'neptunia', 4, '452.00', 'FUNGIBLE', 1, '2022-07-01 22:36:30', '2022-07-01 22:36:30'),
(70, '4588563', 'mayuri', 5, '156.00', 'FUNGIBLE', 1, '2022-07-02 18:16:04', '2022-07-02 18:16:04'),
(71, '632114', 'rem', 2, '500.00', 'FUNGIBLE', 1, '2022-07-09 23:15:58', '2022-07-09 23:15:58'),
(72, '1255632', 'siesta 2.0', 8, '30.00', 'FUNGIBLE', 1, '2022-07-11 12:12:51', '2022-07-11 12:12:51'),
(73, '3325633', 'arduino mega2560', 3, '300.00', 'HERRAMIENTA', 1, '2022-07-11 12:13:43', '2022-07-11 12:13:43'),
(74, '5225', 'arduino mega 3560', 7, '60.00', 'HERRAMIENTA', 1, '2022-07-11 20:38:40', '2022-07-11 20:38:40'),
(75, '3652522', 'ruka 2.0', 12, '63.00', 'FUNGIBLE', 1, '2022-07-19 07:42:44', '2022-07-19 07:42:44'),
(76, '145226', 'kotori 2.0', 1, '36.00', 'FUNGIBLE', 1, '2022-07-19 08:15:28', '2022-07-19 08:15:28'),
(85, '6933', 'LLAVE 9\"', 51, '26.30', 'HERRAMIENTA', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(86, '5236', 'PERNO 1/2\"', 51, '12.00', 'FUNGIBLE', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(87, '3622', 'VÁLVULA', 51, '500.00', 'COMPONENTE', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(88, '2511', 'BUJIA', 51, '240.00', 'PIEZA', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(89, '4577', 'PINTURA', 53, '36.00', 'FUNGIBLE', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(90, '6352', 'CAL', 52, '52.00', 'FUNGIBLE', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(91, '4588', 'GUANTES', 54, '8.50', 'FUNGIBLE', 1, '2022-07-21 08:36:11', '2022-07-21 08:36:11'),
(92, '25336', 'arduino uno', 2, '10.00', 'FUNGIBLE', 1, '2022-07-21 19:08:04', '2022-07-21 19:08:13'),
(134, '3655', 'lilia', 52, '360.00', 'FUNGIBLE', 1, '2022-07-26 09:06:43', '2022-07-26 09:06:43'),
(135, '23', 'liiaaa', 51, '150.00', 'HERRAMIENTA', 1, '2022-07-26 09:06:43', '2022-07-26 09:06:43'),
(136, '252', 'PERNO 1/2', 53, '25.00', 'PIEZA', 1, '2022-07-26 09:06:43', '2022-07-26 09:06:43'),
(137, '362252', 'kotori 2.1', 6, '25.00', 'FUNGIBLE', 1, '2022-08-12 21:46:23', '2022-08-12 21:46:23'),
(138, '1145225', 'void', 51, '66.00', 'FUNGIBLE', 1, '2022-08-12 21:51:48', '2022-08-12 21:55:09'),
(139, '336224', 'tsukasa', 3, '31.00', 'FUNGIBLE', 1, '2022-08-12 21:55:52', '2022-08-12 21:55:52'),
(140, '362214', 'tsukasita', 6, '150.00', 'FUNGIBLE', 1, '2022-08-13 21:49:53', '2022-08-13 21:49:53'),
(141, '3325', 'yukina', 6, '200.00', 'FUNGIBLE', 1, '2022-08-13 21:50:43', '2022-08-13 21:50:43'),
(142, '25111', 'kurumi', 5, '36.00', 'FUNGIBLE', 1, '2022-08-13 21:55:01', '2022-08-13 21:55:01');

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
-- Estructura Stand-in para la vista `lista_de_materiales_pedidos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `lista_de_materiales_pedidos` (
`order_request_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`id` bigint(20) unsigned
,`sku` varchar(15)
,`item` varchar(255)
,`type` enum('FUNGIBLE','COMPONENTE','PIEZA','HERRAMIENTA')
,`quantity` decimal(8,2)
,`abbreviation` varchar(5)
,`ordered_quantity` decimal(8,2)
,`used_quantity` decimal(8,2)
,`stock` decimal(8,2)
,`state` enum('PENDIENTE','ACEPTADO','MODIFICADO','RECHAZADO','VALIDADO','INCOMPLETO','CONCLUIDO')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `lista_de_materiales_pedidos_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `lista_de_materiales_pedidos_pendientes` (
`order_request_id` bigint(20) unsigned
,`user_id` bigint(20) unsigned
,`id` bigint(20) unsigned
,`sku` varchar(15)
,`item` varchar(255)
,`type` enum('FUNGIBLE','COMPONENTE','PIEZA','HERRAMIENTA')
,`quantity` decimal(8,2)
,`abbreviation` varchar(5)
,`ordered_quantity` decimal(8,2)
,`used_quantity` decimal(8,2)
,`stock` decimal(8,2)
);

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
(1, '461330', 'CHINCHA ALTA', 1, '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '857147', 'CHINCHA BAJA', 1, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '639678', 'LOS CASTILLOS', 2, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '719304', 'SANTA MARGARITA', 2, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
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
(50, 'possimus', 'qsc', '2022-06-20 21:21:46', '2022-06-20 21:21:46'),
(51, 'UNIDAD', 'UN', NULL, NULL),
(52, 'KILOGRAMO', 'KG', NULL, NULL),
(53, 'GALÓN', 'GL', NULL, NULL),
(54, 'PAR', 'PAR', NULL, NULL);

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
-- Estructura de tabla para la tabla `operator_stocks`
--

CREATE TABLE `operator_stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `ordered_quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `used_quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `operator_stocks`
--

INSERT INTO `operator_stocks` (`id`, `user_id`, `item_id`, `ordered_quantity`, `used_quantity`, `created_at`, `updated_at`) VALUES
(260, 1, 52, '4.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:02:06'),
(261, 1, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:02:03'),
(262, 1, 21, '11.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:02:00'),
(263, 1, 9, '9.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:01:57'),
(264, 1, 57, '36.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:01:55'),
(265, 1, 3, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-17 13:23:26'),
(266, 1, 24, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:01:51'),
(267, 1, 1, '4.00', '0.00', '2022-08-15 17:55:38', '2022-08-17 13:28:38'),
(268, 1, 140, '4.00', '4.00', '2022-08-15 17:55:38', '2022-08-15 17:55:38'),
(269, 2, 52, '4.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:37'),
(270, 2, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:32'),
(271, 2, 21, '12.00', '1.00', '2022-08-15 17:55:38', '2022-08-15 18:12:30'),
(272, 2, 9, '9.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:28'),
(273, 2, 57, '36.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:25'),
(274, 2, 24, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:20'),
(275, 2, 1, '4.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:07'),
(276, 2, 3, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:12:18'),
(277, 2, 141, '2.00', '2.00', '2022-08-15 17:55:38', '2022-08-17 13:39:08'),
(278, 3, 52, '4.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:03:16'),
(279, 3, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:05:02'),
(280, 3, 21, '11.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:03:06'),
(281, 3, 9, '9.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:03:02'),
(282, 3, 57, '36.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:05:27'),
(283, 3, 24, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:02:49'),
(284, 3, 3, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:05:34'),
(285, 3, 1, '8.00', '4.00', '2022-08-15 17:55:38', '2022-08-15 19:02:37'),
(286, 4, 52, '5.00', '1.00', '2022-08-15 17:55:38', '2022-08-15 18:11:03'),
(287, 4, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:10:59'),
(288, 4, 21, '11.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:10:53'),
(289, 4, 9, '10.00', '1.00', '2022-08-15 17:55:38', '2022-08-15 18:10:51'),
(290, 4, 57, '36.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:10:48'),
(291, 4, 24, '4.00', '1.00', '2022-08-15 17:55:38', '2022-08-15 18:10:44'),
(292, 4, 3, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 18:10:41'),
(293, 4, 1, '10.00', '6.00', '2022-08-15 17:55:38', '2022-08-15 18:05:18'),
(294, 5, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:50'),
(295, 5, 3, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:57'),
(296, 5, 24, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:55'),
(297, 5, 4, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:52'),
(298, 5, 57, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:45'),
(299, 5, 52, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:06:42'),
(300, 5, 9, '12.00', '6.00', '2022-08-15 17:55:38', '2022-08-15 19:06:40'),
(301, 6, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:38'),
(302, 6, 3, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:35'),
(303, 6, 24, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:33'),
(304, 6, 4, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:28'),
(305, 6, 57, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:26'),
(306, 6, 52, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:07:24'),
(307, 6, 9, '12.00', '6.00', '2022-08-15 17:55:38', '2022-08-15 19:07:22'),
(308, 7, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:07'),
(309, 7, 3, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:13'),
(310, 7, 24, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:16'),
(311, 7, 4, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:17'),
(312, 7, 57, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:19'),
(313, 7, 52, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:25'),
(314, 7, 9, '12.00', '6.00', '2022-08-15 17:55:38', '2022-08-15 19:08:23'),
(315, 8, 142, '2.00', '1.00', '2022-08-15 17:55:38', '2022-08-15 19:08:54'),
(316, 8, 4, '3.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:28:03'),
(317, 8, 24, '6.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:27:58'),
(318, 8, 3, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:27:54'),
(319, 8, 57, '12.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:28:09'),
(320, 8, 44, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:27:47'),
(321, 8, 52, '10.00', '0.00', '2022-08-15 17:55:38', '2022-08-15 19:08:59'),
(322, 8, 9, '12.00', '5.00', '2022-08-15 17:55:38', '2022-08-15 19:28:30');

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
  `month_request` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_dates`
--

INSERT INTO `order_dates` (`id`, `open_request`, `close_request`, `order_date`, `arrival_date`, `state`, `month_request`, `created_at`, `updated_at`) VALUES
(1, '2022-04-25', '2022-04-28', '2022-05-02', '2022-07-01', 'CERRADO', 'MAYO', '2022-06-20 22:22:55', '2022-07-23 19:15:21'),
(2, '2022-06-27', '2022-06-30', '2022-07-04', '2022-09-01', 'CERRADO', 'JULIO', '2022-06-20 22:22:55', '2022-08-13 16:55:44'),
(3, '2022-08-29', '2022-09-01', '2022-09-05', '2022-11-01', 'PENDIENTE', 'SETIEMBRE', '2022-06-20 22:22:55', '2022-07-22 15:44:13'),
(4, '2022-10-31', '2022-11-03', '2022-11-07', '2023-01-01', 'PENDIENTE', 'NOVIEMBRE', '2022-06-20 22:22:56', '2022-07-22 15:44:13');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `order_requests`
--

CREATE TABLE `order_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','CERRADO','VALIDADO','RECHAZADO','EN PROCESO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `order_date_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_requests`
--

INSERT INTO `order_requests` (`id`, `user_id`, `implement_id`, `state`, `validated_by`, `is_canceled`, `order_date_id`, `created_at`, `updated_at`) VALUES
(158, 1, 1, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:06', '2022-08-15 17:55:38'),
(159, 2, 2, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:06', '2022-08-15 17:55:38'),
(160, 3, 3, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:07', '2022-08-15 17:55:38'),
(161, 4, 4, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:07', '2022-08-15 17:55:38'),
(162, 5, 5, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:07', '2022-08-15 17:55:38'),
(163, 6, 6, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:08', '2022-08-15 17:55:38'),
(164, 7, 7, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:08', '2022-08-15 17:55:38'),
(165, 8, 8, 'EN PROCESO', 4, 0, 2, '2022-08-13 16:33:08', '2022-08-15 17:55:38');

--
-- Disparadores `order_requests`
--
DELIMITER $$
CREATE TRIGGER `rechazar_detalle` AFTER UPDATE ON `order_requests` FOR EACH ROW BEGIN
IF new.state = "RECHAZADO" AND new.state <> old.state THEN
    DELETE FROM order_request_details WHERE order_request_id = new.id AND state = "VALIDADO";
	UPDATE order_request_details o SET state = "PENDIENTE" WHERE order_request_id = new.id;
ELSEIF(new.state = "EN PROCESO" AND new.state <> old.state) THEN
	BEGIN
    	DECLARE sede BIGINT(20);
        DECLARE material BIGINT(20);
        DECLARE cantidad DECIMAL(8,2);
        DECLARE precio DECIMAL(8,2);
        DECLARE item_final INT DEFAULT 0;
    /*-----OBTENER SEDE DE LA SOLICITUD-------------*/
        SELECT s.id INTO sede FROM implements i INNER JOIN locations l ON l.id = i.location_id INNER JOIN sedes s ON s.id = l.sede_id WHERE i.id = new.implement_id LIMIT 1;
    /*----CURSOR PARA RECORRER LOS ITEMS DE LA SOLICITUD DE PEDIDO EN PROCESO-----------------------*/
    	BEGIN
            DECLARE cursor_item CURSOR FOR SELECT item_id,quantity,estimated_price FROM order_request_details WHERE order_request_id = new.id AND state = "VALIDADO";
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET item_final = 1;
            OPEN cursor_item;
                bucle:LOOP
                    IF item_final = 1 THEN
                        LEAVE bucle;
                    END IF;
                    FETCH cursor_item INTO material,cantidad,precio;
                    IF NOT EXISTS(SELECT * FROM general_order_requests WHERE item_id = material AND sede_id = sede AND order_date_id = new.order_date_id) THEN
                        INSERT INTO general_order_requests(item_id,quantity,quantity_to_arrive,price,sede_id,order_date_id) VALUES (material, cantidad, cantidad, precio, sede, new.order_date_id);
                    ELSE
                        UPDATE general_order_requests SET quantity = quantity + cantidad, quantity_to_arrive = quantity_to_arrive + cantidad WHERE item_id = material AND sede_id = sede AND order_date_id = new.order_date_id;
                    END IF;
                    IF NOT EXISTS(SELECT * FROM operator_stocks WHERE user_id = new.user_id AND item_id = material) THEN
                 		INSERT INTO operator_stocks(user_id, item_id, ordered_quantity, used_quantity) VALUES (new.user_id,material,cantidad,cantidad);
                    ELSE
                    	UPDATE operator_stocks SET ordered_quantity = ordered_quantity + cantidad, used_quantity = used_quantity + cantidad WHERE user_id = new.user_id AND item_id = material;
                    END IF;
                END LOOP bucle;
            CLOSE cursor_item;
        END;
    END;
END IF;
END
$$
DELIMITER ;

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
  `quantity_to_use` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_details`
--

INSERT INTO `order_request_details` (`id`, `order_request_id`, `item_id`, `quantity`, `estimated_price`, `state`, `quantity_to_use`, `created_at`, `updated_at`) VALUES
(667, 158, 1, '4.00', '200.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:06', '2022-08-13 21:49:33'),
(668, 158, 3, '6.00', '50.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:06', '2022-08-13 21:49:30'),
(669, 158, 24, '3.00', '130.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:06', '2022-08-13 21:49:31'),
(670, 158, 57, '36.00', '15.00', 'ACEPTADO', '36.00', '2022-08-13 16:33:06', '2022-08-13 21:49:28'),
(671, 158, 9, '9.00', '25.00', 'ACEPTADO', '9.00', '2022-08-13 16:33:06', '2022-08-13 21:49:27'),
(672, 158, 21, '11.00', '25.00', 'ACEPTADO', '11.00', '2022-08-13 16:33:06', '2022-08-13 21:49:25'),
(673, 158, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:06', '2022-08-13 21:49:24'),
(674, 158, 52, '4.00', '120.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:06', '2022-08-13 21:49:22'),
(675, 159, 1, '4.00', '200.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:06', '2022-08-13 21:50:28'),
(676, 159, 3, '6.00', '50.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:06', '2022-08-13 21:50:29'),
(677, 159, 24, '3.00', '130.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:06', '2022-08-13 21:50:26'),
(678, 159, 57, '36.00', '15.00', 'ACEPTADO', '36.00', '2022-08-13 16:33:06', '2022-08-13 21:50:25'),
(679, 159, 9, '9.00', '25.00', 'ACEPTADO', '9.00', '2022-08-13 16:33:06', '2022-08-13 21:50:24'),
(680, 159, 21, '12.00', '25.00', 'ACEPTADO', '11.00', '2022-08-13 16:33:06', '2022-08-13 21:50:22'),
(681, 159, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:06', '2022-08-13 21:50:21'),
(682, 159, 52, '4.00', '120.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:06', '2022-08-13 21:50:19'),
(683, 160, 1, '4.00', '200.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:07', '2022-08-13 21:52:37'),
(684, 160, 3, '6.00', '50.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:07', '2022-08-13 21:52:35'),
(685, 160, 24, '3.00', '130.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:07', '2022-08-13 21:52:34'),
(686, 160, 57, '36.00', '15.00', 'ACEPTADO', '36.00', '2022-08-13 16:33:07', '2022-08-13 21:52:33'),
(687, 160, 9, '9.00', '25.00', 'ACEPTADO', '9.00', '2022-08-13 16:33:07', '2022-08-13 21:52:31'),
(688, 160, 21, '11.00', '25.00', 'ACEPTADO', '11.00', '2022-08-13 16:33:07', '2022-08-13 21:52:30'),
(689, 160, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:07', '2022-08-13 21:52:15'),
(690, 160, 52, '4.00', '120.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:07', '2022-08-13 21:52:13'),
(691, 161, 1, '5.00', '200.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:07', '2022-08-13 21:53:34'),
(692, 161, 3, '6.00', '50.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:07', '2022-08-13 21:53:32'),
(693, 161, 24, '4.00', '130.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:07', '2022-08-13 21:53:31'),
(694, 161, 57, '37.00', '15.00', 'MODIFICADO', '36.00', '2022-08-13 16:33:07', '2022-08-13 21:53:41'),
(695, 161, 9, '10.00', '25.00', 'ACEPTADO', '9.00', '2022-08-13 16:33:07', '2022-08-13 21:53:28'),
(696, 161, 21, '11.00', '25.00', 'ACEPTADO', '11.00', '2022-08-13 16:33:07', '2022-08-13 21:53:27'),
(697, 161, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:07', '2022-08-13 21:53:25'),
(698, 161, 52, '5.00', '120.00', 'ACEPTADO', '4.00', '2022-08-13 16:33:07', '2022-08-13 21:53:24'),
(699, 162, 9, '6.00', '25.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:07', '2022-08-13 21:54:06'),
(700, 162, 52, '10.00', '120.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:07', '2022-08-13 21:54:05'),
(701, 162, 57, '12.00', '15.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:07', '2022-08-13 21:54:04'),
(702, 162, 4, '3.00', '45.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:07', '2022-08-13 21:54:02'),
(703, 162, 24, '6.00', '130.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:07', '2022-08-13 21:54:01'),
(704, 162, 3, '12.00', '50.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:53:59'),
(705, 162, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:53:57'),
(706, 163, 9, '6.00', '25.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:08', '2022-08-13 21:54:26'),
(707, 163, 52, '10.00', '120.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:54:24'),
(708, 163, 57, '12.00', '15.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:54:23'),
(709, 163, 4, '3.00', '45.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:08', '2022-08-13 21:54:22'),
(710, 163, 24, '6.00', '130.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:08', '2022-08-13 21:54:20'),
(711, 163, 3, '12.00', '50.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:54:19'),
(712, 163, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:54:17'),
(713, 164, 9, '6.00', '25.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:08', '2022-08-13 21:54:44'),
(714, 164, 52, '10.00', '120.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:54:43'),
(715, 164, 57, '12.00', '15.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:54:42'),
(716, 164, 4, '3.00', '45.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:08', '2022-08-13 21:54:40'),
(717, 164, 24, '6.00', '130.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:08', '2022-08-13 21:54:39'),
(718, 164, 3, '12.00', '50.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:54:38'),
(719, 164, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:54:36'),
(720, 165, 9, '6.00', '25.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:08', '2022-08-13 21:55:29'),
(721, 165, 52, '10.00', '120.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:08', '2022-08-13 21:55:27'),
(722, 165, 57, '12.00', '15.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:08', '2022-08-13 21:55:24'),
(723, 165, 4, '3.00', '45.00', 'ACEPTADO', '3.00', '2022-08-13 16:33:08', '2022-08-13 21:55:18'),
(724, 165, 24, '6.00', '130.00', 'ACEPTADO', '6.00', '2022-08-13 16:33:09', '2022-08-13 21:55:20'),
(725, 165, 3, '12.00', '50.00', 'ACEPTADO', '12.00', '2022-08-13 16:33:09', '2022-08-13 21:55:22'),
(726, 165, 44, '10.00', '45.00', 'ACEPTADO', '10.00', '2022-08-13 16:33:09', '2022-08-13 21:55:26'),
(727, 158, 52, '4.00', '120.00', 'VALIDADO', '4.00', '2022-08-13 21:49:22', '2022-08-13 21:49:22'),
(728, 158, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:49:24', '2022-08-13 21:49:24'),
(729, 158, 21, '11.00', '25.00', 'VALIDADO', '11.00', '2022-08-13 21:49:25', '2022-08-13 21:49:25'),
(730, 158, 9, '9.00', '25.00', 'VALIDADO', '9.00', '2022-08-13 21:49:27', '2022-08-13 21:49:27'),
(731, 158, 57, '36.00', '15.00', 'VALIDADO', '36.00', '2022-08-13 21:49:28', '2022-08-13 21:49:28'),
(732, 158, 3, '6.00', '50.00', 'VALIDADO', '6.00', '2022-08-13 21:49:30', '2022-08-13 21:49:30'),
(733, 158, 24, '3.00', '130.00', 'VALIDADO', '3.00', '2022-08-13 21:49:31', '2022-08-13 21:49:31'),
(734, 158, 1, '4.00', '450.00', 'VALIDADO', '4.00', '2022-08-13 21:49:33', '2022-08-13 21:49:33'),
(735, 158, 140, '2.00', '150.00', 'ACEPTADO', '0.00', '2022-08-13 21:49:53', '2022-08-13 21:49:53'),
(736, 158, 140, '2.00', '150.00', 'VALIDADO', '2.00', '2022-08-13 21:49:53', '2022-08-15 17:11:11'),
(737, 159, 52, '4.00', '120.00', 'VALIDADO', '4.00', '2022-08-13 21:50:19', '2022-08-13 21:50:19'),
(738, 159, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:50:21', '2022-08-13 21:50:21'),
(739, 159, 21, '12.00', '25.00', 'VALIDADO', '12.00', '2022-08-13 21:50:22', '2022-08-13 21:50:22'),
(740, 159, 9, '9.00', '25.00', 'VALIDADO', '9.00', '2022-08-13 21:50:24', '2022-08-13 21:50:24'),
(741, 159, 57, '36.00', '15.00', 'VALIDADO', '36.00', '2022-08-13 21:50:25', '2022-08-13 21:50:25'),
(742, 159, 24, '3.00', '130.00', 'VALIDADO', '3.00', '2022-08-13 21:50:26', '2022-08-13 21:50:26'),
(743, 159, 1, '4.00', '450.00', 'VALIDADO', '4.00', '2022-08-13 21:50:28', '2022-08-13 21:50:28'),
(744, 159, 3, '6.00', '50.00', 'VALIDADO', '6.00', '2022-08-13 21:50:29', '2022-08-13 21:50:29'),
(745, 159, 141, '1.00', '200.00', 'ACEPTADO', '0.00', '2022-08-13 21:50:43', '2022-08-13 21:50:43'),
(746, 159, 141, '1.00', '200.00', 'VALIDADO', '1.00', '2022-08-13 21:50:43', '2022-08-15 17:13:58'),
(747, 160, 52, '4.00', '120.00', 'VALIDADO', '4.00', '2022-08-13 21:52:13', '2022-08-13 21:52:13'),
(748, 160, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:52:15', '2022-08-13 21:52:15'),
(749, 160, 21, '11.00', '25.00', 'VALIDADO', '11.00', '2022-08-13 21:52:30', '2022-08-13 21:52:30'),
(750, 160, 9, '9.00', '25.00', 'VALIDADO', '9.00', '2022-08-13 21:52:31', '2022-08-13 21:52:31'),
(751, 160, 57, '36.00', '15.00', 'VALIDADO', '36.00', '2022-08-13 21:52:33', '2022-08-13 21:52:33'),
(752, 160, 24, '3.00', '130.00', 'VALIDADO', '3.00', '2022-08-13 21:52:34', '2022-08-13 21:52:34'),
(753, 160, 3, '6.00', '50.00', 'VALIDADO', '6.00', '2022-08-13 21:52:35', '2022-08-13 21:52:35'),
(754, 160, 1, '4.00', '450.00', 'VALIDADO', '4.00', '2022-08-13 21:52:37', '2022-08-13 21:52:37'),
(755, 161, 52, '5.00', '120.00', 'VALIDADO', '5.00', '2022-08-13 21:53:23', '2022-08-13 21:53:23'),
(756, 161, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:53:25', '2022-08-13 21:53:25'),
(757, 161, 21, '11.00', '25.00', 'VALIDADO', '11.00', '2022-08-13 21:53:26', '2022-08-13 21:53:26'),
(758, 161, 9, '10.00', '25.00', 'VALIDADO', '10.00', '2022-08-13 21:53:28', '2022-08-13 21:53:28'),
(759, 161, 57, '36.00', '15.00', 'VALIDADO', '36.00', '2022-08-13 21:53:30', '2022-08-15 17:13:58'),
(760, 161, 24, '4.00', '130.00', 'VALIDADO', '4.00', '2022-08-13 21:53:31', '2022-08-13 21:53:31'),
(761, 161, 3, '6.00', '50.00', 'VALIDADO', '6.00', '2022-08-13 21:53:32', '2022-08-13 21:53:32'),
(762, 161, 1, '5.00', '450.00', 'VALIDADO', '5.00', '2022-08-13 21:53:34', '2022-08-13 21:53:34'),
(763, 162, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:53:57', '2022-08-13 21:53:57'),
(764, 162, 3, '12.00', '50.00', 'VALIDADO', '12.00', '2022-08-13 21:53:59', '2022-08-13 21:53:59'),
(765, 162, 24, '6.00', '130.00', 'VALIDADO', '6.00', '2022-08-13 21:54:01', '2022-08-13 21:54:01'),
(766, 162, 4, '3.00', '45.00', 'VALIDADO', '3.00', '2022-08-13 21:54:02', '2022-08-13 21:54:02'),
(767, 162, 57, '12.00', '15.00', 'VALIDADO', '12.00', '2022-08-13 21:54:04', '2022-08-13 21:54:04'),
(768, 162, 52, '10.00', '120.00', 'VALIDADO', '10.00', '2022-08-13 21:54:05', '2022-08-13 21:54:05'),
(769, 162, 9, '6.00', '25.00', 'VALIDADO', '6.00', '2022-08-13 21:54:06', '2022-08-13 21:54:06'),
(770, 163, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:54:17', '2022-08-13 21:54:17'),
(771, 163, 3, '12.00', '50.00', 'VALIDADO', '12.00', '2022-08-13 21:54:19', '2022-08-13 21:54:19'),
(772, 163, 24, '6.00', '130.00', 'VALIDADO', '6.00', '2022-08-13 21:54:20', '2022-08-13 21:54:20'),
(773, 163, 4, '3.00', '45.00', 'VALIDADO', '3.00', '2022-08-13 21:54:22', '2022-08-13 21:54:22'),
(774, 163, 57, '12.00', '15.00', 'VALIDADO', '12.00', '2022-08-13 21:54:23', '2022-08-13 21:54:23'),
(775, 163, 52, '10.00', '120.00', 'VALIDADO', '10.00', '2022-08-13 21:54:24', '2022-08-13 21:54:24'),
(776, 163, 9, '6.00', '25.00', 'VALIDADO', '6.00', '2022-08-13 21:54:26', '2022-08-13 21:54:26'),
(777, 164, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:54:36', '2022-08-13 21:54:36'),
(778, 164, 3, '12.00', '50.00', 'VALIDADO', '12.00', '2022-08-13 21:54:38', '2022-08-13 21:54:38'),
(779, 164, 24, '6.00', '130.00', 'VALIDADO', '6.00', '2022-08-13 21:54:39', '2022-08-13 21:54:39'),
(780, 164, 4, '3.00', '45.00', 'VALIDADO', '3.00', '2022-08-13 21:54:40', '2022-08-13 21:54:40'),
(781, 164, 57, '12.00', '15.00', 'VALIDADO', '12.00', '2022-08-13 21:54:41', '2022-08-13 21:54:41'),
(782, 164, 52, '10.00', '120.00', 'VALIDADO', '10.00', '2022-08-13 21:54:43', '2022-08-13 21:54:43'),
(783, 164, 9, '6.00', '25.00', 'VALIDADO', '6.00', '2022-08-13 21:54:44', '2022-08-13 21:54:44'),
(784, 165, 142, '2.00', '36.00', 'ACEPTADO', '0.00', '2022-08-13 21:55:01', '2022-08-13 21:55:01'),
(785, 165, 142, '2.00', '36.00', 'VALIDADO', '2.00', '2022-08-13 21:55:02', '2022-08-15 17:13:58'),
(786, 165, 4, '3.00', '45.00', 'VALIDADO', '3.00', '2022-08-13 21:55:18', '2022-08-13 21:55:18'),
(787, 165, 24, '6.00', '130.00', 'VALIDADO', '6.00', '2022-08-13 21:55:20', '2022-08-13 21:55:20'),
(788, 165, 3, '12.00', '50.00', 'VALIDADO', '12.00', '2022-08-13 21:55:22', '2022-08-13 21:55:22'),
(789, 165, 57, '12.00', '15.00', 'VALIDADO', '12.00', '2022-08-13 21:55:24', '2022-08-13 21:55:24'),
(790, 165, 44, '10.00', '45.00', 'VALIDADO', '10.00', '2022-08-13 21:55:26', '2022-08-13 21:55:26'),
(791, 165, 52, '10.00', '120.00', 'VALIDADO', '10.00', '2022-08-13 21:55:27', '2022-08-13 21:55:27'),
(792, 165, 9, '6.00', '25.00', 'VALIDADO', '6.00', '2022-08-13 21:55:29', '2022-08-13 21:55:29');

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
  `datasheet` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `image` varchar(2048) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` enum('PENDIENTE','CREADO','RECHAZADO') COLLATE utf8mb4_unicode_ci DEFAULT 'PENDIENTE',
  `item_id` bigint(20) UNSIGNED DEFAULT NULL,
  `observation` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `order_request_new_items`
--

INSERT INTO `order_request_new_items` (`id`, `order_request_id`, `new_item`, `quantity`, `measurement_unit_id`, `datasheet`, `image`, `state`, `item_id`, `observation`, `created_at`, `updated_at`) VALUES
(13, 161, 'SIESTA', '2.00', 51, 'SDA\nSDASDASD', 'public/newMaterials/1iBZN4jLhgObKH3hOgZVi0NXwzDdFMdo3l0N1za9.jpg', 'RECHAZADO', NULL, '', '2022-08-13 21:34:23', '2022-08-13 21:53:13'),
(14, 161, 'IMOUTO', '2.00', 2, 'DASDAS', 'public/newMaterials/4dqi7v0qxv1Hg9v6tUd5VlbwZe8lhT7KFl2KEadv.jpg', 'RECHAZADO', NULL, '', '2022-08-13 21:34:44', '2022-08-13 21:53:07'),
(15, 158, 'TSUKASITA', '2.00', 6, 'SAD\nASDAS', 'public/newMaterials/bYujT1w5hZy5GvHUzfpfPeNPB1fQGZtoKmEqY4Dw.jpg', 'CREADO', 140, '', '2022-08-13 21:39:36', '2022-08-13 21:49:53'),
(16, 159, 'YUKINA', '1.00', 6, 'ASDA', 'public/newMaterials/dHTa3PIzKzLrdP4uFRTu0Bmy4gMfeV28NtfjKHAk.jpg', 'CREADO', 141, '', '2022-08-13 21:40:57', '2022-08-13 21:50:43'),
(17, 165, 'KURUMI', '2.00', 5, 'SADSAD', 'public/newMaterials/0c0Cxd9wnoTeysDReJl0ZY8JDlskNoVW06BoMrQh.jpg', 'CREADO', 142, '', '2022-08-13 21:46:24', '2022-08-13 21:55:02'),
(18, 165, 'MIZUHARA', '2.00', 6, 'ASD', 'public/newMaterials/2RXTO521bXJMV0qIxloka2p3QbZH0MnPogz0lgDW.jpg', 'RECHAZADO', NULL, '', '2022-08-13 21:46:52', '2022-08-13 21:55:06'),
(19, 165, 'REM', '2.00', 9, 'SDAD', 'public/newMaterials/HHUrvAXqkorjQKyibrd0dS2kzhJ3I7DuNthjyeAR.jpg', 'RECHAZADO', NULL, '', '2022-08-13 21:47:11', '2022-08-13 21:55:09');

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
`sku` varchar(15)
,`item_id` bigint(20) unsigned
,`part` varchar(255)
,`component_id` bigint(20) unsigned
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `preventive_maintenance_frequencies`
--

CREATE TABLE `preventive_maintenance_frequencies` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `frequency` decimal(8,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `preventive_maintenance_frequencies`
--

INSERT INTO `preventive_maintenance_frequencies` (`id`, `component_id`, `frequency`) VALUES
(1, 1, '1207.25'),
(2, 2, '64.50'),
(3, 3, '86.00'),
(4, 4, '110.75'),
(5, 5, '461.00'),
(6, 6, '232.25'),
(7, 7, '102.75'),
(8, 8, '691.25'),
(9, 9, '373.75'),
(10, 10, '1045.00'),
(11, 11, '35.50'),
(12, 12, '1135.50'),
(13, 13, '86.50'),
(14, 14, '91.75'),
(15, 15, '74.25'),
(16, 16, '960.25'),
(17, 17, '7.50'),
(18, 18, '124.00'),
(19, 19, '975.75'),
(20, 20, '1159.75'),
(21, 21, '371.25'),
(22, 22, '877.50'),
(23, 23, '77.50'),
(24, 24, '1237.00'),
(25, 25, '113.00'),
(26, 26, '603.50'),
(27, 27, '179.25'),
(28, 28, '335.50'),
(29, 29, '114.00'),
(30, 30, '94.25'),
(31, 31, '4.50'),
(32, 32, '1143.75'),
(33, 33, '58.50'),
(34, 34, '743.50');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpiles`
--

CREATE TABLE `pre_stockpiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('PENDIENTE','CERRADO','VALIDADO','RECHAZADO','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `pre_stockpile_date_id` bigint(20) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `pre_stockpiles`
--

INSERT INTO `pre_stockpiles` (`id`, `user_id`, `implement_id`, `state`, `validated_by`, `pre_stockpile_date_id`, `created_at`, `updated_at`) VALUES
(42, 1, 1, 'VALIDADO', 4, 1, '2022-08-15 17:22:29', '2022-08-17 18:38:23'),
(43, 2, 2, 'VALIDADO', 4, 1, '2022-08-15 17:22:30', '2022-08-17 18:39:15'),
(44, 3, 3, 'VALIDADO', 4, 1, '2022-08-15 17:22:30', '2022-08-17 18:40:30'),
(45, 4, 4, 'VALIDADO', 4, 1, '2022-08-15 17:22:30', '2022-08-17 18:40:57'),
(46, 5, 5, 'VALIDADO', 4, 1, '2022-08-15 17:22:31', '2022-08-17 18:50:09'),
(47, 6, 6, 'VALIDADO', 4, 1, '2022-08-15 17:22:31', '2022-08-17 18:50:34'),
(48, 7, 7, 'VALIDADO', 4, 1, '2022-08-15 17:22:31', '2022-08-17 18:50:56'),
(49, 8, 8, 'VALIDADO', 4, 1, '2022-08-15 17:22:32', '2022-08-17 18:51:30');

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
(1, '2022-07-09', '2022-07-10', '2022-07-01', 'CERRADO', '2022-07-09 18:04:44', '2022-08-17 14:01:25'),
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
  `state` enum('PENDIENTE','RESERVADO','ACEPTADO','MODIFICADO','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `quantity_to_use` decimal(8,2) NOT NULL DEFAULT 0.00,
  `validated_quantity` decimal(8,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `pre_stockpile_details`
--

INSERT INTO `pre_stockpile_details` (`id`, `pre_stockpile_id`, `item_id`, `quantity`, `state`, `quantity_to_use`, `validated_quantity`, `created_at`, `updated_at`) VALUES
(249, 42, 1, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:29', '2022-08-17 18:35:34'),
(250, 42, 3, '6.00', 'VALIDADO', '5.00', '5.00', '2022-08-15 17:22:29', '2022-08-17 18:34:58'),
(251, 42, 24, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:29', '2022-08-17 18:34:13'),
(252, 42, 57, '36.00', 'VALIDADO', '36.00', '36.00', '2022-08-15 17:22:29', '2022-08-17 18:35:40'),
(253, 42, 9, '9.00', 'VALIDADO', '8.00', '8.00', '2022-08-15 17:22:29', '2022-08-17 18:34:52'),
(254, 42, 21, '11.00', 'VALIDADO', '11.00', '11.00', '2022-08-15 17:22:29', '2022-08-17 18:34:18'),
(255, 42, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:29', '2022-08-17 18:34:06'),
(256, 42, 52, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:29', '2022-08-17 18:29:34'),
(257, 43, 1, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:30', '2022-08-17 18:38:48'),
(258, 43, 3, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:30', '2022-08-17 18:38:51'),
(259, 43, 24, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:30', '2022-08-17 18:38:54'),
(260, 43, 57, '36.00', 'VALIDADO', '36.00', '36.00', '2022-08-15 17:22:30', '2022-08-17 18:38:56'),
(261, 43, 9, '9.00', 'VALIDADO', '9.00', '9.00', '2022-08-15 17:22:30', '2022-08-17 18:38:59'),
(262, 43, 21, '11.00', 'VALIDADO', '11.00', '11.00', '2022-08-15 17:22:30', '2022-08-17 18:39:01'),
(263, 43, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:30', '2022-08-17 18:39:03'),
(264, 43, 52, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:30', '2022-08-17 18:39:11'),
(265, 44, 1, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:30', '2022-08-17 18:40:08'),
(266, 44, 3, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:30', '2022-08-17 18:40:11'),
(267, 44, 24, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:30', '2022-08-17 18:40:13'),
(268, 44, 57, '36.00', 'VALIDADO', '36.00', '36.00', '2022-08-15 17:22:30', '2022-08-17 18:40:16'),
(269, 44, 9, '9.00', 'VALIDADO', '9.00', '9.00', '2022-08-15 17:22:30', '2022-08-17 18:40:19'),
(270, 44, 21, '11.00', 'VALIDADO', '11.00', '11.00', '2022-08-15 17:22:30', '2022-08-17 18:40:27'),
(271, 44, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:30', '2022-08-17 18:40:22'),
(272, 44, 52, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:30', '2022-08-17 18:40:24'),
(273, 45, 1, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:30', '2022-08-17 18:40:36'),
(274, 45, 3, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:30', '2022-08-17 18:40:38'),
(275, 45, 24, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:30', '2022-08-17 18:40:40'),
(276, 45, 57, '36.00', 'VALIDADO', '36.00', '36.00', '2022-08-15 17:22:30', '2022-08-17 18:40:43'),
(277, 45, 9, '9.00', 'VALIDADO', '9.00', '9.00', '2022-08-15 17:22:31', '2022-08-17 18:40:45'),
(278, 45, 21, '11.00', 'VALIDADO', '11.00', '11.00', '2022-08-15 17:22:31', '2022-08-17 18:40:48'),
(279, 45, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:40:50'),
(280, 45, 52, '4.00', 'VALIDADO', '4.00', '4.00', '2022-08-15 17:22:31', '2022-08-17 18:40:52'),
(281, 46, 9, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:31', '2022-08-17 18:41:07'),
(282, 46, 52, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:41:09'),
(283, 46, 57, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:31', '2022-08-17 18:41:14'),
(284, 46, 4, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:31', '2022-08-17 18:50:06'),
(285, 46, 24, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:31', '2022-08-17 18:41:40'),
(286, 46, 3, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:31', '2022-08-17 18:41:45'),
(287, 46, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:41:43'),
(288, 47, 9, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:31', '2022-08-17 18:50:15'),
(289, 47, 52, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:50:17'),
(290, 47, 57, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:31', '2022-08-17 18:50:20'),
(291, 47, 4, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:31', '2022-08-17 18:50:22'),
(292, 47, 24, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:31', '2022-08-17 18:50:24'),
(293, 47, 3, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:31', '2022-08-17 18:50:28'),
(294, 47, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:50:31'),
(295, 48, 9, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:31', '2022-08-17 18:50:42'),
(296, 48, 52, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:31', '2022-08-17 18:50:53'),
(297, 48, 57, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:31', '2022-08-17 18:50:44'),
(298, 48, 4, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:31', '2022-08-17 18:50:46'),
(299, 48, 24, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:32', '2022-08-17 18:50:48'),
(300, 48, 3, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:32', '2022-08-17 18:50:52'),
(301, 48, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:32', '2022-08-17 18:50:50'),
(302, 49, 9, '7.00', 'VALIDADO', '5.00', '5.00', '2022-08-15 17:22:32', '2022-08-17 18:51:07'),
(303, 49, 52, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:32', '2022-08-17 18:51:13'),
(304, 49, 57, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:32', '2022-08-17 18:51:15'),
(305, 49, 4, '3.00', 'VALIDADO', '3.00', '3.00', '2022-08-15 17:22:32', '2022-08-17 18:51:10'),
(306, 49, 24, '6.00', 'VALIDADO', '6.00', '6.00', '2022-08-15 17:22:32', '2022-08-17 18:51:17'),
(307, 49, 3, '12.00', 'VALIDADO', '12.00', '12.00', '2022-08-15 17:22:32', '2022-08-17 18:51:19'),
(308, 49, 44, '10.00', 'VALIDADO', '10.00', '10.00', '2022-08-15 17:22:32', '2022-08-17 18:51:21'),
(309, 43, 141, '1.00', 'RECHAZADO', '1.00', NULL, '2022-08-15 23:12:52', '2022-08-17 18:39:08'),
(310, 49, 142, '1.00', 'VALIDADO', '1.00', '1.00', '2022-08-16 00:08:54', '2022-08-17 18:51:25');

--
-- Disparadores `pre_stockpile_details`
--
DELIMITER $$
CREATE TRIGGER `regresar_cantidad_reservada` AFTER UPDATE ON `pre_stockpile_details` FOR EACH ROW BEGIN
	IF new.state = "RECHAZADO" AND new.state <> old.state THEN
    BEGIN
    	DECLARE usuario INT;
    	SELECT user_id INTO usuario FROM pre_stockpiles WHERE id = old.pre_stockpile_id;
        UPDATE operator_stocks op SET used_quantity = used_quantity + old.quantity WHERE user_id = usuario AND item_id = new.item_id;
    	DELETE FROM pre_stockpile_price_details WHERE pre_stockpile_detail_id = new.id; 
    END;
    ELSEIF new.state = "RESERVADO" OR new.state = "VALIDADO" THEN
            BEGIN
                DECLARE cantidad decimal(8,2) DEFAULT 0;
                DECLARE stock decimal(8,2) DEFAULT 0;
                DECLARE id_stock_detalle INT;
                DECLARE sede INT;
                DECLARE usuario INT;
                IF new.state = "VALIDADO" THEN
                	SET cantidad = new.validated_quantity;
                ELSE
                	SET cantidad = new.quantity;
                END IF;
                
                SELECT user_id INTO usuario FROM pre_stockpiles WHERE id = new.pre_stockpile_id;
                IF old.state = "PENDIENTE" OR old.state = "RECHAZADO" THEN
                    UPDATE operator_stocks op SET used_quantity = used_quantity - new.quantity WHERE user_id = usuario AND item_id = new.item_id;
                ELSE
                    UPDATE operator_stocks op SET used_quantity = used_quantity - new.quantity + old.quantity WHERE user_id = usuario AND item_id = new.item_id;
                END IF;
                IF EXISTS (SELECT * FROM pre_stockpile_price_details WHERE pre_stockpile_detail_id = new.id) THEN
                    DELETE FROM pre_stockpile_price_details WHERE pre_stockpile_detail_id = new.id; 
                END IF;
                SELECT l.sede_id INTO sede FROM pre_stockpiles p INNER JOIN implements i ON i.id = p.implement_id INNER JOIN locations l ON l.id = i.location_id WHERE p.id = new.pre_stockpile_id;
                WHILE cantidad > 0 DO
                    SELECT gsd.id,gsd.quantity_to_reserve INTO id_stock_detalle,stock FROM general_stock_details gsd WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    IF stock >= cantidad THEN
                        UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = gsd.quantity_to_reserve - cantidad WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO pre_stockpile_price_details(pre_stockpile_detail_id, general_stock_detail_id, quantity, quantity_to_use) VALUES (new.id, id_stock_detalle, cantidad, cantidad);
                    SET cantidad = 0;
                ELSE
                    UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = 0 WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO pre_stockpile_price_details(pre_stockpile_detail_id, general_stock_detail_id, quantity, quantity_to_use) VALUES (new.id, id_stock_detalle, stock, stock);
                    SET cantidad = cantidad - stock;
                END IF;
            END WHILE;
        END;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `reservar_material` AFTER INSERT ON `pre_stockpile_details` FOR EACH ROW IF new.state = "RESERVADO" THEN
    	BEGIN
    DECLARE cantidad decimal(8,2) DEFAULT 0;
    DECLARE stock decimal(8,2) DEFAULT 0;
    DECLARE id_stock_detalle INT;
    DECLARE sede INT;
    DECLARE usuario INT;
    SET cantidad = new.quantity;
    SELECT user_id INTO usuario FROM pre_stockpiles WHERE id = new.pre_stockpile_id;
    UPDATE operator_stocks op SET used_quantity = used_quantity - new.quantity WHERE user_id = usuario AND item_id = new.item_id;
    IF EXISTS (SELECT * FROM pre_stockpile_price_details WHERE pre_stockpile_detail_id = new.id) THEN
    	DELETE FROM pre_stockpile_price_details WHERE pre_stockpile_detail_id = new.id; 
    END IF;
    SELECT l.sede_id INTO sede FROM pre_stockpiles p INNER JOIN implements i ON i.id = p.implement_id INNER JOIN locations l ON l.id = i.location_id WHERE p.id = new.pre_stockpile_id;
    WHILE cantidad > 0 DO
    	SELECT gsd.id,gsd.quantity_to_reserve INTO id_stock_detalle,stock FROM general_stock_details gsd WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
    	IF stock >= cantidad THEN
        	UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = gsd.quantity_to_reserve - cantidad WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
            INSERT INTO pre_stockpile_price_details(pre_stockpile_detail_id, general_stock_detail_id, quantity,quantity_to_use) VALUES (new.id, id_stock_detalle, cantidad, cantidad);
            SET cantidad = 0;
        ELSE
        	UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = 0 WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
            INSERT INTO pre_stockpile_price_details(pre_stockpile_detail_id, general_stock_detail_id, quantity,quantity_to_use) VALUES (new.id,id_stock_detalle,stock,stock);
            SET cantidad = cantidad - stock;
        END IF;
    END WHILE;
END;
    END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pre_stockpile_price_details`
--

CREATE TABLE `pre_stockpile_price_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `pre_stockpile_detail_id` bigint(20) UNSIGNED NOT NULL,
  `general_stock_detail_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `quantity_to_use` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Volcado de datos para la tabla `pre_stockpile_price_details`
--

INSERT INTO `pre_stockpile_price_details` (`id`, `pre_stockpile_detail_id`, `general_stock_detail_id`, `quantity`, `quantity_to_use`, `created_at`, `updated_at`) VALUES
(264, 256, 360, '4.00', '4.00', '2022-08-17 13:29:34', '2022-08-17 18:55:49'),
(269, 255, 361, '10.00', '10.00', '2022-08-17 13:34:06', '2022-08-17 18:55:49'),
(270, 251, 366, '3.00', '3.00', '2022-08-17 13:34:13', '2022-08-17 18:55:49'),
(272, 254, 362, '11.00', '11.00', '2022-08-17 13:34:18', '2022-08-17 18:55:49'),
(276, 253, 363, '8.00', '8.00', '2022-08-17 13:34:52', '2022-08-17 18:55:49'),
(277, 250, 365, '5.00', '5.00', '2022-08-17 13:34:58', '2022-08-17 18:55:49'),
(282, 249, 367, '4.00', '4.00', '2022-08-17 13:35:34', '2022-08-17 18:55:49'),
(283, 252, 364, '36.00', '36.00', '2022-08-17 13:35:40', '2022-08-17 18:55:49'),
(284, 257, 367, '4.00', '4.00', '2022-08-17 13:38:48', '2022-08-17 18:55:49'),
(285, 258, 365, '6.00', '6.00', '2022-08-17 13:38:51', '2022-08-17 18:55:49'),
(286, 259, 366, '3.00', '3.00', '2022-08-17 13:38:54', '2022-08-17 18:55:49'),
(287, 260, 364, '36.00', '36.00', '2022-08-17 13:38:56', '2022-08-17 18:55:49'),
(288, 261, 363, '9.00', '9.00', '2022-08-17 13:38:59', '2022-08-17 18:55:49'),
(289, 262, 362, '11.00', '11.00', '2022-08-17 13:39:01', '2022-08-17 18:55:49'),
(290, 263, 361, '10.00', '10.00', '2022-08-17 13:39:03', '2022-08-17 18:55:49'),
(291, 264, 360, '4.00', '4.00', '2022-08-17 13:39:11', '2022-08-17 18:55:49'),
(292, 265, 367, '4.00', '4.00', '2022-08-17 13:40:08', '2022-08-17 18:55:49'),
(293, 266, 365, '6.00', '6.00', '2022-08-17 13:40:11', '2022-08-17 18:55:49'),
(294, 267, 366, '3.00', '3.00', '2022-08-17 13:40:13', '2022-08-17 18:55:49'),
(295, 268, 364, '35.00', '35.00', '2022-08-17 13:40:16', '2022-08-17 18:55:49'),
(296, 268, 390, '1.00', '1.00', '2022-08-17 13:40:16', '2022-08-17 18:55:49'),
(297, 269, 363, '9.00', '9.00', '2022-08-17 13:40:19', '2022-08-17 18:55:49'),
(298, 271, 361, '9.00', '9.00', '2022-08-17 13:40:22', '2022-08-17 18:55:49'),
(299, 271, 387, '1.00', '1.00', '2022-08-17 13:40:22', '2022-08-17 18:55:49'),
(300, 272, 360, '4.00', '4.00', '2022-08-17 13:40:24', '2022-08-17 18:55:49'),
(301, 270, 362, '11.00', '11.00', '2022-08-17 13:40:27', '2022-08-17 18:55:49'),
(302, 273, 367, '4.00', '4.00', '2022-08-17 13:40:36', '2022-08-17 18:55:49'),
(303, 274, 365, '6.00', '6.00', '2022-08-17 13:40:38', '2022-08-17 18:55:49'),
(304, 275, 366, '3.00', '3.00', '2022-08-17 13:40:40', '2022-08-17 18:55:49'),
(305, 276, 364, '36.00', '36.00', '2022-08-17 13:40:43', '2022-08-17 18:55:49'),
(306, 277, 363, '9.00', '9.00', '2022-08-17 13:40:45', '2022-08-17 18:55:49'),
(307, 278, 362, '11.00', '11.00', '2022-08-17 13:40:48', '2022-08-17 18:55:49'),
(308, 279, 361, '10.00', '10.00', '2022-08-17 13:40:50', '2022-08-17 18:55:49'),
(309, 280, 360, '4.00', '4.00', '2022-08-17 13:40:52', '2022-08-17 18:55:49'),
(310, 281, 376, '6.00', '6.00', '2022-08-17 13:41:07', '2022-08-17 18:55:49'),
(311, 282, 375, '10.00', '10.00', '2022-08-17 13:41:09', '2022-08-17 18:55:49'),
(312, 283, 374, '12.00', '12.00', '2022-08-17 13:41:14', '2022-08-17 18:55:49'),
(313, 285, 372, '6.00', '6.00', '2022-08-17 13:41:40', '2022-08-17 18:55:49'),
(314, 287, 370, '10.00', '10.00', '2022-08-17 13:41:43', '2022-08-17 18:55:49'),
(315, 286, 371, '12.00', '12.00', '2022-08-17 13:41:45', '2022-08-17 18:55:49'),
(316, 284, 373, '3.00', '3.00', '2022-08-17 13:50:06', '2022-08-17 18:55:49'),
(317, 288, 376, '6.00', '6.00', '2022-08-17 13:50:15', '2022-08-17 18:55:49'),
(318, 289, 375, '10.00', '10.00', '2022-08-17 13:50:17', '2022-08-17 18:55:49'),
(319, 290, 374, '12.00', '12.00', '2022-08-17 13:50:20', '2022-08-17 18:55:49'),
(320, 291, 373, '3.00', '3.00', '2022-08-17 13:50:22', '2022-08-17 18:55:49'),
(321, 292, 372, '6.00', '6.00', '2022-08-17 13:50:24', '2022-08-17 18:55:49'),
(322, 293, 371, '12.00', '12.00', '2022-08-17 13:50:28', '2022-08-17 18:55:49'),
(323, 294, 370, '10.00', '10.00', '2022-08-17 13:50:31', '2022-08-17 18:55:49'),
(324, 295, 376, '6.00', '6.00', '2022-08-17 13:50:42', '2022-08-17 18:55:49'),
(325, 297, 374, '12.00', '12.00', '2022-08-17 13:50:44', '2022-08-17 18:55:49'),
(326, 298, 373, '3.00', '3.00', '2022-08-17 13:50:46', '2022-08-17 18:55:49'),
(327, 299, 372, '6.00', '6.00', '2022-08-17 13:50:48', '2022-08-17 18:55:49'),
(328, 301, 370, '10.00', '10.00', '2022-08-17 13:50:50', '2022-08-17 18:55:49'),
(329, 300, 371, '12.00', '12.00', '2022-08-17 13:50:52', '2022-08-17 18:55:49'),
(330, 296, 375, '10.00', '10.00', '2022-08-17 13:50:53', '2022-08-17 18:55:49'),
(332, 302, 376, '5.00', '5.00', '2022-08-17 13:51:07', '2022-08-17 18:55:49'),
(333, 305, 373, '2.00', '2.00', '2022-08-17 13:51:10', '2022-08-17 18:55:49'),
(334, 305, 381, '1.00', '1.00', '2022-08-17 13:51:10', '2022-08-17 18:55:49'),
(335, 303, 375, '9.00', '9.00', '2022-08-17 13:51:13', '2022-08-17 18:55:49'),
(336, 303, 383, '1.00', '1.00', '2022-08-17 13:51:13', '2022-08-17 18:55:49'),
(337, 304, 374, '11.00', '11.00', '2022-08-17 13:51:15', '2022-08-17 18:55:49'),
(338, 304, 382, '1.00', '1.00', '2022-08-17 13:51:15', '2022-08-17 18:55:49'),
(339, 306, 372, '5.00', '5.00', '2022-08-17 13:51:17', '2022-08-17 18:55:49'),
(340, 306, 380, '1.00', '1.00', '2022-08-17 13:51:17', '2022-08-17 18:55:49'),
(341, 307, 371, '11.00', '11.00', '2022-08-17 13:51:19', '2022-08-17 18:55:49'),
(342, 307, 379, '1.00', '1.00', '2022-08-17 13:51:19', '2022-08-17 18:55:49'),
(343, 308, 370, '9.00', '9.00', '2022-08-17 13:51:21', '2022-08-17 18:55:49'),
(344, 308, 378, '1.00', '1.00', '2022-08-17 13:51:21', '2022-08-17 18:55:49'),
(345, 310, 377, '1.00', '1.00', '2022-08-17 13:51:25', '2022-08-17 18:55:49');

--
-- Disparadores `pre_stockpile_price_details`
--
DELIMITER $$
CREATE TRIGGER `corregir_cantidades` AFTER DELETE ON `pre_stockpile_price_details` FOR EACH ROW BEGIN
	UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = gsd.quantity_to_reserve + old.quantity WHERE gsd.id = old.general_stock_detail_id ORDER BY id ASC LIMIT 1;
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
-- Estructura de tabla para la tabla `routine_tasks`
--

CREATE TABLE `routine_tasks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tractor_scheduling_id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `state` enum('PENDIENTE','CONCLUIDO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `routine_tasks`
--

INSERT INTO `routine_tasks` (`id`, `tractor_scheduling_id`, `implement_id`, `user_id`, `date`, `state`, `validated_by`, `created_at`, `updated_at`) VALUES
(38, 25, 5, 5, '2022-08-18', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(39, 26, 6, 37, '2022-08-18', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(40, 27, 7, 7, '2022-08-18', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(41, 28, 8, 36, '2022-08-18', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(42, 29, 5, 5, '2022-08-19', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(43, 30, 6, 37, '2022-08-19', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(44, 31, 8, 8, '2022-08-19', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(45, 32, 7, 36, '2022-08-19', 'PENDIENTE', NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32');

--
-- Disparadores `routine_tasks`
--
DELIMITER $$
CREATE TRIGGER `detallar_tareas_rutinarias` AFTER INSERT ON `routine_tasks` FOR EACH ROW BEGIN
	DECLARE modelo_implemento INT;
    SELECT i.implement_model_id INTO modelo_implemento FROM implements i WHERE i.id = new.implement_id;
    BEGIN
    DECLARE tarea_final INT;
    DECLARE tarea INT;
    DECLARE componente INT;
    DECLARE cursor_tareas CURSOR FOR SELECT t.id,c.id FROM tasks t INNER JOIN components c ON c.id = t.component_id INNER JOIN component_implement_model cim ON cim.component_id = c.id WHERE cim.implement_model_id = modelo_implemento AND t.type = "RUTINARIO";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
    OPEN cursor_tareas;
    	bucle_tareas:LOOP
        	IF tarea_final = 1 THEN
            	LEAVE bucle_tareas;
            END IF;
            FETCH cursor_tareas INTO tarea,componente;
            IF NOT EXISTS(SELECT * FROM routine_task_details WHERE routine_task_id = new.id AND task_id = tarea) THEN
        	INSERT INTO routine_task_details (routine_task_id, task_id) VALUES (new.id, tarea);
            END IF;
            BEGIN
                DECLARE tarea_pieza_final INT DEFAULT 0;
            	DECLARE cursor_tareas_pieza CURSOR FOR SELECT t.id FROM tasks t INNER JOIN components p ON p.id = t.component_id INNER JOIN component_part_model cpm ON cpm.part = p.id INNER JOIN components c ON c.id = cpm.component WHERE c.id = componente AND t.type = "RUTINARIO";
                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_pieza_final = 1;
                OPEN cursor_tareas_pieza;
                    bucle_pieza:LOOP
                        IF tarea_pieza_final = 1 THEN
            	            LEAVE bucle_pieza;
                        END IF;
                        FETCH cursor_tareas_pieza INTO tarea;
                        IF NOT EXISTS(SELECT * FROM routine_task_details WHERE routine_task_id = new.id AND task_id = tarea) THEN
                            INSERT INTO routine_task_details (routine_task_id, task_id) VALUES (new.id, tarea);
                        END IF;
                    END LOOP bucle_pieza;
                CLOSE cursor_tareas_pieza;
            END;
        END LOOP bucle_tareas;
    CLOSE cursor_tareas;
    END;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `routine_task_details`
--

CREATE TABLE `routine_task_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `routine_task_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `is_checked` tinyint(1) NOT NULL DEFAULT 0,
  `observations` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `routine_task_details`
--

INSERT INTO `routine_task_details` (`id`, `routine_task_id`, `task_id`, `is_checked`, `observations`, `created_at`, `updated_at`) VALUES
(240, 38, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(241, 38, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(242, 38, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(243, 38, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(244, 38, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(245, 38, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(246, 38, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(247, 38, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(248, 38, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(249, 38, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(250, 38, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(251, 38, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(252, 39, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(253, 39, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(254, 39, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(255, 39, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(256, 39, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(257, 39, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(258, 39, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(259, 39, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(260, 39, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(261, 39, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(262, 39, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(263, 39, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(264, 40, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(265, 40, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(266, 40, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(267, 40, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(268, 40, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(269, 40, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(270, 40, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(271, 40, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(272, 40, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(273, 40, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(274, 40, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(275, 40, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(276, 41, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(277, 41, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(278, 41, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(279, 41, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(280, 41, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(281, 41, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(282, 41, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(283, 41, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(284, 41, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(285, 41, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(286, 41, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(287, 41, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(288, 42, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(289, 42, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(290, 42, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(291, 42, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(292, 42, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(293, 42, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(294, 42, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(295, 42, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(296, 42, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(297, 42, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(298, 42, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(299, 42, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(300, 43, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(301, 43, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(302, 43, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(303, 43, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(304, 43, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(305, 43, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(306, 43, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(307, 43, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(308, 43, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(309, 43, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(310, 43, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(311, 43, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(312, 44, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(313, 44, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(314, 44, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(315, 44, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(316, 44, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(317, 44, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(318, 44, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(319, 44, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(320, 44, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(321, 44, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(322, 44, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(323, 44, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(324, 45, 90, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(325, 45, 84, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(326, 45, 32, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(327, 45, 96, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(328, 45, 27, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(329, 45, 8, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(330, 45, 88, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(331, 45, 14, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(332, 45, 4, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(333, 45, 35, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(334, 45, 18, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32'),
(335, 45, 39, 0, NULL, '2022-08-19 17:29:32', '2022-08-19 17:29:32');

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
(1, '4102', 'CHINCHA', 1, '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '4101', 'ICA', 1, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(3, '389512', 'TRUJILLO', 2, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
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
('cZebbPioHWhpDxs37TPbNUxoR0tsWfIFCuln6VZz', 4, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiNTJiUlNYWDNybHUyM1Jyekh3UklCdFk4eDNQUjhsWFQzZlU1Tm1KbCI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NTQ6Imh0dHA6Ly9zaXN0ZW1hLnRlc3Qvb3BlcmF0b3IvTWFudGVuaW1pZW50b3MtUGVuZGllbnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjQ7fQ==', 1661297576),
('CzgIc6UU390qP4XwlA1Dpxwflp9ymkEVc0YkJYaq', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWHJmYk1NcnpST0pRNlQxbjBYekdETzI4RWpVZWVMOXJWd3NMRVpzcSI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo1NDoiaHR0cDovL3Npc3RlbWEudGVzdC9vcGVyYXRvci9NYW50ZW5pbWllbnRvcy1QZW5kaWVudGVzIjt9czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6MjU6Imh0dHA6Ly9zaXN0ZW1hLnRlc3QvbG9naW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1661311896),
('O0DZv4j27XGjslOgMXyzZ4GKWZDWLoOUcUdaSkS9', 4, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiVUZUYnNSWENZcnFQaFJadjExQXlxVGhJclcyWFdlU25KcUJzRVo0ZiI7czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NTQ6Imh0dHA6Ly9zaXN0ZW1hLnRlc3Qvb3BlcmF0b3IvTWFudGVuaW1pZW50b3MtUGVuZGllbnRlcyI7fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjQ7fQ==', 1661134693),
('tqu9QNIF51DuITm6FEluaMJmcMnVn8sfkcLkcMgS', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.102 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoia3BmcEFaM1FqSjIzT2tuOExhSU1na1lKOEgxd2VpVkx5VGlaR2o3VyI7czozOiJ1cmwiO2E6MTp7czo4OiJpbnRlbmRlZCI7czo1NDoiaHR0cDovL3Npc3RlbWEudGVzdC9vcGVyYXRvci9NYW50ZW5pbWllbnRvcy1QZW5kaWVudGVzIjt9czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NTQ6Imh0dHA6Ly9zaXN0ZW1hLnRlc3Qvb3BlcmF0b3IvTWFudGVuaW1pZW50b3MtUGVuZGllbnRlcyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1661311895);

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
  `validated_by` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
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
  `state` enum('PENDIENTE','RESERVADO','VALIDADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_to_use` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `stockpile_details`
--
DELIMITER $$
CREATE TRIGGER `regresar_cantidad_reservada_stockpile` AFTER UPDATE ON `stockpile_details` FOR EACH ROW BEGIN
	IF new.state = "RECHAZADO" AND new.state <> old.state THEN
    	DELETE FROM stockpile_price_details WHERE stockpile_detail_id = new.id; 
    ELSEIF new.state = "RESERVADO" THEN
    	BEGIN
            DECLARE cantidad decimal(8,2) DEFAULT 0;
            DECLARE stock decimal(8,2) DEFAULT 0;
            DECLARE id_stock_detalle INT;
            DECLARE sede INT;
            DECLARE usuario INT;
            SET cantidad = new.quantity;
            SELECT user_id INTO usuario FROM stockpiles WHERE id = stockpile_id;
    UPDATE operator_stocks SET ordered_quantity = ordered_quantity - new.quantity, used_quantity = used_quantity - new.quantity WHERE user_id = usuario AND item_id = new.item_id;
            IF EXISTS (SELECT * FROM stockpile_price_details WHERE stockpile_detail_id = new.id) THEN
                DELETE FROM stockpile_price_details WHERE stockpile_detail_id = new.id; 
            END IF;
            SELECT l.sede_id INTO sede FROM stockpiles p INNER JOIN implements i ON i.id = p.implement_id INNER JOIN locations l ON l.id = i.location_id WHERE p.id = new.stockpile_id;
            WHILE cantidad > 0 DO
                SELECT gsd.id,gsd.quantity_to_reserve INTO id_stock_detalle,stock FROM general_stock_details gsd WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                IF stock >= cantidad THEN
                    UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = gsd.quantity_to_reserve - cantidad WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO stockpile_price_details(stockpile_detail_id, general_stock_detail_id, quantity) VALUES (new.id, id_stock_detalle, cantidad);
                    SET cantidad = 0;
                ELSE
                    UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = 0 WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO stockpile_price_details(stockpile_detail_id, general_stock_detail_id, quantity) VALUES (new.id,id_stock_detalle,stock);
                    SET cantidad = cantidad - stock;
                END IF;
            END WHILE;
        END;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `sdas` AFTER INSERT ON `stockpile_details` FOR EACH ROW IF new.state = "RESERVADO" THEN
    	BEGIN
            DECLARE cantidad decimal(8,2) DEFAULT 0;
            DECLARE stock decimal(8,2) DEFAULT 0;
            DECLARE id_stock_detalle INT;
            DECLARE sede INT;
            DECLARE usuario INT;
            SET cantidad = new.quantity;
            SELECT user_id INTO usuario FROM stockpiles WHERE id = stockpile_id;
    UPDATE operator_stocks SET ordered_quantity = ordered_quantity - new.quantity, used_quantity = used_quantity - new.quantity WHERE user_id = usuario AND item_id = new.item_id;
            IF EXISTS (SELECT * FROM stockpile_price_details WHERE stockpile_detail_id = new.id) THEN
                DELETE FROM stockpile_price_details WHERE stockpile_detail_id = new.id; 
            END IF;
            SELECT l.sede_id INTO sede FROM stockpiles p INNER JOIN implements i ON i.id = p.implement_id INNER JOIN locations l ON l.id = i.location_id WHERE p.id = new.stockpile_id;
            WHILE cantidad > 0 DO
                SELECT gsd.id,gsd.quantity_to_reserve INTO id_stock_detalle,stock FROM general_stock_details gsd WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                IF stock >= cantidad THEN
                    UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = gsd.quantity_to_reserve - cantidad WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO stockpile_price_details(stockpile_detail_id, general_stock_detail_id, quantity) VALUES (new.id, id_stock_detalle, cantidad);
                    SET cantidad = 0;
                ELSE
                    UPDATE general_stock_details gsd SET gsd.quantity_to_reserve = 0 WHERE gsd.item_id = new.item_id AND gsd.sede_id = sede AND gsd.quantity_to_reserve > 0 AND gsd.is_canceled = 0 ORDER BY id ASC LIMIT 1;
                    INSERT INTO stockpile_price_details(stockpile_detail_id, general_stock_detail_id, quantity) VALUES (new.id,id_stock_detalle,stock);
                    SET cantidad = cantidad - stock;
                END IF;
            END WHILE;
        END;
    END IF
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stockpile_price_details`
--

CREATE TABLE `stockpile_price_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `stockpile_id` bigint(20) UNSIGNED NOT NULL,
  `general_stock_detail_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `stockpile_price_details`
--
DELIMITER $$
CREATE TRIGGER `corregir_cantidad_stockpile` AFTER DELETE ON `stockpile_price_details` FOR EACH ROW BEGIN
	UPDATE general_stock_details gsd SET gsd.quantity_to_use = gsd.quantity_to_use + old.quantity WHERE gsd.id = old.general_stock_detail_id ORDER BY id ASC LIMIT 1;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stocks`
--

CREATE TABLE `stocks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stock_details`
--

CREATE TABLE `stock_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `movement` enum('INGRESO','SALIDA') NOT NULL DEFAULT 'SALIDA',
  `quantity` decimal(8,2) NOT NULL DEFAULT 0.00,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `warehouse_id` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `order_request_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `validated_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
(6, 'ELÉCTRICO', '2022-07-15 16:26:21', '2022-07-15 16:26:21');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tasks`
--

CREATE TABLE `tasks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `task` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_time` decimal(8,2) NOT NULL,
  `type` enum('RUTINARIO','PREVENTIVO','CORRECTIVO','RECAMBIO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RUTINARIO',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tasks`
--

INSERT INTO `tasks` (`id`, `task`, `component_id`, `estimated_time`, `type`, `created_at`, `updated_at`) VALUES
(1, 'Esse reprehenderit commodi pariatur quibusdam vitae enim odio.', 8, '15.00', 'RUTINARIO', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(2, 'Minus asperiores perferendis quia sequi autem.', 25, '15.00', 'RUTINARIO', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(3, 'Iusto officia tempore id dolore quia.', 14, '15.00', 'RUTINARIO', '2022-06-20 21:22:00', '2022-06-20 21:22:00'),
(4, 'Aut est odio dolorum dolor qui dolorem.', 2, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(5, 'Minus fugit voluptate non sit optio placeat.', 18, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(6, 'Sit et voluptatum quis ullam rem voluptate aut.', 31, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(7, 'Necessitatibus ut esse adipisci.', 9, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(8, 'Consequatur non aliquam aspernatur quis.', 3, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(9, 'Sed eius dolorem sequi fuga nihil.', 7, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(10, 'Nisi vitae dolorum modi molestiae consequatur nisi quis molestiae.', 10, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(11, 'Voluptatibus id alias ad rerum sint beatae sit voluptatem.', 9, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(12, 'Cumque magnam et et eligendi.', 32, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(13, 'Pariatur non qui provident dolores.', 1, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(14, 'Velit doloremque saepe ipsum et temporibus vitae omnis.', 22, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(15, 'Id possimus et sint blanditiis fugit accusamus ducimus.', 12, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(16, 'Tenetur autem recusandae nam dicta alias.', 24, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(17, 'Reprehenderit pariatur repellat voluptas et qui quis dolore dignissimos.', 18, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(18, 'Amet blanditiis nesciunt veniam consequatur qui harum odio.', 23, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(19, 'Placeat ullam quia enim pariatur sint delectus dolor.', 32, '15.00', 'RUTINARIO', '2022-06-20 21:22:01', '2022-06-20 21:22:01'),
(20, 'Aut sit sed natus.', 15, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(21, 'Qui et earum voluptatum ratione aut.', 7, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(22, 'Officiis quo libero ut sapiente.', 7, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(23, 'Libero dolor reiciendis ullam ut enim eos.', 8, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(24, 'Atque nulla fugit voluptatem reiciendis recusandae culpa.', 7, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(25, 'Molestiae vitae quia iste nemo harum.', 21, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(26, 'Voluptas illo quia ullam.', 24, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(27, 'Iure et reprehenderit molestiae.', 19, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(28, 'Aut totam unde qui voluptatem deserunt quia ipsum.', 15, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(29, 'Fugit iure occaecati quas alias itaque consequuntur perspiciatis.', 10, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(30, 'Maiores in laborum molestias.', 31, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(31, 'Commodi molestias magni fuga aspernatur.', 8, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(32, 'Eius quam et esse accusamus accusantium.', 29, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(33, 'Doloremque blanditiis amet ullam aut rerum quos et.', 17, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(34, 'Laudantium omnis sed laboriosam et ut.', 32, '15.00', 'RUTINARIO', '2022-06-20 21:22:02', '2022-06-20 21:22:02'),
(35, 'Earum dolorum quia sit sit voluptas.', 2, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(36, 'Dolores debitis esse quia et dolores modi.', 26, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(37, 'Animi est necessitatibus omnis omnis est dolor.', 34, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(38, 'Excepturi laborum dolore ea et autem dignissimos.', 30, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(39, 'Est minus accusantium deserunt et voluptatem nulla odio.', 23, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(40, 'Qui deserunt corporis id ut impedit explicabo nihil quaerat.', 9, '15.00', 'RUTINARIO', '2022-06-20 21:22:03', '2022-06-20 21:22:03'),
(47, 'RECAMBIO', 1, '30.00', 'RECAMBIO', NULL, NULL),
(51, 'RECAMBIO', 2, '15.00', 'RECAMBIO', NULL, NULL),
(52, 'RECAMBIO', 3, '15.00', 'RECAMBIO', NULL, NULL),
(53, 'RECAMBIO', 4, '15.00', 'RECAMBIO', NULL, NULL),
(54, 'RECAMBIO', 5, '15.00', 'RECAMBIO', NULL, NULL),
(55, 'RECAMBIO', 6, '15.00', 'RECAMBIO', NULL, NULL),
(56, 'RECAMBIO', 7, '15.00', 'RECAMBIO', NULL, NULL),
(57, 'RECAMBIO', 8, '15.00', 'RECAMBIO', NULL, NULL),
(58, 'RECAMBIO', 9, '15.00', 'RECAMBIO', NULL, NULL),
(59, 'RECAMBIO', 10, '15.00', 'RECAMBIO', NULL, NULL),
(60, 'RECAMBIO', 11, '15.00', 'RECAMBIO', NULL, NULL),
(61, 'RECAMBIO', 12, '15.00', 'RECAMBIO', NULL, NULL),
(62, 'RECAMBIO', 13, '15.00', 'RECAMBIO', NULL, NULL),
(63, 'RECAMBIO', 14, '15.00', 'RECAMBIO', NULL, NULL),
(64, 'RECAMBIO', 15, '15.00', 'RECAMBIO', NULL, NULL),
(65, 'RECAMBIO', 16, '15.00', 'RECAMBIO', NULL, NULL),
(66, 'RECAMBIO', 17, '15.00', 'RECAMBIO', NULL, NULL),
(67, 'RECAMBIO', 18, '15.00', 'RECAMBIO', NULL, NULL),
(68, 'RECAMBIO', 19, '15.00', 'RECAMBIO', NULL, NULL),
(69, 'RECAMBIO', 20, '15.00', 'RECAMBIO', NULL, NULL),
(70, 'RECAMBIO', 21, '15.00', 'RECAMBIO', NULL, NULL),
(71, 'RECAMBIO', 22, '15.00', 'RECAMBIO', NULL, NULL),
(72, 'RECAMBIO', 23, '15.00', 'RECAMBIO', NULL, NULL),
(73, 'RECAMBIO', 24, '15.00', 'RECAMBIO', NULL, NULL),
(74, 'RECAMBIO', 25, '15.00', 'RECAMBIO', NULL, NULL),
(75, 'RECAMBIO', 26, '15.00', 'RECAMBIO', NULL, NULL),
(76, 'RECAMBIO', 27, '15.00', 'RECAMBIO', NULL, NULL),
(77, 'RECAMBIO', 28, '15.00', 'RECAMBIO', NULL, NULL),
(78, 'RECAMBIO', 29, '15.00', 'RECAMBIO', NULL, NULL),
(79, 'RECAMBIO', 30, '15.00', 'RECAMBIO', NULL, NULL),
(80, 'RECAMBIO', 31, '15.00', 'RECAMBIO', NULL, NULL),
(81, 'RECAMBIO', 32, '15.00', 'RECAMBIO', NULL, NULL),
(82, 'RECAMBIO', 33, '15.00', 'RECAMBIO', NULL, NULL),
(83, 'RECAMBIO', 34, '15.00', 'RECAMBIO', NULL, NULL),
(84, 'Verfiicar', 4, '15.00', 'RUTINARIO', NULL, NULL),
(85, 'Comprobar', 5, '15.00', 'RUTINARIO', NULL, NULL),
(86, 'Rectificar', 6, '15.00', 'RUTINARIO', NULL, NULL),
(87, 'Mirar', 11, '15.00', 'RUTINARIO', NULL, NULL),
(88, 'Observar', 13, '15.00', 'RUTINARIO', NULL, NULL),
(89, 'Cotejar', 16, '15.00', 'RUTINARIO', NULL, NULL),
(90, 'Kasda', 20, '15.00', 'RUTINARIO', NULL, NULL),
(94, 'aerr', 27, '15.00', 'RUTINARIO', NULL, NULL),
(95, 'ser', 28, '15.00', 'RUTINARIO', NULL, NULL),
(96, 'dad', 33, '15.00', 'RUTINARIO', NULL, NULL),
(97, 'MANTENIMIENTO DE BUJIAS', 28, '36.00', 'PREVENTIVO', '2022-07-15 12:39:35', '2022-07-14 13:29:50'),
(98, 'MANTENIMIENTO DE EJE', 8, '30.00', 'PREVENTIVO', '2022-07-14 12:51:39', '2022-07-14 13:47:13'),
(99, 'MATENIMIENTO DE CIRCUITOS', 20, '30.00', 'PREVENTIVO', '2022-07-14 12:52:57', '2022-07-14 13:46:50');

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
(16, 84, 50, '1.00'),
(17, 1, 38, '1.00'),
(18, 1, 70, '1.00'),
(19, 1, 35, '1.00'),
(20, 2, 63, '1.00'),
(21, 2, 50, '1.00'),
(22, 2, 22, '1.00'),
(23, 77, 28, '1.00'),
(24, 77, 16, '1.00'),
(25, 77, 22, '2.00'),
(26, 77, 20, '1.00'),
(27, 97, 1, '1.00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tool_for_location`
--

CREATE TABLE `tool_for_location` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `state` enum('ACTIVO','PENDIENTE','OBSOLETO') NOT NULL DEFAULT 'ACTIVO',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
(1, 1, '72307', '1500.00', 1, '2022-06-20 21:22:03', '2022-07-21 19:26:17'),
(2, 1, '76737', '1659.00', 1, '2022-06-20 21:22:03', '2022-07-21 19:26:53'),
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
(25, 5, 1, 5, 5, '2022-08-18', 'MAÑANA', 5, 0, '2022-08-18 17:12:53', '2022-08-18 17:12:53'),
(26, 37, 1, 6, 6, '2022-08-18', 'MAÑANA', 5, 0, '2022-08-18 17:13:05', '2022-08-18 17:13:05'),
(27, 7, 3, 7, 7, '2022-08-18', 'MAÑANA', 7, 0, '2022-08-18 17:13:18', '2022-08-18 17:13:18'),
(28, 36, 5, 8, 8, '2022-08-18', 'MAÑANA', 7, 0, '2022-08-18 17:13:24', '2022-08-18 17:13:24'),
(29, 5, 3, 5, 5, '2022-08-19', 'MAÑANA', 5, 0, '2022-08-18 21:09:59', '2022-08-18 21:09:59'),
(30, 37, 5, 6, 6, '2022-08-19', 'MAÑANA', 5, 0, '2022-08-18 21:10:07', '2022-08-18 21:10:07'),
(31, 8, 2, 7, 8, '2022-08-19', 'MAÑANA', 8, 0, '2022-08-18 21:10:20', '2022-08-18 21:10:20'),
(32, 36, 5, 8, 7, '2022-08-19', 'MAÑANA', 8, 0, '2022-08-18 21:10:29', '2022-08-18 21:10:29'),
(33, 7, 3, 7, 7, '2022-08-18', 'NOCHE', 8, 0, '2022-08-18 21:10:58', '2022-08-18 21:10:58'),
(34, 8, 3, 8, 8, '2022-08-18', 'NOCHE', 8, 0, '2022-08-18 21:11:06', '2022-08-18 21:11:06'),
(35, 6, 4, 5, 5, '2022-08-18', 'NOCHE', 6, 0, '2022-08-18 21:11:19', '2022-08-18 21:11:19'),
(36, 5, 3, 6, 6, '2022-08-18', 'NOCHE', 6, 0, '2022-08-18 21:11:27', '2022-08-18 21:11:27'),
(37, 5, 3, 6, 6, '2022-08-19', 'NOCHE', 5, 0, '2022-08-18 21:11:46', '2022-08-18 21:11:46'),
(38, 37, 2, 5, 5, '2022-08-19', 'NOCHE', 5, 0, '2022-08-18 21:11:54', '2022-08-18 21:11:54'),
(39, 8, 3, 8, 7, '2022-08-19', 'NOCHE', 7, 0, '2022-08-18 21:12:09', '2022-08-18 21:12:09'),
(40, 36, 2, 7, 8, '2022-08-19', 'NOCHE', 7, 0, '2022-08-18 21:12:16', '2022-08-18 21:12:16');

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
(1, '777269', 'Mr. Ford Vandervort', 'Kunze', 1, 'roob.brianne@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'O0nIxI5IQprroeRZWEEa3vnPs0R1Pi5wgB9j0qktxHzR83vsquad1iThdR6V', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(2, '213312', 'Birdie Waelchi', 'Walker', 1, 'ernser.caden@example.org', '2022-06-20 21:21:37', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'kq6UeoBK8yBEh7t3lORPFEAPfgfFHoV59d0ik3tdEuR1ZFdngX8vVxDpSwRv', NULL, NULL, '2022-06-20 21:21:37', '2022-06-20 21:21:37'),
(3, '109931', 'Randi Leuschke', 'Cormier', 2, 'amaya.feeney@example.org', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'i8ehVi3sLB4xZmPyinXPVVagbbIAokfAbankLCFkiMTSSLX6A65RE5lEQjUH', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(4, '854140', 'Dr. Levi Feest', 'Ondricka', 2, 'woodrow.bogan@example.com', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'gzNzJmT6jNbUhqhriQXAFj2QQX4eChvPN12TmZFqsFGLn2m82KwPLKFWsTxG', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(5, '912055', 'Erwin Green', 'Heidenreich', 3, 'hbeatty@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'ru24VEDqMX306p1YRHGG3O2E0jPb4gJr22vcKCK9J7U70t5YZHxeVf0eiqBw', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(6, '502387', 'Bella Block', 'Bashirian', 3, 'sibyl08@example.net', '2022-06-20 21:21:38', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'RVExDOoZewUypH8ghrpflQW4DtNKg282pxx1kBPeW5BmwAtGRk5CK8SgMKwx', NULL, NULL, '2022-06-20 21:21:38', '2022-06-20 21:21:38'),
(7, '981787', 'Jaylon Prosacco', 'Langosh', 4, 'pleuschke@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'ze5dr2RfKobN0IEj4TKysHzR84jH0tO19WeXOP6jrIvLwNXJXEk5jIujUM19', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(8, '588440', 'Irving Strosin', 'Langosh', 4, 'mercedes57@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'gGkZjXDuDGzrNV5Cowztezi5rGrfPtFD3vl1CYPKXjxexgoGkTNEiagdrYhq', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(9, '454006', 'Margarett Heller', 'Cruickshank', 5, 'oconner.sydnie@example.org', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'yy14ZVjsNaQLhhKXXAGP6fxeGY28MwPWIQgy3S7RDNGLs8JAxhpa1ugk64fO', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(10, '916293', 'Dr. Ryder Gutmann V', 'McLaughlin', 5, 'dprice@example.com', '2022-06-20 21:21:39', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '6asVBO6pjosFw4Qqz0y2G3EHNAZQ0jmscpsuYiXp9fVcAZzNuufoavxUkN0w', NULL, NULL, '2022-06-20 21:21:39', '2022-06-20 21:21:39'),
(11, '985395', 'Eldora Considine DVM', 'Bashirian', 6, 'dedric.herman@example.net', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'mm9bEziZrO', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(12, '500276', 'Kali Heidenreich', 'Mills', 6, 'carrie.lebsack@example.net', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'JwmMsbBoeM', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(13, '645058', 'Mr. Zachery Hoeger', 'Fadel', 7, 'xkoelpin@example.org', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '7IksTELjOl', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(14, '650494', 'Chauncey Cummings III', 'Gaylord', 7, 'doug54@example.org', '2022-06-20 21:21:40', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, '0bdjgP8SoL', NULL, NULL, '2022-06-20 21:21:40', '2022-06-20 21:21:40'),
(15, '057018', 'Meda Bode', 'Lynch', 8, 'garrison42@example.com', '2022-06-20 21:21:41', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'p93dRjOOBD', NULL, NULL, '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(16, '266459', 'Carrie Haley', 'Wolf', 8, 'kathleen72@example.net', '2022-06-20 21:21:41', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, 'j6TyHWP4T1', NULL, NULL, '2022-06-20 21:21:41', '2022-06-20 21:21:41'),
(35, '999999', 'CARLOS', 'ESCATE ROMÁN', 1, 'STORNBLOOD6969@GMAIL.COM', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-07-21 06:39:33', '2022-07-21 06:39:33'),
(36, '888888', 'SERGIO', 'BERROCAL QUIÑONES', 4, 'SDD@GMAIL.COM', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-07-21 06:39:33', '2022-07-21 06:39:33'),
(37, '777777', 'RAMÓN', 'AGUADO APAZA', 3, 'ASS@GMAIL.COM', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-07-21 06:39:33', '2022-07-21 06:39:33'),
(38, '6666', 'LUCHO', 'ARANA PEREZ', 2, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-07-21 06:39:33', '2022-07-21 06:39:33'),
(40, '4197385', 'Rodrigo', 'Escate Román', 1, '', NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-07-26 06:51:33', '2022-07-26 06:51:33');

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
  `date` date NOT NULL,
  `maintenance` enum('1','2','3') COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','CONCLUIDO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validated_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_details`
--

CREATE TABLE `work_order_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL,
  `state` enum('ACEPTADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACEPTADO',
  `is_checked` tinyint(1) NOT NULL DEFAULT 0,
  `component_implement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `component_part_id` bigint(20) UNSIGNED DEFAULT NULL,
  `component_hours` decimal(8,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Disparadores `work_order_details`
--
DELIMITER $$
CREATE TRIGGER `componente_ordenado` AFTER UPDATE ON `work_order_details` FOR EACH ROW BEGIN
DECLARE material_final INT DEFAULT 0;
DECLARE material INT;
DECLARE cantidad DECIMAL(8,2);
DECLARE tipo_tarea VARCHAR(255);
SELECT type INTO tipo_tarea FROM tasks WHERE id = new.task_id;
IF new.state = "ACEPTADO" AND old.state = "RECHAZADO" AND tipo_tarea = "RECAMBIO" THEN
	/*-----Marcar componente ordenado si la tarea es de recambio------------*/
	IF new.component_part_id IS NULL THEN
    	UPDATE component_implement SET state = "ORDENADO" WHERE id = new.component_implement_id;
    ELSE
    /*------Marcar a la pieza ordenado si la tarea es de recambio------------*/
    UPDATE component_part SET state = "ORDENADO" WHERE id = new.component_part_id;
    END IF;
    /*------Poner materiales que tiene cada tarea-----*/
        BEGIN
            DECLARE cursor_tareas CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = new.task_id;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
            OPEN cursor_tareas;
                bucle:LOOP
                    IF material_final = 1 THEN
                        LEAVE bucle;
                    END IF;
                    FETCH cursor_tareas INTO material,cantidad;
                    IF EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = new.work_order_id AND item_id = material) THEN
                        UPDATE work_order_required_materials SET quantity = quantity + cantidad WHERE work_order_id = new.work_order_id AND item_id = material;
                    ELSE
                        INSERT INTO work_order_required_materials(work_order_id,item_id,quantity) VALUES (new.work_order_id,material,cantidad);
                    END IF;
                END LOOP bucle;
            CLOSE cursor_tareas;
        END;
ELSEIF new.state = "RECHAZADO" AND old.state = "ACEPTADO" AND tipo_tarea = "RECAMBIO" THEN
	/*---------Revertir cambios---------------------*/
	IF new.component_part_id IS NULL THEN
    	UPDATE component_implement SET state = "PENDIENTE" WHERE id = new.component_implement_id;
    ELSE
    	UPDATE component_part SET state = "PENDIENTE" WHERE id = new.component_part_id;
    END IF;
    /*------Quitar materiales que tiene cada tarea-----*/
        BEGIN
            DECLARE cursor_tareas CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = new.task_id;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
            OPEN cursor_tareas;
                bucle:LOOP
                    IF material_final = 1 THEN
                        LEAVE bucle;
                    END IF;
                    FETCH cursor_tareas INTO material,cantidad;
                    IF EXISTS(SELECT * FROM work_order_required_materials WHERE work_order_id = new.work_order_id AND item_id = material AND quantity >= cantidad) THEN
                        UPDATE work_order_required_materials SET quantity = quantity - cantidad WHERE work_order_id = new.work_order_id AND item_id = material;
                    ELSE
                    	UPDATE work_order_required_materials SET quantity = 0 WHERE work_order_id = new.work_order_id AND item_id = material;
                    END IF;
                END LOOP bucle;
            CLOSE cursor_tareas;
        END;
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
-- Estructura de tabla para la tabla `work_order_price_details`
--

CREATE TABLE `work_order_price_details` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_required_material_id` bigint(20) UNSIGNED NOT NULL,
  `general_stock_detail_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_order_required_materials`
--

CREATE TABLE `work_order_required_materials` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `work_order_id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` decimal(8,2) NOT NULL DEFAULT 1.00,
  `state` enum('PENDIENTE','RESERVADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Disparadores `work_order_required_materials`
--
DELIMITER $$
CREATE TRIGGER `retirar_materiales_del_stock` AFTER UPDATE ON `work_order_required_materials` FOR EACH ROW BEGIN
	IF new.state = "RECHAZADO" AND old.state = "RESERVADO" THEN
    BEGIN
    	DECLARE usuario INT;
    	SELECT user_id INTO usuario FROM work_orders WHERE id = old.work_order_id;
        UPDATE operator_stocks op SET op.ordered_quantity = op.ordered_quantity + old.quantity,used_quantity = used_quantity + old.quantity WHERE user_id = usuario AND item_id = new.item_id;
    	DELETE FROM work_order_price_details WHERE work_order_required_material_id = new.id; 
    END;
    ELSEIF new.state = "RESERVADO" THEN
            BEGIN
                DECLARE cantidad decimal(8,2) DEFAULT 0;
                DECLARE stock decimal(8,2) DEFAULT 0;
                DECLARE id_stock_detalle INT;
                DECLARE id_pre_reserva INT;
                DECLARE usuario INT;
                SET cantidad = new.quantity;
                
                SELECT user_id INTO usuario FROM work_orders WHERE id = new.work_order_id;
                IF old.state = "PENDIENTE" OR old.state = "RECHAZADO" THEN
                    UPDATE operator_stocks op SET op.ordered_quantity = op.ordered_quantity - new.quantity,used_quantity = used_quantity - new.quantity WHERE user_id = usuario AND item_id = new.item_id;
                ELSE
                    UPDATE operator_stocks op SET ordered_quantity = ordered_quantity - new.quantity + old.quantity,used_quantity = used_quantity - new.quantity + old.quantity WHERE user_id = usuario AND item_id = new.item_id;
                END IF;
                IF EXISTS (SELECT * FROM work_order_price_details WHERE work_order_required_material_id = new.id) THEN
                    DELETE FROM work_order_price_details WHERE work_order_detail_id = new.id; 
                END IF;
                SELECT psd.id INTO id_pre_reserva FROM pre_stockpile_details psd INNER JOIN pre_stockpiles ps ON ps.id = psd.pre_stockpile_id INNER JOIN work_orders wo ON wo.implement_id = ps.implement_id WHERE wo.id = new.work_order_id AND ps.state = "VALIDADO" LIMIT 1;
                WHILE cantidad > 0 DO
                    SELECT p.general_stock_detail_id, p.quantity_to_use INTO id_stock_detalle,stock FROM pre_stockpile_price_details p WHERE p.pre_stockpile_detail_id = id_pre_reserva ORDER BY id ASC LIMIT 1;
                    IF stock >= cantidad THEN
                        UPDATE general_stock_details gsd SET gsd.quantity_to_use = gsd.quantity_to_use - cantidad, gsd.quantity_to_reserve = gsd.quantity_to_reserve - cantidad WHERE gsd.id = id_stock_detalle ORDER BY id ASC LIMIT 1;
                    INSERT INTO work_order_price_details(work_order_required_material_id, general_stock_detail_id, quantity) VALUES (new.id, id_stock_detalle, cantidad);
                    SET cantidad = 0;
                ELSE
                    UPDATE general_stock_details gsd SET gsd.quantity_to_use = 0,gsd.quantity_to_reserve = 0 WHERE gsd.id = id_stock_detalle ORDER BY id ASC LIMIT 1;
                    INSERT INTO work_order_price_details(work_order_required_material_id, general_stock_detail_id, quantity) VALUES (new.id,id_stock_detalle,stock);
                    SET cantidad = cantidad - stock;
                END IF;
            END WHILE;
        END;
    END IF;
END
$$
DELIMITER ;

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
(1, '176445', 'SUR', '2022-06-20 21:21:36', '2022-06-20 21:21:36'),
(2, '678751', 'NORTE', '2022-06-20 21:21:39', '2022-06-20 21:21:39');

-- --------------------------------------------------------

--
-- Estructura para la vista `componentes_del_implemento`
--
DROP TABLE IF EXISTS `componentes_del_implemento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `componentes_del_implemento`  AS SELECT `c`.`id` AS `component_id`, `it`.`sku` AS `sku`, `c`.`item_id` AS `item_id`, `c`.`component` AS `item`, `i`.`id` AS `implement_id` FROM (((`components` `c` join `component_implement_model` `cim` on(`c`.`id` = `cim`.`component_id`)) join `implements` `i` on(`i`.`implement_model_id` = `cim`.`implement_model_id`)) join `items` `it` on(`it`.`id` = `c`.`item_id`))  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `lista_de_materiales_pedidos`
--
DROP TABLE IF EXISTS `lista_de_materiales_pedidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_de_materiales_pedidos`  AS SELECT `o`.`id` AS `order_request_id`, `u`.`id` AS `user_id`, `ord`.`id` AS `id`, `it`.`sku` AS `sku`, `it`.`item` AS `item`, `it`.`type` AS `type`, `ord`.`quantity` AS `quantity`, `mu`.`abbreviation` AS `abbreviation`, ifnull(`os`.`ordered_quantity`,0) AS `ordered_quantity`, ifnull(`os`.`used_quantity`,0) AS `used_quantity`, ifnull(`gs`.`quantity`,0) AS `stock`, `ord`.`state` AS `state` FROM ((((((((`order_request_details` `ord` join `order_requests` `o` on(`o`.`id` = `ord`.`order_request_id`)) join `users` `u` on(`u`.`id` = `o`.`user_id`)) join `locations` `l` on(`l`.`id` = `u`.`location_id`)) join `sedes` `s` on(`s`.`id` = `l`.`sede_id`)) join `items` `it` on(`it`.`id` = `ord`.`item_id`)) join `measurement_units` `mu` on(`mu`.`id` = `it`.`measurement_unit_id`)) left join `operator_stocks` `os` on(`os`.`user_id` = `u`.`id` and `os`.`item_id` = `it`.`id`)) left join `general_stocks` `gs` on(`gs`.`item_id` = `it`.`id` and `gs`.`sede_id` = `s`.`id`))  ;

-- --------------------------------------------------------

--
-- Estructura para la vista `lista_de_materiales_pedidos_pendientes`
--
DROP TABLE IF EXISTS `lista_de_materiales_pedidos_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_de_materiales_pedidos_pendientes`  AS SELECT `o`.`id` AS `order_request_id`, `u`.`id` AS `user_id`, `ord`.`id` AS `id`, `it`.`sku` AS `sku`, `it`.`item` AS `item`, `it`.`type` AS `type`, `ord`.`quantity` AS `quantity`, `mu`.`abbreviation` AS `abbreviation`, ifnull(`os`.`ordered_quantity`,0) AS `ordered_quantity`, ifnull(`os`.`used_quantity`,0) AS `used_quantity`, ifnull(`gs`.`quantity`,0) AS `stock` FROM ((((((((`order_request_details` `ord` join `order_requests` `o` on(`o`.`id` = `ord`.`order_request_id`)) join `users` `u` on(`u`.`id` = `o`.`user_id`)) join `locations` `l` on(`l`.`id` = `u`.`location_id`)) join `sedes` `s` on(`s`.`id` = `l`.`sede_id`)) join `items` `it` on(`it`.`id` = `ord`.`item_id`)) join `measurement_units` `mu` on(`mu`.`id` = `it`.`measurement_unit_id`)) left join `operator_stocks` `os` on(`os`.`user_id` = `u`.`id` and `os`.`item_id` = `it`.`id`)) left join `general_stocks` `gs` on(`gs`.`item_id` = `it`.`id` and `gs`.`sede_id` = `s`.`id`)) WHERE `ord`.`state` = 'PENDIENTE''PENDIENTE'  ;

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `pieza_simplificada`  AS SELECT `it`.`sku` AS `sku`, `p`.`item_id` AS `item_id`, `p`.`component` AS `part`, `c`.`item_id` AS `component_id` FROM (((`component_part_model` `cpm` join `components` `c` on(`c`.`id` = `cpm`.`component`)) join `components` `p` on(`p`.`id` = `cpm`.`part`)) join `items` `it` on(`it`.`id` = `p`.`item_id`))  ;

--
-- Índices para tablas volcadas
--

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
-- Indices de la tabla `general_order_requests`
--
ALTER TABLE `general_order_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_order_requests_item_id_foreign` (`item_id`),
  ADD KEY `general_order_requests_sede_id_foreign` (`sede_id`),
  ADD KEY `general_order_requests_order_date_id_foreign` (`order_date_id`);

--
-- Indices de la tabla `general_stocks`
--
ALTER TABLE `general_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_stocks_general_warehouse_id_foreign` (`sede_id`),
  ADD KEY `general_stocks_general_item_id_foreign` (`item_id`);

--
-- Indices de la tabla `general_stock_details`
--
ALTER TABLE `general_stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_stock_details_general_warehouse_id_foreign` (`sede_id`),
  ADD KEY `general_stock_details_order_date_id_foreign` (`order_date_id`),
  ADD KEY `general_stock_details_item_id_foreign` (`item_id`);

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
-- Indices de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `operator_stocks_user_id_foreign` (`user_id`),
  ADD KEY `operator_stocks_item_id_foreign` (`item_id`);

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
  ADD KEY `order_requests_validate_by_foreign` (`validated_by`),
  ADD KEY `order_requests_order_date_id_foreign` (`order_date_id`),
  ADD KEY `state` (`state`);

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
-- Indices de la tabla `preventive_maintenance_frequencies`
--
ALTER TABLE `preventive_maintenance_frequencies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `preventive_maintenance_frequencies_component_id_foreign` (`component_id`);

--
-- Indices de la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pre_stockpiles_user_id_foreign` (`user_id`),
  ADD KEY `pre_stockpiles_implement_foreign` (`implement_id`),
  ADD KEY `pre_stockpiles_pre_stockpile_date_id_foreign` (`pre_stockpile_date_id`),
  ADD KEY `pre_stockpiles_validate_by_foreign` (`validated_by`);

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
  ADD KEY `pre_stockpile_details_item_id_foreign` (`item_id`);

--
-- Indices de la tabla `pre_stockpile_price_details`
--
ALTER TABLE `pre_stockpile_price_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_stock_price_details_general_stock_detail_id` (`general_stock_detail_id`),
  ADD KEY `general_stock_price_details_pre_stockpile_detail_id` (`pre_stockpile_detail_id`);

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
-- Indices de la tabla `routine_tasks`
--
ALTER TABLE `routine_tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `implement_id` (`implement_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `validated_by` (`validated_by`),
  ADD KEY `tractor_scheduling_id` (`tractor_scheduling_id`);

--
-- Indices de la tabla `routine_task_details`
--
ALTER TABLE `routine_task_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `task` (`task_id`),
  ADD KEY `routine_task_details_ibfk_2` (`routine_task_id`);

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
  ADD KEY `validated_by` (`validated_by`);

--
-- Indices de la tabla `stockpile_details`
--
ALTER TABLE `stockpile_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stockpile_details_stockpile_id_foreign` (`stockpile_id`),
  ADD KEY `stockpile_details_item_id_foreign` (`item_id`);

--
-- Indices de la tabla `stockpile_price_details`
--
ALTER TABLE `stockpile_price_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stockpile_id` (`stockpile_id`),
  ADD KEY `general_stock_detail_id` (`general_stock_detail_id`);

--
-- Indices de la tabla `stocks`
--
ALTER TABLE `stocks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stocks_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `stocks_item_id_warehouse_id_index` (`item_id`,`warehouse_id`);

--
-- Indices de la tabla `stock_details`
--
ALTER TABLE `stock_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stock_details_item_id_foreign` (`item_id`),
  ADD KEY `stock_details_warehouse_id_foreign` (`warehouse_id`),
  ADD KEY `stock_details_user_id_foreign` (`user_id`),
  ADD KEY `stock_details_validated_by_foreign` (`validated_by`);

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
  ADD KEY `tasks_component_id_foreign` (`component_id`),
  ADD KEY `type` (`type`);

--
-- Indices de la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  ADD PRIMARY KEY (`id`),
  ADD KEY `task_required_materials_task_id_foreign` (`task_id`),
  ADD KEY `task_required_materials_item_id_foreign` (`item_id`);

--
-- Indices de la tabla `tool_for_location`
--
ALTER TABLE `tool_for_location`
  ADD PRIMARY KEY (`id`);

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
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_location_id_foreign` (`location_id`);

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
  ADD KEY `work_orders_user_id_foreign` (`user_id`);

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
-- Indices de la tabla `work_order_price_details`
--
ALTER TABLE `work_order_price_details`
  ADD PRIMARY KEY (`id`),
  ADD KEY `general_stock_detail_id` (`general_stock_detail_id`),
  ADD KEY `work_order_required_material_id` (`work_order_required_material_id`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT de la tabla `component_implement`
--
ALTER TABLE `component_implement`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=169;

--
-- AUTO_INCREMENT de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `component_part`
--
ALTER TABLE `component_part`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=361;

--
-- AUTO_INCREMENT de la tabla `component_part_model`
--
ALTER TABLE `component_part_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1601;

--
-- AUTO_INCREMENT de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `general_order_requests`
--
ALTER TABLE `general_order_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=118;

--
-- AUTO_INCREMENT de la tabla `general_stocks`
--
ALTER TABLE `general_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=154;

--
-- AUTO_INCREMENT de la tabla `general_stock_details`
--
ALTER TABLE `general_stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=396;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=143;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

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
-- AUTO_INCREMENT de la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=323;

--
-- AUTO_INCREMENT de la tabla `order_dates`
--
ALTER TABLE `order_dates`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `order_requests`
--
ALTER TABLE `order_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=166;

--
-- AUTO_INCREMENT de la tabla `order_request_details`
--
ALTER TABLE `order_request_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=793;

--
-- AUTO_INCREMENT de la tabla `order_request_new_items`
--
ALTER TABLE `order_request_new_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

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
-- AUTO_INCREMENT de la tabla `preventive_maintenance_frequencies`
--
ALTER TABLE `preventive_maintenance_frequencies`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT de la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=50;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_dates`
--
ALTER TABLE `pre_stockpile_dates`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=329;

--
-- AUTO_INCREMENT de la tabla `pre_stockpile_price_details`
--
ALTER TABLE `pre_stockpile_price_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=346;

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
-- AUTO_INCREMENT de la tabla `routine_tasks`
--
ALTER TABLE `routine_tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT de la tabla `routine_task_details`
--
ALTER TABLE `routine_task_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=336;

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
-- AUTO_INCREMENT de la tabla `stockpile_price_details`
--
ALTER TABLE `stockpile_price_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `stocks`
--
ALTER TABLE `stocks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;

--
-- AUTO_INCREMENT de la tabla `stock_details`
--
ALTER TABLE `stock_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `systems`
--
ALTER TABLE `systems`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=100;

--
-- AUTO_INCREMENT de la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT de la tabla `tool_for_location`
--
ALTER TABLE `tool_for_location`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

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
-- AUTO_INCREMENT de la tabla `work_order_price_details`
--
ALTER TABLE `work_order_price_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `work_order_required_materials`
--
ALTER TABLE `work_order_required_materials`
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
-- Filtros para la tabla `general_order_requests`
--
ALTER TABLE `general_order_requests`
  ADD CONSTRAINT `general_order_requests_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `general_order_requests_order_date_id_foreign` FOREIGN KEY (`order_date_id`) REFERENCES `order_dates` (`id`),
  ADD CONSTRAINT `general_order_requests_sede_id_foreign` FOREIGN KEY (`sede_id`) REFERENCES `sedes` (`id`);

--
-- Filtros para la tabla `general_stocks`
--
ALTER TABLE `general_stocks`
  ADD CONSTRAINT `general_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `general_stocks_sede_id_foreign` FOREIGN KEY (`sede_id`) REFERENCES `sedes` (`id`);

--
-- Filtros para la tabla `general_stock_details`
--
ALTER TABLE `general_stock_details`
  ADD CONSTRAINT `general_stock_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `general_stock_details_order_date_id_foreign` FOREIGN KEY (`order_date_id`) REFERENCES `order_dates` (`id`),
  ADD CONSTRAINT `general_stock_details_sede_id_foreign` FOREIGN KEY (`sede_id`) REFERENCES `sedes` (`id`);

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
-- Filtros para la tabla `operator_stocks`
--
ALTER TABLE `operator_stocks`
  ADD CONSTRAINT `operator_stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `operator_stocks_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `order_requests`
--
ALTER TABLE `order_requests`
  ADD CONSTRAINT `order_requests_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `order_requests_order_date_id_foreign` FOREIGN KEY (`order_date_id`) REFERENCES `order_dates` (`id`),
  ADD CONSTRAINT `order_requests_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `order_requests_validate_by_foreign` FOREIGN KEY (`validated_by`) REFERENCES `users` (`id`);

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
-- Filtros para la tabla `preventive_maintenance_frequencies`
--
ALTER TABLE `preventive_maintenance_frequencies`
  ADD CONSTRAINT `preventive_maintenance_frequencies_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `components` (`id`);

--
-- Filtros para la tabla `pre_stockpiles`
--
ALTER TABLE `pre_stockpiles`
  ADD CONSTRAINT `pre_stockpiles_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `pre_stockpiles_pre_stockpile_date_id_foreign` FOREIGN KEY (`pre_stockpile_date_id`) REFERENCES `pre_stockpile_dates` (`id`),
  ADD CONSTRAINT `pre_stockpiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `pre_stockpiles_validate_by_foreign` FOREIGN KEY (`validated_by`) REFERENCES `users` (`id`);

--
-- Filtros para la tabla `pre_stockpile_details`
--
ALTER TABLE `pre_stockpile_details`
  ADD CONSTRAINT `pre_stockpile_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `pre_stockpile_details_pre_stockpile_foreign` FOREIGN KEY (`pre_stockpile_id`) REFERENCES `pre_stockpiles` (`id`);

--
-- Filtros para la tabla `pre_stockpile_price_details`
--
ALTER TABLE `pre_stockpile_price_details`
  ADD CONSTRAINT `general_stock_price_details_general_stock_detail_id` FOREIGN KEY (`general_stock_detail_id`) REFERENCES `general_stock_details` (`id`),
  ADD CONSTRAINT `general_stock_price_details_pre_stockpile_detail_id` FOREIGN KEY (`pre_stockpile_detail_id`) REFERENCES `pre_stockpile_details` (`id`);

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
-- Filtros para la tabla `routine_tasks`
--
ALTER TABLE `routine_tasks`
  ADD CONSTRAINT `routine_tasks_ibfk_1` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `routine_tasks_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `routine_tasks_ibfk_3` FOREIGN KEY (`validated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `routine_tasks_ibfk_4` FOREIGN KEY (`tractor_scheduling_id`) REFERENCES `tractor_schedulings` (`id`);

--
-- Filtros para la tabla `routine_task_details`
--
ALTER TABLE `routine_task_details`
  ADD CONSTRAINT `routine_task_details_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`),
  ADD CONSTRAINT `routine_task_details_ibfk_2` FOREIGN KEY (`routine_task_id`) REFERENCES `routine_tasks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `sedes`
--
ALTER TABLE `sedes`
  ADD CONSTRAINT `sedes_zone_id_foreign` FOREIGN KEY (`zone_id`) REFERENCES `zones` (`id`);

--
-- Filtros para la tabla `stockpiles`
--
ALTER TABLE `stockpiles`
  ADD CONSTRAINT `stockpiles_ibfk_1` FOREIGN KEY (`validated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `stockpiles_implement_id_foreign` FOREIGN KEY (`implement_id`) REFERENCES `implements` (`id`),
  ADD CONSTRAINT `stockpiles_pre_stockpile_id_foreign` FOREIGN KEY (`pre_stockpile_id`) REFERENCES `pre_stockpiles` (`id`),
  ADD CONSTRAINT `stockpiles_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `stockpiles_work_order_id_foreign` FOREIGN KEY (`work_order_id`) REFERENCES `work_orders` (`id`);

--
-- Filtros para la tabla `stockpile_details`
--
ALTER TABLE `stockpile_details`
  ADD CONSTRAINT `stockpile_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `stockpile_details_stockpile_id_foreign` FOREIGN KEY (`stockpile_id`) REFERENCES `stockpiles` (`id`);

--
-- Filtros para la tabla `stockpile_price_details`
--
ALTER TABLE `stockpile_price_details`
  ADD CONSTRAINT `stockpile_price_details_ibfk_1` FOREIGN KEY (`stockpile_id`) REFERENCES `stockpiles` (`id`),
  ADD CONSTRAINT `stockpile_price_details_ibfk_2` FOREIGN KEY (`general_stock_detail_id`) REFERENCES `general_stock_details` (`id`);

--
-- Filtros para la tabla `stocks`
--
ALTER TABLE `stocks`
  ADD CONSTRAINT `stocks_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `stocks_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

--
-- Filtros para la tabla `stock_details`
--
ALTER TABLE `stock_details`
  ADD CONSTRAINT `stock_details_item_id_foreign` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `stock_details_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `stock_details_validated_by_foreign` FOREIGN KEY (`validated_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `stock_details_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`);

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
-- Filtros para la tabla `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_location_id_foreign` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`);

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
-- Filtros para la tabla `work_order_price_details`
--
ALTER TABLE `work_order_price_details`
  ADD CONSTRAINT `work_order_price_details_ibfk_1` FOREIGN KEY (`general_stock_detail_id`) REFERENCES `general_stock_details` (`id`),
  ADD CONSTRAINT `work_order_price_details_ibfk_2` FOREIGN KEY (`work_order_required_material_id`) REFERENCES `work_order_required_materials` (`id`);

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
CREATE DEFINER=`root`@`localhost` EVENT `asignar_monto_ceco` ON SCHEDULE EVERY 1 MONTH STARTS '2022-06-01 00:00:00' ON COMPLETION NOT PRESERVE DISABLE DO UPDATE ceco_allocation_amounts SET is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

CREATE DEFINER=`root`@`localhost` EVENT `Listar_materiales_pedido` ON SCHEDULE EVERY 1 DAY STARTS '2022-06-27 00:00:00' ON COMPLETION PRESERVE DISABLE DO BEGIN
    /*---------VARIABLES PARA LA ALMACENAR LA FECHA PARA ABRIR EL PEDIDO-----------------------------*/
        DECLARE fecha_solicitud INT;
        DECLARE fecha_abrir_solicitud DATE;
    /*---------OBTENER LA FECHA DE APERTURA DEL PEDIDO MÁS CERCANO-----------------------------------*/
        SELECT id,open_request INTO fecha_solicitud,fecha_abrir_solicitud FROM order_dates WHERE state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
    /*---------HACER EN CASO SEA FECHA DE ABRIR EL PEDIDO-----------------------------------------*/
        IF(fecha_abrir_solicitud <= NOW()) THEN
            BEGIN
                /*-----------VARIABLES PARA DETENER LOS CICLOS------------------------------*/
                    DECLARE implemento_final INT DEFAULT 0;
                    DECLARE componente_final INT DEFAULT 0;
                    DECLARE pieza_final INT DEFAULT 0;
                    DECLARE tarea_final INT DEFAULT 0;
                    DECLARE material_final INT DEFAULT 0;
                /*-----------VARIABLES PARA LA CABECERA DE LA SOLICITUD DE PEDIDO-----------*/
                    DECLARE implemento INT;
                    DECLARE responsable INT;
                /*-----------VARIABLES PARA EL DETALLE DE LA SOLICITUD DEL PEDIDO-----------*/
                    DECLARE solicitud_pedido INT;
                    DECLARE componente_del_implemento INT;
                    DECLARE pieza_del_componente INT;
                /*-----------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO---------------*/
                    DECLARE modelo_del_implemento INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE------------------*/
                    DECLARE componente INT;
                    DECLARE horas_componente DECIMAL(8,2);
                    DECLARE tiempo_vida_componente DECIMAL(8,2);
                    DECLARE cantidad_componente_recambio DECIMAL(8,2);
                    DECLARE cantidad_componente_preventivo DECIMAL(8,2);
                    DECLARE item_componente DECIMAL(8,2);
                    DECLARE precio_componente DECIMAL(8,2);
                    DECLARE frecuencia_componente DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_componente DECIMAL(8,2);
                    DECLARE tarea_componente INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA---------------------*/
                    DECLARE pieza INT;
                    DECLARE horas_pieza DECIMAL(8,2);
                    DECLARE tiempo_vida_pieza DECIMAL(8,2);
                    DECLARE cantidad_pieza_recambio DECIMAL(8,2);
                    DECLARE cantidad_pieza_preventivo DECIMAL(8,2);
                    DECLARE item_pieza DECIMAL(8,2);
                    DECLARE precio_pieza DECIMAL(8,2);
                    DECLARE frecuencia_pieza DECIMAL(8,2);
                    DECLARE horas_ultimo_mantenimiento_pieza DECIMAL(8,2);
                    DECLARE tarea_pieza INT;
                /*-----------VARIABLES PARA MATERIAL-----------------------*/
                    DECLARE material INT;
                /*-----------CURSOR PARA ITERAR CADA IMPLEMENTO-----------------------------*/
                    DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id FROM implements;
                    DECLARE CONTINUE HANDLER for NOT FOUND SET implemento_final = 1;
                /*-----------ABRIR CURSOR DE LOS IMPLEMENTOS--------------------------------*/
                    OPEN cursor_implementos;
                        bucle_implementos:LOOP
                            /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS-------------*/
                                IF implemento_final = 1 THEN
                                    LEAVE bucle_implementos;
                                END IF;
                            /*---------OBTENER LOS DATOS DEL IMPLEMENTO DEL CICLO-----------------------*/
                                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
                            /*---------HACER EN CASO LA SOLICITUD DE PEDIDO SI NO ESTÁ CREADA AÚN-------*/
                                IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud) THEN
                                    /*----------------------CREAR CABECERA DE LA SOLICITUD DE PEDIDO---------------------------------*/
                                        INSERT INTO order_requests (user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
                                    /*----------------------OBTENER ID DE LA CABECERA DEL PEDIDO-------------------------------------*/
                                        SELECT id INTO solicitud_pedido FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud;
                                    /*----------------------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO DEL CICLO--------------*/
                                        BEGIN
                                            DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                                            /*--------------ABRIR CURSOR DE LOS COMPONENTES--------------------------------------------*/
                                                OPEN cursor_componentes;
                                                    bucle_componentes:LOOP
                                                        /*---------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS----------------------------------------*/
                                                            IF componente_final = 1 THEN
                                                                LEAVE bucle_componentes;
                                                            END IF;
                                                        /*---------OBTENER LOS DATOS DEL COMPONENTE DEL CICLO--------------------------------------------------*/
                                                            FETCH cursor_componentes INTO componente;
                                                        /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------------*/
                                                            IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento) THEN
                                                                /*-----------CREAR REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------*/
                                                                    INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
                                                            END IF;
                                                        /*---------OBTENER EL ID Y HORAS DEL COMPONENTE DEL IMPLEMENTO ----------------------------------------*/
                                                            SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                                        /*---------OBTENER TIEMPO DE VIDA Y EL ID DEL ITEM DEL COMPONENTE -------------------------------------*/
                                                            SELECT c.lifespan,c.item_id,i.estimated_price INTO tiempo_vida_componente,item_componente,precio_componente FROM components c INNER JOIN items i ON i.id = c.item_id WHERE c.id = componente;
                                                        /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DEL COMPONENTE--------------------------------*/
                                                            IF horas_componente > tiempo_vida_componente THEN
                                                                /*-----------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS-----------------------------------*/
                                                                SELECT tiempo_vida_componente INTO horas_componente;
                                                            END IF;
                                                        /*---------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES--------------------------------------------*/
                                                            SELECT FLOOR((horas_componente+336)/tiempo_vida_componente) INTO cantidad_componente_recambio;
                                                        /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------------*/
                                                            SELECT frequency INTO frecuencia_componente FROM preventive_maintenance_frequencies WHERE component_id = componente;
                                                        /*---------OBTENER HORAS DEL ÚLTIMO MANTENIMIENTO DEL COMPONENTE EN CASO HUBIERA-----------------------*/
                                                            IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_implement_id = componente_del_implemento AND t.type = "PREVENTIVO") THEN
                                                                SELECT component_hours INTO horas_ultimo_mantenimiento_componente FROM work_order_details WHERE component_implement_id = componente_del_implemento AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                            ELSE
                                                                SELECT 0 INTO horas_ultimo_mantenimiento_componente;
                                                            END IF;
                                                        /*---------HACER EN CASO NECESITE RECAMBIO-------------------------------------------------------------*/
                                                            IF cantidad_componente_recambio > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_componente_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "RECAMBIO";
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                            OPEN cursor_componente_tareas_recambio;
                                                                                bucle_componente_tareas_recambio:LOOP
                                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                        IF tarea_final = 1 THEN
                                                                                            LEAVE bucle_componente_tareas_recambio;
                                                                                        END IF;
                                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                        FETCH cursor_componente_tareas_recambio INTO tarea_componente;
                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                OPEN cursor_materiales_recambio;
                                                                                                    bucle_materiales:LOOP
                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                            IF material_final = 1 THEN
                                                                                                                LEAVE bucle_materiales;
                                                                                                            END IF;
                                                                                                        /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                            IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_componente AND order_request_id = solicitud_pedido) THEN
                                                                                                                INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_componente,cantidad_componente_recambio,precio_componente);
                                                                                                            ELSE
                                                                                                                UPDATE order_request_details SET quantity = quantity + cantidad_componente_recambio WHERE order_request_id = solicitud_pedido AND item_id = item_componente;
                                                                                                            END IF;
                                                                                                    END LOOP bucle_materiales;
                                                                                                CLOSE cursor_materiales_recambio;
                                                                                            /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                SELECT 0 INTO material_final;
                                                                                        END;
                                                                                END LOOP bucle_componente_tareas_recambio;
                                                                            CLOSE cursor_componente_tareas_recambio;
                                                                        /*--------RESETEAR CONTADOR DE TAREAS----------------------------------------------*/
                                                                            SELECT 0 INTO tarea_final;
                                                                    END;
                                                            END IF;
                                                        /*---------CALCULAR MANTENIMIENTO PREVENTIVOS----------------------------------------------------------*/
                                                            SELECT (FLOOR((horas_ultimo_mantenimiento_componente+336)/frecuencia_componente) - cantidad_componente_recambio) INTO cantidad_componente_preventivo;
                                                        /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------------*/
                                                            IF cantidad_componente_preventivo > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------*/
                                                                    BEGIN
                                                                        DECLARE cursor_componente_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "PREVENTIVO";
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                            OPEN cursor_componente_tareas_preventivo;
                                                                                bucle_componente_tareas_preventino:LOOP
                                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                        IF tarea_final = 1 THEN
                                                                                            LEAVE bucle_componente_tareas_preventino;
                                                                                        END IF;
                                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                        FETCH cursor_componente_tareas_preventivo INTO tarea_componente;
                                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                            /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                OPEN cursor_materiales_preventivo;
                                                                                                    bucle_materiales:LOOP
                                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                            IF material_final = 1 THEN
                                                                                                                LEAVE bucle_materiales;
                                                                                                            END IF;
                                                                                                        /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                            IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_componente AND order_request_id = solicitud_pedido) THEN
                                                                                                                INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_componente,cantidad_componente_preventivo,precio_componente);
                                                                                                            ELSE
                                                                                                                UPDATE order_request_details SET quantity = quantity + cantidad_componente_preventivo WHERE order_request_id = solicitud_pedido AND item_id = item_componente;
                                                                                                            END IF;
                                                                                                    END LOOP bucle_materiales;
                                                                                                CLOSE cursor_materiales_preventivo;
                                                                                            /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                SELECT 0 INTO material_final;
                                                                                        END;
                                                                                END LOOP bucle_componente_tareas_preventino;
                                                                            CLOSE cursor_componente_tareas_preventivo;
                                                                        /*--------RESETEAR CONTADOR TAREAS-----------------------------------------------------------*/
                                                                            SELECT 0 INTO tarea_final;
                                                                    END;
                                                            END IF;
                                                        /*---------CURSOR PARA ITERAR CADA PIEZA DEL COMPONENTE-------------------------------------------------*/
                                                            BEGIN
                                                                DECLARE cursor_piezas CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
                                                                /*---------ABRIR CURSOR PARA LAS PIEZAS--------------------------------------------------*/
                                                                    OPEN cursor_piezas;
                                                                        bucle_piezas:LOOP
                                                                            /*---------DETENER CICLO CUANDO NO SE ENCUENTREN MAS PIEZAS---------------------------------------*/
                                                                                IF pieza_final = 1 THEN
                                                                                    LEAVE bucle_piezas;
                                                                                END IF;
                                                                            /*---------OBTENER LOS DATOS DE LA PIEZA DEL CICLO------------------------------------------------*/
                                                                                FETCH cursor_piezas INTO pieza;

                                                                            /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DE LA PIEZA DEL COMPONENTE DEL IMPLEMENTO----*/
                                                                                IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id  = componente_del_implemento AND part = pieza AND state = "PENDIENTE") THEN
                                                                                    INSERT INTO component_part (component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                                                                END IF;
                                                                            /*---------OBTENER ID Y HORAS DE LA PIEZA DEL COMPONENTE------------------------------------------*/
                                                                                SELECT id,hours INTO pieza_del_componente,horas_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza AND state = "PENDIENTE";
                                                                            /*---------OBTENER EL TIEMPO DE VIDA Y EL ID DEL ALMACEN DE LA PIEZA------------------------------*/
                                                                                SELECT lifespan,item_id INTO tiempo_vida_pieza,item_pieza FROM components WHERE id = pieza;
                                                                            /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DE LA PIEZA------------------------------*/
                                                                                IF horas_pieza >= tiempo_vida_pieza THEN
                                                                                    /*---------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS----------*/
                                                                                        SELECT tiempo_vida_pieza INTO horas_pieza;
                                                                                END IF;
                                                                            /*---------CALCULAR SI NECESITA RECAMBIO DENTRO DE 2 MESES----------------------------------------*/
                                                                                SELECT FLOOR((horas_pieza+336)/tiempo_vida_pieza) INTO cantidad_pieza_recambio;
                                                                            /*---------OBTENER FRECUENCIA DE MANTENIMIENTO PREVENTIVO DE LA PIEZA-----------------------------*/
                                                                                SELECT frequency INTO frecuencia_componente FROM preventive_maintenance_frequencies WHERE component_id = pieza;
                                                                            /*---------OBTENER HORAS DEL ÚLTIMO MATENIMIENTO DE LA PIEZA EN CASO HUBIERA----------------------*/
                                                                                IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1) THEN
                                                                                        SELECT wod.component_hours INTO horas_ultimo_mantenimiento_pieza FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                                                    ELSE
                                                                                        SELECT 0 INTO horas_ultimo_mantenimiento_pieza;
                                                                                    END IF;
                                                                            /*---------HACER EN CASO NECESITE RECAMBIO--------------------------------------------------------*/
                                                                                IF(cantidad_pieza_recambio > 0) THEN
                                                                                        /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                                            BEGIN
                                                                                                DECLARE cursor_pieza_tareas_recambio CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "RECAMBIO";
                                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                                /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                                                    OPEN cursor_pieza_tareas_recambio;
                                                                                                        bucle_pieza_tareas_recambio:LOOP
                                                                                                            /*----------DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                                IF tarea_final = 1 THEN
                                                                                                                    LEAVE bucle_pieza_tareas_recambio;
                                                                                                                END IF;
                                                                                                            /*----------OBTENER LA TAREA DE LA PIEZA--------------------------------*/
                                                                                                                FETCH cursor_pieza_tareas_recambio INTO tarea_pieza;
                                                                                                            /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA---------------*/
                                                                                                                BEGIN
                                                                                                                    DECLARE cursor_materiales_recambio CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                    /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                        OPEN cursor_materiales_recambio;
                                                                                                                            bucle_materiales:LOOP
                                                                                                                                /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                    IF material_final = 1 THEN
                                                                                                                                        LEAVE bucle_materiales;
                                                                                                                                    END IF;
                                                                                                                                /*----------PONER MATERIALES PARA PEDIDO----------------------------------------*/
                                                                                                                                    IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_pieza AND order_request_id = solicitud_pedido) THEN
                                                                                                                                        INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_recambio,precio_componente);
                                                                                                                                    ELSE
                                                                                                                                        UPDATE order_request_details SET quantity = quantity + cantidad_pieza_recambio WHERE order_request_id = solicitud_pedido AND item_id = item_pieza;
                                                                                                                                    END IF;
                                                                                                                            END LOOP bucle_materiales;
                                                                                                                        CLOSE cursor_materiales_recambio;
                                                                                                                    /*---------RESETEAR CONTADOR DE MATERIALES-------------------------*/
                                                                                                                        SELECT 0 INTO material_final;
                                                                                                                END;
                                                                                                        END LOOP bucle_pieza_tareas_recambio;
                                                                                                    CLOSE cursor_pieza_tareas_recambio;
                                                                                                /*----------RESETEAR CONTADOR DE TAREAS----------------------------*/
                                                                                                    SELECT 0 INTO tarea_final;
                                                                                            END;
                                                                                END IF;
                                                                            /*---------CALCULAR MANTENIMIENTO PREVENTIVOS-----------------------------------------------------*/
                                                                                SELECT (FLOOR((horas_ultimo_mantenimiento_pieza+336)/frecuencia_pieza) - cantidad_componente_recambio) INTO cantidad_componente_preventivo;
                                                                            /*----------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------*/
                                                                                IF cantidad_componente_preventivo > 0 THEN
                                                                                    /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DE LA PIEZA-------------------------*/
                                                                                        BEGIN
                                                                                            DECLARE cursor_pieza_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = "PREVENTIVO";
                                                                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                                            /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                                                OPEN cursor_pieza_tareas_preventivo;
                                                                                                    bucle_pieza_tareas_preventino:LOOP
                                                                                                        /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                                                            IF tarea_final = 1 THEN
                                                                                                                LEAVE bucle_pieza_tareas_preventino;
                                                                                                            END IF;
                                                                                                        /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                                            FETCH cursor_pieza_tareas_preventivo INTO tarea_pieza;
                                                                                                        /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                                                            BEGIN
                                                                                                                DECLARE cursor_materiales_preventivo CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_pieza;
                                                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                                                /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                                                    OPEN cursor_materiales_preventivo;
                                                                                                                        bucle_materiales:LOOP
                                                                                                                            /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                                                                IF material_final = 1 THEN
                                                                                                                                    LEAVE bucle_materiales;
                                                                                                                                END IF;
                                                                                                                            /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                                                                IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_pieza AND order_request_id = solicitud_pedido) THEN
                                                                                                                                    INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_preventivo,precio_pieza);
                                                                                                                                ELSE
                                                                                                                                    UPDATE order_request_details SET quantity = quantity + cantidad_pieza_preventivo WHERE order_request_id = solicitud_pedido AND item_id = item_pieza;
                                                                                                                                END IF;
                                                                                                                        END LOOP bucle_materiales;
                                                                                                                    CLOSE cursor_materiales_preventivo;
                                                                                                            /*------RESERTEAR CONTADOR MATERIALES---------------------------------------*/
                                                                                                                SELECT 0 INTO material_final;
                                                                                                            END;
                                                                                                    END LOOP bucle_pieza_tareas_preventino;
                                                                                                CLOSE cursor_pieza_tareas_preventivo;
                                                                                            /*----------------RESETEAR CONTADOR TAREAS----------------------------------------------*/
                                                                                                SELECT 0 INTO tarea_final;
                                                                                        END;
                                                                                END IF;
                                                                        END LOOP bucle_piezas;
                                                                    CLOSE cursor_piezas;
                                                                    /*--------RESETEAR CONTADOR DE PIEZAS-------------------------*/
                                                                        SELECT 0 INTO pieza_final;
                                                            END;
                                                    END LOOP bucle_componentes;
                                                CLOSE cursor_componentes;
                                            /*------------RESETEAR CONTADOR COMPONENTES-------------------*/
                                                SELECT 0 INTO componente_final;
                                        END;
                                END IF;
                        END LOOP bucle_implementos;
                    CLOSE cursor_implementos;
                /*---------RESETEAR CONTADOR IMPLEMENTOS---------------*/
                    SELECT 0 INTO implemento_final;
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
