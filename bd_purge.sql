-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 09-11-2022 a las 08:51:27
-- Versión del servidor: 10.4.20-MariaDB
-- Versión de PHP: 8.0.8

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
CREATE DEFINER=`root`@`localhost` PROCEDURE `asignarMontoCeco` ()  UPDATE ceco_allocation_amounts SET is_allocated = true WHERE date <= CURDATE() AND is_allocated = false$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cerrarPedido` ()  BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `CerrarPreReserva` ()  BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_frecuencia_mantenimientos` ()  BEGIN
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_rutinario` ()  BEGIN
	DECLARE programacion_tractor INT;
    DECLARE implemento INT;
    DECLARE usuario INT;
	DECLARE programado_final INT DEFAULT 0;
    DECLARE cursor_programacion CURSOR FOR SELECT ts.id,ts.implement_id,ts.user_id FROM tractor_schedulings ts WHERE DATE(ts.date) = CURDATE();
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_mantenimientos_programados` ()  BEGIN
        DECLARE dias_antes_del_aviso INT DEFAULT 3;
    /*---------------------------VARIABLES PARA DETENER LOS CICLOS----------------------------------------------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_del_implemento_final INT DEFAULT 0;
        DECLARE pieza_del_componente_final INT DEFAULT 0;
        DECLARE tarea_final INT DEFAULT 0;
    /*---------------------------VARIABLES PARA LA CABECERA DE LA ORDEN DE TRABAJO----------------------------------------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        DECLARE fecha INT;
        DECLARE ubicacion INT;
        DECLARE ceco INT;
    /*---------------------------VARIABLES PARA EL DETALLE DE LA ORDEN DE TRABAJO----------------------------------------------------*/
        DECLARE orden_de_trabajo INT;
        DECLARE componente_del_implemento INT;
        DECLARE pieza_del_componente INT;
    /*---------------------------VARIABLES DEL MODELO DEL IMPLEMENTO PARA OBTENER SUS COMPONENTES----------------------------------------------------*/
        DECLARE modelo_del_implemento INT;
    /*---------------------------VARIABLES PARA ALMACENAR LOS DATOS DEL COMPONENTE----------------------------------------------------*/
        DECLARE componente INT;
        DECLARE horas_del_componente DECIMAL(8,2);
        DECLARE frecuencia_del_componente DECIMAL(8,2);
        DECLARE tiempo_de_vida_del_componente DECIMAL(8,2);
        DECLARE dias_para_el_recambio_del_componente INT;
        DECLARE dias_para_el_matenimiento_preventivo_del_componente INT;
        DECLARE codigo_del_componente INT;
        DECLARE horas_del_ultimo_mantenimiento_preventivo_del_componente DECIMAL(8,2);
        DECLARE tarea_del_componente INT;
    /*---------------------------VARIABLES PARA ALMACENAR LOS DATOS DE LA PIEZA----------------------------------------------------*/
        DECLARE pieza INT;
        DECLARE horas_de_la_pieza DECIMAL(8,2);
        DECLARE frecuencia_de_la_pieza DECIMAL(8,2);
        DECLARE tiempo_de_vida_de_la_pieza DECIMAL(8,2);
        DECLARE dias_para_el_recambio_de_la_pieza INT;
        DECLARE dias_para_el_mantenimiento_preventivo_de_la_pieza INT;
        DECLARE codigo_de_la_pieza INT;
        DECLARE horas_del_ultimo_mantenimiento_preventivo_de_la_pieza DECIMAL(8,2);
        DECLARE tarea_de_la_pieza INT;
    /*--------------------------INCIO DE RECORRIDO DE TODOS LOS IMPLEMENTOS----------------------------------------------------*/
        DECLARE lista_de_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id,ceco_id FROM implements;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        OPEN lista_de_implementos;
            bucle_implementos:LOOP
                    FETCH lista_de_implementos INTO implemento,modelo_del_implemento,responsable,ubicacion,ceco;
                    IF implemento_final THEN
                        LEAVE bucle_implementos;
                    END IF;
                /*-----------------INICIO DE RECORRIDO DE TODOS LOS COMPONENTES DEL IMPLEMENTO---------------------------------------------*/
                    BEGIN
                        DECLARE lista_de_componentes_del_implemento CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_del_implemento_final = 1;
                        OPEN lista_de_componentes_del_implemento;
                            bucle_componentes_del_implemento:LOOP
                                FETCH lista_de_componentes_del_implemento INTO componente;
                                IF componente_del_implemento_final THEN
                                    LEAVE bucle_componentes_del_implemento;
                                END IF;
                                IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento) THEN
                                    INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
                                END IF;
                            /*-------------------------OBTENER EL CODIGO DEL COMPONENTE, LA FRECUENCIA DE MANTENIMIENTO Y SU TIEMPO DE VIDA---------------------*/
                                SELECT item_id,frequency,lifespan INTO codigo_del_componente,frecuencia_del_componente,tiempo_de_vida_del_componente FROM components WHERE id = componente;
                            /*--------------------------OBTENER EL ID Y LAS HORAS DEL COMPONENTE DEL IMPLEMENTO--------------------------*/
                                SELECT id,hours INTO componente_del_implemento,horas_del_componente FROM component_implement WHERE implement_id = implemento AND component_id = componente;
                            /*--------------------------EN CASO LAS HORAS SEAN MAYORES AL TIEMPO DE VIDA, PONERLO COMO LAS HORAS---------*/
                                IF horas_del_componente > tiempo_de_vida_del_componente THEN
                                    SET horas_del_componente = tiempo_de_vida_del_componente;
                                END IF;
                            /*--------------------------CALCULAR EN CUÁNTOS DÍAS NECESITA CAMBIARSE EL COMPONENTE---------------------------*/
                                SET dias_para_el_recambio_del_componente = CEILING((tiempo_de_vida_del_componente - horas_del_componente) / 7);
                            /*-------------------HACER EN CASO SE NECESITE RECAMBO EN 3 DÍAS------------------------------------------------*/
                                IF (dias_para_el_recambio_del_componente <= dias_antes_del_aviso) THEN
                                    BEGIN
                                    /*----------OBTENER LA FECHA QUE FALTA PARA EL CAMBIO--------------------------------------------------*/
                                        SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_recambio_del_componente + 1) day);
                                        IF NOT EXISTS (SELECT * FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE') THEN
                                            INSERT INTO work_orders (implement_id,user_id,date,location_id,ceco_id) VALUES (implemento,responsable,fecha,ubicacion,ceco);
                                        END IF;
                                        SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE' ORDER BY id DESC LIMIT 1;
                                    /*--------OBTENER LA TAREA DE RECAMBIO PARA DICHO COMPONENTE--------------*/
                                        SELECT id INTO tarea_del_componente FROM tasks WHERE component_id = componente AND type = 'RECAMBIO' LIMIT 1;
                                    /*-------SOLICITAR EL RECAMBIO DEL COMPONENTE---------------------------*/
                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_de_trabajo AND task_id = tarea_del_componente) THEN
                                            INSERT INTO work_order_details(work_order_id,task_id,task_type,component_implement_id) VALUES(orden_de_trabajo,tarea_del_componente,'RECAMBIO',componente_del_implemento);
                                        ELSE
                                            UPDATE work_order_details SET quantity = quantity + 1 WHERE work_order_id = orden_de_trabajo AND task_id = tarea_del_componente AND component_implement_id = componente_del_implemento;
                                        END IF;
                                    END;
                            /*------------------DE LO CONTRARIO VERIFICAR SI NECESITA MANTENIMIENTO PREVENTIVO------------------------------*/
                                ELSE
                                    BEGIN
                                    /*----------OBTENER LAS HORAS DEL ÚLTIMO MANTENIMIENTO DEL COMPONENTE-----------------------------------*/
                                        IF EXISTS(SELECT * FROM work_order_details WHERE component_implement_id = componente_del_implemento AND task_type = 'PREVENTIVO') THEN
                                            SELECT component_hours INTO horas_del_ultimo_mantenimiento_preventivo_del_componente FROM work_order_details WHERE component_implement_id = componente_del_implemento AND task_type = 'PREVENTIVO' ORDER BY id DESC LIMIT 1;
                                        ELSE
                                            SET horas_del_ultimo_mantenimiento_preventivo_del_componente = 0;
                                        END IF;
                                    /*----------CALCULAR LOS DÍAS QUE LE FALTAN PARA SU MANTENIMIENTO PREVENTIVO----------------------------*/
                                        IF ((horas_del_componente - horas_del_ultimo_mantenimiento_preventivo_del_componente) > frecuencia_del_componente) THEN
                                            SET dias_para_el_matenimiento_preventivo_del_componente = 0;
                                        ELSE
                                            SET dias_para_el_matenimiento_preventivo_del_componente = CEILING((frecuencia_del_componente - (horas_del_componente - horas_del_ultimo_mantenimiento_preventivo_del_componente))/7);
                                        END IF;
                                    /*---------HACER SI ES NECESARIO EL MATENIMIENTO DEL COMPONENTE-----------------------------------------*/
                                        IF dias_para_el_matenimiento_preventivo_del_componente <= dias_antes_del_aviso THEN
                                            BEGIN
                                            /*-----OBTENER LA FECHA EN LA CUAL ES NECESARIA EL MANTENIMIENTO PREVENTIVO-------------------------*/
                                                SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_matenimiento_preventivo_del_componente + 1) day);
                                            /*----------------------------------------------------------------------*/
                                                IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE') THEN
                                                    INSERT INTO work_orders (implement_id,user_id,date,location_id,ceco_id) VALUES (implemento,responsable,fecha,ubicacion,ceco);
                                                END IF;
                                                SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE' LIMIT 1;
                                                BEGIN
                                                    DECLARE lista_de_las_tareas_para_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = 'PREVENTIVO';
                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                    OPEN lista_de_las_tareas_para_preventivo;
                                                        bucle_tareas:LOOP
                                                            FETCH lista_de_las_tareas_para_preventivo INTO tarea_del_componente;
                                                            IF tarea_final THEN
                                                                LEAVE bucle_tareas;
                                                            END IF;
                                                        /*-------INSERTAR LAS TAREAS AL DETALLE DE ORDEN DE TRABAJO------------------------------*/
                                                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_de_trabajo AND task_id = tarea_del_componente) THEN
                                                                INSERT INTO work_order_details(work_order_id,task_id,task_type,component_implement_id) VALUES (orden_de_trabajo,tarea_del_componente,'PREVENTIVO',componente_del_implemento);
                                                            ELSE
                                                                UPDATE work_order_details SET quantity = quantity + 1 WHERE work_order_id = orden_de_trabajo AND task_id = tarea_del_componente;
                                                            END IF;
                                                        END LOOP bucle_tareas;
                                                    CLOSE lista_de_las_tareas_para_preventivo;
                                                    SET tarea_final = 0;
                                                END;
                                            END;
                                        END IF;
                                    /*------------INICIO DE RECORRIDO DE TODOS LAS PIEZAS DEL COMPONENTE DEL IMPLEMENTO-----------------------------*/
                                        BEGIN
                                            DECLARE lista_de_las_piezas_del_componente CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_del_componente_final = 1;
                                            OPEN lista_de_las_piezas_del_componente;
                                                bucle_piezas_del_componente:LOOP
                                                    FETCH lista_de_las_piezas_del_componente INTO pieza;
                                                    IF pieza_del_componente_final THEN
                                                        LEAVE bucle_piezas_del_componente;
                                                    END IF;
                                                    IF NOT EXISTS(SELECT * FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza) THEN
                                                        INSERT INTO component_part(component_implement_id,part) VALUES (componente_del_implemento,pieza);
                                                    END IF;
                                                /*---------------------------OBTENER EL CÓDIGO DE LA PIEZA--------------------------------------------------------------*/
                                                    SELECT item_id,frequency,lifespan INTO codigo_de_la_pieza,frecuencia_de_la_pieza,tiempo_de_vida_de_la_pieza FROM components WHERE id = pieza;
                                                /*---------------------------OBTENER EL ID Y LAS HORAS DE LA PIEZA DEL COMPONENTE---------------------------------------*/
                                                    SELECT id, hours INTO pieza_del_componente,horas_de_la_pieza FROM component_part WHERE component_implement_id = componente_del_implemento AND part = pieza;
                                                /*--------------------------EN CASO LAS HORAS SEAN MAYORES AL TIEMPO DE VIDA, PONERLO COMO HORAS------------------------*/
                                                    IF horas_de_la_pieza > tiempo_de_vida_de_la_pieza THEN
                                                        SET horas_de_la_pieza = tiempo_de_vida_de_la_pieza;
                                                    END IF;
                                                /*-------------------------CALCULAR EN CUÁNTOS DÍAS NECESITA RECAMBIO LA PIEZA-------------------------------------------*/
                                                    SET dias_para_el_recambio_de_la_pieza = CEILING((tiempo_de_vida_de_la_pieza - horas_de_la_pieza)/7);
                                                /*-------------------------HACER EN CASO ESTE PROXIMO SU RECAMBIO--------------------------------------------------------*/
                                                    IF (dias_para_el_recambio_de_la_pieza <= dias_antes_del_aviso) THEN
                                                        BEGIN
                                                        /*-----------------OBTENER LA FECHA QUE FALTA PARA EL CAMBIO DE LA PIEZA-----------------------------------------*/
                                                            SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_recambio_de_la_pieza + 1) day);
                                                            IF NOT EXISTS (SELECT * FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE') THEN
                                                                INSERT INTO work_orders (implement_id,user_id,date,location_id,ceco_id) VALUES (implemento,responsable,fecha,ubicacion,ceco);
                                                            END IF;
                                                            SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE' ORDER BY id DESC LIMIT 1;
                                                        /*----------------OBTENER LA TAREA DE RECMABIO PARA DICHA PIEZA--------------------------------------------------*/
                                                            SELECT id INTO tarea_de_la_pieza FROM tasks WHERE component_id = pieza AND type = "RECAMBIO" LIMIT 1;
                                                        /*----------------SOLICITAR EL RECAMBIO DEL COMPONENTE-----------------------------------------------------------*/
                                                            IF NOT EXISTS (SELECT * FROM work_order_details WHERE work_order_id = orden_de_trabajo AND task_id = tarea_de_la_pieza) THEN
                                                                INSERT INTO work_order_details(work_order_id,task_id,task_type,component_part_id) VALUES (orden_de_trabajo,tarea_de_la_pieza,'RECAMBIO',pieza_del_componente);
                                                            ELSE
                                                                UPDATE work_order_details SET quantity = quantity + 1 WHERE work_order_id = orden_de_trabajo AND task_id = tarea_de_la_pieza AND component_part_id = pieza_del_componente;
                                                            END IF;
                                                        END;
                                                    ELSE
                                                        BEGIN
                                                        /*-----------------------------DE LO CONTRARIO VERIFICAR SI NECESITA MANTENIMIENTO PREVENTIVO-------------------*/
                                                            IF EXISTS (SELECT * FROM work_order_details WHERE component_part_id = pieza_del_componente AND task_type = 'PREVENTIVO') THEN
                                                                SELECT component_hours INTO horas_del_ultimo_mantenimiento_preventivo_de_la_pieza FROM work_order_details WHERE component_part_id = pieza_del_componente AND task_type = 'PREVENTIVO' ORDER BY id DESC LIMIT 1;
                                                            ELSE
                                                                SET horas_del_ultimo_mantenimiento_preventivo_de_la_pieza = 0;
                                                            END IF;
                                                        /*----------------------------CALCULAR LOS DÍAS QUE LE FALTAN PARA SU MANTENIMIENTO PREVENTIVO------------------*/
                                                            IF ((horas_de_la_pieza - horas_del_ultimo_mantenimiento_preventivo_del_componente) > frecuencia_de_la_pieza) THEN
                                                                SET dias_para_el_mantenimiento_preventivo_de_la_pieza = 0;
                                                            ELSE
                                                                SET dias_para_el_mantenimiento_preventivo_de_la_pieza = CEILING((frecuencia_de_la_pieza - (horas_de_la_pieza - horas_del_ultimo_mantenimiento_preventivo_de_la_pieza))/7);
                                                            END IF;
                                                        /*---------------------------HACER SI ES NECESARIO EL MANTENIMIENTO DE LA PIEZA---------------------------------*/
                                                            IF dias_para_el_mantenimiento_preventivo_de_la_pieza <= dias_antes_del_aviso THEN
                                                                BEGIN
                                                                /*-------------------OBTENER LA FECHA EN LA CUAL ES NECESARIA EL MANTENIMIENTO PREVENTIVO---------------*/
                                                                    SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_mantenimiento_preventivo_de_la_pieza + 1) day);
                                                                /*--------------------------------------------------------------------------------------------------*/
                                                                    IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE') THEN
                                                                        INSERT INTO work_orders (implement_id,user_id,date,location_id,ceco_id) VALUES (implemento,responsable,fecha,ubicacion,ceco);
                                                                    END IF;
                                                                    SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE' ORDER BY id DESC LIMIT 1;
                                                                    BEGIN
                                                                        DECLARE lista_de_las_tareas_para_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND type = 'PREVENTIVO';
                                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                        OPEN lista_de_las_tareas_para_preventivo;
                                                                            bucle_tareas:LOOP
                                                                                FETCH lista_de_las_tareas_para_preventivo INTO tarea_de_la_pieza;
                                                                                IF tarea_final THEN
                                                                                    LEAVE bucle_tareas;
                                                                                END IF;
                                                                            /*----------INSERTAR LAS TAREAS AL DETALLE DE ORDEN DE TRABAJO-------------------------*/
                                                                                IF NOT EXISTS (SELECT * FROM work_order_details WHERE work_order_id = orden_de_trabajo AND task_id = tarea_de_la_pieza AND component_part_id = pieza_del_componente) THEN
                                                                                    INSERT INTO work_order_details(work_order_id,task_id,task_type,component_part_id) VALUES (orden_de_trabajo,tarea_de_la_pieza,'PREVENTIVO',pieza_del_componente);
                                                                                ELSE
                                                                                    UPDATE work_order_details SET quantity = quantity + 1 WHERE work_order_id = orden_de_trabajo AND task_id = tarea_de_la_pieza;
                                                                                END IF;
                                                                            END LOOP bucle_tareas;
                                                                        CLOSE lista_de_las_tareas_para_preventivo;
                                                                        SET tarea_final = 0;
                                                                    END;
                                                                END;
                                                            END IF;
                                                        END;
                                                    END IF;
                                                END LOOP bucle_piezas_del_componente;
                                            CLOSE lista_de_las_piezas_del_componente;
                                            SET pieza_del_componente_final = 0;
                                        END;
                                    /*-----------------FIN DE RECORRIDO DE TODAS LAS PIEZAS DEL COMPONENTE DEL IMPLEMENTNTO---------------------------------------------*/
                                    END;
                                END IF;
                            END LOOP bucle_componentes_del_implemento;
                        CLOSE lista_de_componentes_del_implemento;
                        SET componente_del_implemento_final = 0;
                    END;
                /*-----------------FIN DE RECORRIDO DE TODOS LOS COMPONENTES DEL IMPLEMENTO---------------------------------------------*/
            END LOOP bucle_implementos;
        CLOSE lista_de_implementos;
        SET implemento_final = 0;
    /*--------------------------FIN DE RECORRIDO DE TODOS LOS IMPLEMENTOS----------------------------------------------------*/
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_materiales_pedido` ()  BEGIN
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
                                                                    SELECT (FLOOR(((horas_componenete - horas_ultimo_mantenimiento_componente)+336)/frecuencia_componente) ) INTO cantidad_componente_preventivo;
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
                                                                                        SELECT (FLOOR(((horas_pieza - horas_ultimo_mantenimiento_pieza)+336)/frecuencia_pieza)) INTO cantidad_pieza_preventivo;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `Listar_prereserva` ()  BEGIN
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
                                                        /*---------HACER EN CASO LA PRE-RESERVA SI NO ESTÁ CREADA AÚN---------------*/
                                                            IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva) THEN
                                                                /*----------------------CREAR CABECERA DE LA PRE-RESERVA---------------------------------*/
                                                                    INSERT INTO pre_stockpiles (user_id,implement_id,pre_stockpile_date_id) VALUES (responsable,implemento,fecha_pre_reserva);
                                                                /*----------------------OBTENER ID DE LA CABECERA DE LA PRE-RESERVA-------------------------------------*/
                                                                    SELECT id INTO pre_reserva FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva;
                                                            END IF;
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
                                                    ELSE
                                                        /*---------CALCULAR MANTENIMIENTO PREVENTIVOS----------------------------------------------------------*/
                                                            SELECT (FLOOR((horas_componente - horas_ultimo_mantenimiento_componente+168)/frecuencia_componente)) INTO cantidad_componente_preventivo;
                                                        /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------------*/
                                                            IF cantidad_componente_preventivo > 0 THEN
                                                                /*---------HACER EN CASO LA PRE-RESERVA SI NO ESTÁ CREADA AÚN---------------*/
                                                                    IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva) THEN
                                                                        /*----------------------CREAR CABECERA DE LA PRE-RESERVA---------------------------------*/
                                                                            INSERT INTO pre_stockpiles (user_id,implement_id,pre_stockpile_date_id) VALUES (responsable,implemento,fecha_pre_reserva);
                                                                        /*----------------------OBTENER ID DE LA CABECERA DE LA PRE-RESERVA-------------------------------------*/
                                                                            SELECT id INTO pre_reserva FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva;
                                                                    END IF;
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
                                                                                        /*---------HACER EN CASO LA PRE-RESERVA SI NO ESTÁ CREADA AÚN---------------*/
                                                                                            IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva) THEN
                                                                                                /*----------------------CREAR CABECERA DE LA PRE-RESERVA---------------------------------*/
                                                                                                    INSERT INTO pre_stockpiles (user_id,implement_id,pre_stockpile_date_id) VALUES (responsable,implemento,fecha_pre_reserva);
                                                                                                /*----------------------OBTENER ID DE LA CABECERA DE LA PRE-RESERVA-------------------------------------*/
                                                                                                    SELECT id INTO pre_reserva FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva;
                                                                                            END IF;
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
                                                                                ELSE
                                                                                    /*---------CALCULAR MANTENIMIENTO PREVENTIVOS-----------------------------------------------------*/
                                                                                        SELECT (FLOOR((horas_pieza - horas_ultimo_mantenimiento_pieza+168)/frecuencia_pieza)) INTO cantidad_pieza_preventivo;
                                                                                    /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS----------------------*/
                                                                                        IF cantidad_pieza_preventivo > 0 THEN
                                                                                            /*---------HACER EN CASO LA PRE-RESERVA SI NO ESTÁ CREADA AÚN---------------*/
                                                                                                IF NOT EXISTS(SELECT * FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva) THEN
                                                                                                    /*----------------------CREAR CABECERA DE LA PRE-RESERVA---------------------------------*/
                                                                                                        INSERT INTO pre_stockpiles (user_id,implement_id,pre_stockpile_date_id) VALUES (responsable,implemento,fecha_pre_reserva);
                                                                                                    /*----------------------OBTENER ID DE LA CABECERA DE LA PRE-RESERVA-------------------------------------*/
                                                                                                        SELECT id INTO pre_reserva FROM pre_stockpiles WHERE implement_id = implemento AND state = "PENDIENTE" AND pre_stockpile_date_id = fecha_pre_reserva;
                                                                                                END IF;
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
                        END LOOP bucle_implementos;
                    CLOSE cursor_implementos;
                /*---------RESETEAR CONTADOR IMPLEMENTOS---------------*/
                    SELECT 0 INTO implemento_final;
                /*---------ABRIR PRE-RESERVA-------------------*/
                    UPDATE pre_stockpile_dates SET state = "ABIERTO" WHERE id = fecha_pre_reserva;
            END;
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `rutinario` (IN `fecha` DATE, IN `responsable` BIGINT(20) UNSIGNED)  BEGIN
    IF EXISTS(SELECT * FROM tractor_schedulings ts WHERE ts.date = fecha) THEN
        BEGIN
            DECLARE programacion_tractor INT;
            DECLARE implemento INT;
            DECLARE usuario INT;
            DECLARE programado_final INT DEFAULT 0;
            DECLARE cursor_programacion CURSOR FOR SELECT ts.id,ts.implement_id,ts.user_id FROM tractor_schedulings ts WHERE ts.date = fecha AND ts.is_canceled = 0 AND ts.validated_by = responsable;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET programado_final = 1;
                OPEN cursor_programacion;
                    bucle_programacion:LOOP
                        IF programado_final = 1 THEN
                            LEAVE bucle_programacion;
                        END IF;
                        FETCH cursor_programacion INTO programacion_tractor,implemento,usuario;
            			DELETE FROM routine_tasks WHERE tractor_scheduling_id = programacion_tractor;
                        IF NOT EXISTS(SELECT * FROM routine_tasks WHERE tractor_scheduling_id = programacion_tractor) THEN
                            INSERT INTO routine_tasks (tractor_scheduling_id, implement_id, user_id, date) VALUES (programacion_tractor,implemento,usuario,fecha);
                        END IF;
                    END LOOP bucle_programacion;
                CLOSE cursor_programacion;
        END;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cecos`
