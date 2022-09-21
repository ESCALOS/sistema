-- Active: 1663248452468@@127.0.0.1@3306@sistema
BEGIN
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
END