--

CREATE TABLE `cecos` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(8,2) NOT NULL DEFAULT 0.00,
  `warehouse_amount` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cecos`
--

INSERT INTO `cecos` (`id`, `code`, `description`, `location_id`, `amount`, `warehouse_amount`, `created_at`, `updated_at`) VALUES
(18, '8091100104', NULL, 14, '0.00', '0.00', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(19, '8091100108', NULL, 14, '0.00', '0.00', '2022-10-05 00:10:18', '2022-10-05 00:10:18');

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
  `frequency` decimal(8,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_implement_model`
--

CREATE TABLE `component_implement_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `implement_model_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `component_part_model`
--

CREATE TABLE `component_part_model` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `component` bigint(20) UNSIGNED NOT NULL,
  `part` bigint(20) UNSIGNED NOT NULL
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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epp_risk`
--

CREATE TABLE `epp_risk` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED NOT NULL,
  `risk_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `epp_work_order`
--

CREATE TABLE `epp_work_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `epp_id` bigint(20) UNSIGNED DEFAULT NULL,
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
(17, 7, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(18, 7, '2', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(19, 7, '3', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(20, 8, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(21, 9, '1', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(22, 10, '1', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(23, 10, '2', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(24, 10, '3', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(25, 10, '4', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(26, 11, '1', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(27, 12, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(28, 13, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(29, 14, '1', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(30, 15, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(31, 16, '1', '0.00', 180, 14, 18, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(32, 17, '1', '0.00', 180, 14, 19, '2022-10-05 00:10:18', '2022-10-05 00:10:18');

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
(7, 'FEDE', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(8, 'CURTEC', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(9, 'PICADORA', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(10, 'CARRETA', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(11, 'SUBSOLADO', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(12, 'CISTERNA ', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(13, 'JACTO 2000', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(14, 'RUFA ESP N°1', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(15, 'JACTO CONDOR 600', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(16, 'JACTO ARBUS - TOWER', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(17, 'ARADO', '2022-10-05 00:10:18', '2022-10-05 00:10:18');

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
  `code` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `location` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sede_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `locations`
--

INSERT INTO `locations` (`id`, `code`, `location`, `sede_id`) VALUES
(14, '01', 'SANTA LUISA', 5),
(15, '02', 'PARACAS', 6);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lotes`
--

CREATE TABLE `lotes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lote` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ha` decimal(8,0) NOT NULL DEFAULT 0,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(1, 'UNIDAD', 'UN', '2022-10-06 10:53:31', '2022-10-06 10:53:31');

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
(1, 'App\\Models\\User', 41),
(2, 'App\\Models\\User', 41),
(2, 'App\\Models\\User', 180),
(3, 'App\\Models\\User', 179),
(3, 'App\\Models\\User', 188),
(3, 'App\\Models\\User', 189),
(3, 'App\\Models\\User', 190),
(3, 'App\\Models\\User', 191),
(3, 'App\\Models\\User', 192),
(4, 'App\\Models\\User', 41),
(4, 'App\\Models\\User', 180),
(5, 'App\\Models\\User', 180),
(5, 'App\\Models\\User', 188),
(7, 'App\\Models\\User', 181),
(7, 'App\\Models\\User', 182),
(7, 'App\\Models\\User', 183),
(7, 'App\\Models\\User', 184),
(7, 'App\\Models\\User', 185),
(7, 'App\\Models\\User', 186),
(7, 'App\\Models\\User', 187);

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `overseer_locations`
--

CREATE TABLE `overseer_locations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL
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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `risk_task_order`
--

CREATE TABLE `risk_task_order` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `risk_id` bigint(20) UNSIGNED NOT NULL,
  `task_id` bigint(20) UNSIGNED NOT NULL
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
(6, 'jefe', 'web', '2022-06-20 21:43:35', '2022-06-20 21:43:35'),
(7, 'tractorista', 'web', '2022-06-20 21:43:35', '2022-06-20 21:43:35');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `role_has_permissions`
--

CREATE TABLE `role_has_permissions` (
  `permission_id` bigint(20) UNSIGNED NOT NULL,
  `role_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(5, '01', 'CHINCHA', 1, '2022-09-21 16:48:48', '2022-09-21 16:48:48'),
(6, '02', 'PARACAS', 1, '2022-09-21 16:48:48', '2022-09-21 16:48:48');

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
('jy3VFpR4fQf5anljTonXTWBGXlAcvTs8vlV2tfRD', 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoibERqRUhQRm9LMHJCWVkxSVRCMEVGNVF1cTBQbVl6aU16djZhMEVKUyI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6NDE6Imh0dHA6Ly9sb2NhbGhvc3Qvc2lzdGVtYS9wdWJsaWMvYXNpc3RlbnRlIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NDE7fQ==', 1667510906),
('MdZAEJnBCIjmHmEYBQIytoUNmKJOI4QFm3tMJuWB', 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoiaGNJM0tqM1BpTU1qQmJMbVlHRDlJZGVkSGZvakQ3QUpRTlptbDR2YSI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjQxOiJodHRwOi8vbG9jYWxob3N0L3Npc3RlbWEvcHVibGljL2FzaXN0ZW50ZSI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fXM6NTA6ImxvZ2luX3dlYl81OWJhMzZhZGRjMmIyZjk0MDE1ODBmMDE0YzdmNThlYTRlMzA5ODlkIjtpOjQxO30=', 1667592484),
('plqINxCqu6hKvJ7YBZ12MQIAhhsoSJqq4d7sLDZZ', 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.24', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoickw5WWVoemRINXFMNnJEeW1MN0VUWHFsOGp3REYybm9lMTEzTndZTCI7czo5OiJfcHJldmlvdXMiO2E6MTp7czozOiJ1cmwiO3M6Mzc6Imh0dHA6Ly9sb2NhbGhvc3Qvc2lzdGVtYS9wdWJsaWMvYWRtaW4iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX1zOjUwOiJsb2dpbl93ZWJfNTliYTM2YWRkYzJiMmY5NDAxNTgwZjAxNGM3ZjU4ZWE0ZTMwOTg5ZCI7aTo0MTt9', 1667092195),
('wRMqN5v0kJhuXavoLm1KUt4lCiLSZCoKdMSh78Op', 41, '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.24', 'YTo1OntzOjY6Il90b2tlbiI7czo0MDoibGl2OXJNNHRJRWhLRlhyS1NCemFMTlZ2a1FONHczRENRZ1o2WFBobyI7czozOiJ1cmwiO2E6MDp7fXM6OToiX3ByZXZpb3VzIjthOjE6e3M6MzoidXJsIjtzOjM3OiJodHRwOi8vbG9jYWxob3N0L3Npc3RlbWEvcHVibGljL2FkbWluIjt9czo2OiJfZmxhc2giO2E6Mjp7czozOiJvbGQiO2E6MDp7fXM6MzoibmV3IjthOjA6e319czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6NDE7fQ==', 1667162617);

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tasks`
--

CREATE TABLE `tasks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `task` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_time` decimal(8,2) NOT NULL,
  `type` enum('RUTINARIO','PREVENTIVO','CORRECTIVO','RECAMBIO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RUTINARIO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tool_for_location`
--

CREATE TABLE `tool_for_location` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `measurement_unit_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
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
  `motor` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `serie` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hour_meter` decimal(8,2) NOT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractors`
--

INSERT INTO `tractors` (`id`, `tractor_model_id`, `tractor_number`, `motor`, `serie`, `hour_meter`, `location_id`, `created_at`, `updated_at`) VALUES
(29, 14, '3', 'RR60151B593917G', '4283623583', '0.00', 14, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(30, 14, '4', 'RR60151B593916G', '4283623038', '0.00', 14, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(31, 14, '5', 'RRG0151B594017G', '4283622292', '0.00', 14, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(32, 15, '1', 'M5D495001', 'TABMC180PM5351019', '0.00', 15, '2022-10-05 00:10:18', '2022-10-05 00:10:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tractor_models`
--

CREATE TABLE `tractor_models` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tractor_model` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tractor_models`
--

INSERT INTO `tractor_models` (`id`, `tractor_model`, `model`, `created_at`, `updated_at`) VALUES
(14, 'MASSEY FERGUSON ', '4283/4F', '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(15, 'MASSEY FERGUSON ', '6711', '2022-10-05 00:10:18', '2022-10-05 00:10:18');

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
  `validated_by` bigint(20) UNSIGNED NOT NULL,
  `is_canceled` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dni` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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

INSERT INTO `users` (`id`, `code`, `dni`, `name`, `lastname`, `location_id`, `email`, `email_verified_at`, `password`, `two_factor_secret`, `two_factor_recovery_codes`, `two_factor_confirmed_at`, `is_admin`, `remember_token`, `current_team_id`, `profile_photo_path`, `created_at`, `updated_at`) VALUES
(41, '419738', '70821326', 'CARLOS DANIEL', 'ESCATE ROMÁN', 14, NULL, '2022-09-21 18:49:12', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL),
(179, '341929', '47828986', 'RONALD LEONARDO', 'ALMEYDA NAPA', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(180, '442479', '71883064', 'GIOVANNI DUVAN', 'LURITA MENDOZA', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(181, '457208', '42598148', 'LUIS EDUARDO', 'MORON PALACIOS', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(182, '36816', '45856807', 'LORENZO', 'SANCHEZ CASTILLON', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(183, '48665', '21820182', 'JESUS ERNESTOR', 'FELIPA ATUNCAR', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(184, '33057', '40907813', 'TEODORO JUAN', 'RAMOS TASAYCO', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(185, '44391267', '44391267', 'JUAN CARLOS', 'QUISPE SANCHEZ', 15, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(186, '70774404', '70774404', 'EDSON MANUEL', 'HUAMAN HUILLCAS', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(187, '72255755', '72255755', 'JOHEL', 'JANAMPA TORRES', 15, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-05 00:10:18', '2022-10-05 00:10:18'),
(188, '419739', '23232323', 'CARLOS ESCATE', 'ESCATE CARLOS', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-29 04:14:59', '2022-10-29 04:14:59'),
(189, '419740', '23232323', 'rod', 'perez', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-29 06:01:46', '2022-10-29 06:01:46'),
(190, '419741', '23232323', 'rod', 'perez', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-29 06:02:59', '2022-10-29 06:02:59'),
(191, '419742', '33', 'rod', 'perez', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-29 06:03:54', '2022-10-29 06:03:54'),
(192, '419743', '44', 'rad', 'dominguz', 14, NULL, NULL, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, NULL, NULL, 0, NULL, NULL, NULL, '2022-10-29 06:03:54', '2022-10-29 06:03:54');

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

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `work_orders`
--

CREATE TABLE `work_orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `implement_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `state` enum('PENDIENTE','VALIDADO','CONCLUIDO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDIENTE',
  `validated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `location_id` bigint(20) UNSIGNED NOT NULL,
  `ceco_id` bigint(20) UNSIGNED NOT NULL,
  `estimated_time` decimal(8,2) DEFAULT NULL,
  `start_time` decimal(8,2) DEFAULT NULL,
  `end_time` decimal(8,2) DEFAULT NULL,
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
  `task_id` bigint(20) UNSIGNED DEFAULT NULL,
  `task_type` enum('RUTINARIO','PREVENTIVO','CORRECTIVO','RECAMBIO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PREVENTIVO',
  `state` enum('ACEPTADO','RECHAZADO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACEPTADO',
  `is_checked` tinyint(1) NOT NULL DEFAULT 0,
  `component_implement_id` bigint(20) UNSIGNED DEFAULT NULL,
  `component_part_id` bigint(20) UNSIGNED DEFAULT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `component_hours` decimal(8,2) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
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
CREATE TRIGGER `insert_orden_trabajo` AFTER UPDATE ON `work_order_details` FOR EACH ROW BEGIN
/*----------VARIABLE PARA DETENER CICLO DE EPPS----------*/
DECLARE epp_final INT DEFAULT 0;
/*----------VARIABLE PARA LA TAREA ASIGNADA---------------*/
DECLARE tarea VARCHAR(255);
/*----------VARIABLE PARA EL EPP--------------------------*/
DECLARE equipo_proteccion INT;
/*----------OBTENER NOMBRE DE LA TAREA--------------------*/
SELECT task INTO tarea FROM tasks WHERE id = 99;
/*-----------AGREGAR EPPS NECESARIOS PARA LA ORDEN DE TRABAJO----------*/
    /*-----------Obtener los epp según el riesgo--------------------------*/
	IF EXISTS(SELECT * FROM risk_task_order rt INNER JOIN epp_risk er ON er.risk_id = rt.risk_id WHERE rt.task_id = new.task_id) THEN
    BEGIN
		DECLARE cur_epp CURSOR FOR SELECT er.epp_id FROM risk_task_order rt INNER JOIN epp_risk er ON er.risk_id = rt.risk_id WHERE rt.task_id = new.task_id;
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
    END IF;
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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `componentes_del_implemento`  AS SELECT `c`.`id` AS `component_id`, `it`.`sku` AS `sku`, `c`.`item_id` AS `item_id`, `c`.`component` AS `item`, `i`.`id` AS `implement_id` FROM (((`components` `c` join `component_implement_model` `cim` on(`c`.`id` = `cim`.`component_id`)) join `implements` `i` on(`i`.`implement_model_id` = `cim`.`implement_model_id`)) join `items` `it` on(`it`.`id` = `c`.`item_id`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `lista_de_materiales_pedidos`
--
DROP TABLE IF EXISTS `lista_de_materiales_pedidos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_de_materiales_pedidos`  AS SELECT `o`.`id` AS `order_request_id`, `u`.`id` AS `user_id`, `ord`.`id` AS `id`, `it`.`sku` AS `sku`, `it`.`item` AS `item`, `it`.`type` AS `type`, `ord`.`quantity` AS `quantity`, `mu`.`abbreviation` AS `abbreviation`, ifnull(`os`.`ordered_quantity`,0) AS `ordered_quantity`, ifnull(`os`.`used_quantity`,0) AS `used_quantity`, ifnull(`gs`.`quantity`,0) AS `stock`, `ord`.`state` AS `state` FROM ((((((((`order_request_details` `ord` join `order_requests` `o` on(`o`.`id` = `ord`.`order_request_id`)) join `users` `u` on(`u`.`id` = `o`.`user_id`)) join `locations` `l` on(`l`.`id` = `u`.`location_id`)) join `sedes` `s` on(`s`.`id` = `l`.`sede_id`)) join `items` `it` on(`it`.`id` = `ord`.`item_id`)) join `measurement_units` `mu` on(`mu`.`id` = `it`.`measurement_unit_id`)) left join `operator_stocks` `os` on(`os`.`user_id` = `u`.`id` and `os`.`item_id` = `it`.`id`)) left join `general_stocks` `gs` on(`gs`.`item_id` = `it`.`id` and `gs`.`sede_id` = `s`.`id`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `lista_de_materiales_pedidos_pendientes`
--
DROP TABLE IF EXISTS `lista_de_materiales_pedidos_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_de_materiales_pedidos_pendientes`  AS SELECT `o`.`id` AS `order_request_id`, `u`.`id` AS `user_id`, `ord`.`id` AS `id`, `it`.`sku` AS `sku`, `it`.`item` AS `item`, `it`.`type` AS `type`, `ord`.`quantity` AS `quantity`, `mu`.`abbreviation` AS `abbreviation`, ifnull(`os`.`ordered_quantity`,0) AS `ordered_quantity`, ifnull(`os`.`used_quantity`,0) AS `used_quantity`, ifnull(`gs`.`quantity`,0) AS `stock` FROM ((((((((`order_request_details` `ord` join `order_requests` `o` on(`o`.`id` = `ord`.`order_request_id`)) join `users` `u` on(`u`.`id` = `o`.`user_id`)) join `locations` `l` on(`l`.`id` = `u`.`location_id`)) join `sedes` `s` on(`s`.`id` = `l`.`sede_id`)) join `items` `it` on(`it`.`id` = `ord`.`item_id`)) join `measurement_units` `mu` on(`mu`.`id` = `it`.`measurement_unit_id`)) left join `operator_stocks` `os` on(`os`.`user_id` = `u`.`id` and `os`.`item_id` = `it`.`id`)) left join `general_stocks` `gs` on(`gs`.`item_id` = `it`.`id` and `gs`.`sede_id` = `s`.`id`)) WHERE `ord`.`state` = 'PENDIENTE' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `lista_mantenimiento`
--
DROP TABLE IF EXISTS `lista_mantenimiento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lista_mantenimiento`  AS SELECT `wod`.`work_order_id` AS `work_order_id`, `t`.`task` AS `task`, ifnull((select `c`.`component` from (`component_implement` `ci` join `components` `c` on(`c`.`id` = `ci`.`component_id`)) where `ci`.`id` = `wod`.`component_implement_id`),(select `c`.`component` from ((`component_part` `cp` join `component_implement` `ci` on(`ci`.`id` = `cp`.`component_implement_id`)) join `components` `c` on(`c`.`id` = `cp`.`part`)) where `cp`.`id` = `wod`.`component_part_id`)) AS `componente`, ifnull((select `p`.`component` from (`component_part` `cp` join `components` `p` on(`p`.`id` = `cp`.`part`)) where `cp`.`id` = `wod`.`component_part_id`),'GENERAL') AS `pieza` FROM (`work_order_details` `wod` join `tasks` `t` on(`wod`.`task_id` = `t`.`id`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `pieza_simplificada`
--
DROP TABLE IF EXISTS `pieza_simplificada`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `pieza_simplificada`  AS SELECT `it`.`sku` AS `sku`, `p`.`item_id` AS `item_id`, `p`.`component` AS `part`, `c`.`item_id` AS `component_id` FROM (((`component_part_model` `cpm` join `components` `c` on(`c`.`id` = `cpm`.`component`)) join `components` `p` on(`p`.`id` = `cpm`.`part`)) join `items` `it` on(`it`.`id` = `p`.`item_id`)) ;

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
  ADD KEY `locations_sede_id_foreign` (`sede_id`);

--
-- Indices de la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD PRIMARY KEY (`id`),
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
-- Indices de la tabla `overseer_locations`
--
ALTER TABLE `overseer_locations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `location_id` (`location_id`),
  ADD KEY `user_id` (`user_id`);

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
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`),
  ADD KEY `location_id` (`location_id`),
  ADD KEY `user_id` (`user_id`);

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
  ADD KEY `work_orders_user_id_foreign` (`user_id`),
  ADD KEY `location_id` (`location_id`),
  ADD KEY `ceco_id` (`ceco_id`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=183;

--
-- AUTO_INCREMENT de la tabla `component_implement_model`
--
ALTER TABLE `component_implement_model`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT de la tabla `component_part`
--
ALTER TABLE `component_part`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=400;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT de la tabla `epp_work_order`
--
ALTER TABLE `epp_work_order`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1659;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `implement_models`
--
ALTER TABLE `implement_models`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `lotes`
--
ALTER TABLE `lotes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `measurement_units`
--
ALTER TABLE `measurement_units`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=168;

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
-- AUTO_INCREMENT de la tabla `overseer_locations`
--
ALTER TABLE `overseer_locations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=89;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT de la tabla `routine_tasks`
--
ALTER TABLE `routine_tasks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=230;

--
-- AUTO_INCREMENT de la tabla `routine_task_details`
--
ALTER TABLE `routine_task_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2544;

--
-- AUTO_INCREMENT de la tabla `sedes`
--
ALTER TABLE `sedes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=127;

--
-- AUTO_INCREMENT de la tabla `task_required_materials`
--
ALTER TABLE `task_required_materials`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT de la tabla `tool_for_location`
--
ALTER TABLE `tool_for_location`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `tractors`
--
ALTER TABLE `tractors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT de la tabla `tractor_models`
--
ALTER TABLE `tractor_models`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT de la tabla `tractor_reports`
--
ALTER TABLE `tractor_reports`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `tractor_schedulings`
--
ALTER TABLE `tractor_schedulings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=56;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=193;

--
-- AUTO_INCREMENT de la tabla `warehouses`
--
ALTER TABLE `warehouses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `work_orders`
--
ALTER TABLE `work_orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT de la tabla `work_order_details`
--
ALTER TABLE `work_order_details`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=404;

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
-- Filtros para la tabla `overseer_locations`
--
ALTER TABLE `overseer_locations`
  ADD CONSTRAINT `overseer_locations_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `overseer_locations_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

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
-- Filtros para la tabla `tool_for_location`
--
ALTER TABLE `tool_for_location`
  ADD CONSTRAINT `tool_for_location_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
  ADD CONSTRAINT `tool_for_location_ibfk_2` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `tool_for_location_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

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
  ADD CONSTRAINT `work_orders_ibfk_1` FOREIGN KEY (`location_id`) REFERENCES `locations` (`id`),
  ADD CONSTRAINT `work_orders_ibfk_2` FOREIGN KEY (`ceco_id`) REFERENCES `cecos` (`id`),
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
