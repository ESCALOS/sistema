-- Active: 1663248452468@@127.0.0.1@3306@sistema
BEGIN
        DECLARE dias_antes_del_aviso INT;
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
        DECLARE dias_para_el_matenimiento_preventivo_de_la_pieza INT;
        DECLARE codigo_de_la_pieza INT;
        DECLARE horas_de_la_ultimo_mantenimiento_de_la_pieza DECIMAL(8,2);
        DECLARE tarea_de_la_pieza INT;
    /*--------------------------INCIO DE RECORRIDO DE TODOS LOS IMPLEMENTOS----------------------------------------------------*/
        DECLARE lista_de_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id,ceco_id FROM implements;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET implemento_final = 1;
        SET dias_antes_del_aviso = 3;
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
                                SET dias_para_el_recambio_del_componente = FLOOR((tiempo_de_vida_del_componente - horas_del_componente) / 7);
                            /*-------------------HACER EN CASO SE NECESITE RECAMBO EN 3 DÍAS------------------------------------------------*/
                                IF (dias_para_el_recambio_del_componente <= dias_antes_del_aviso) THEN
                                    BEGIN
                                    /*----------OBTENER LA FECHA QUE FALTA PARA EL MATENIMIENTO---------------------------------------------*/
                                        SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_recambio_del_componente+1) day);
                                        IF NOT EXISTS (SELECT * FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE') THEN
                                            INSERT INTO work_orders (implement_id,user_id,date,location_id,ceco_id) VALUES (implemento,responsable,fecha,ubicacion,ceco);
                                        END IF;
                                        SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = 'PENDIENTE' LIMIT 1;
                                    /*--------OBTENER LA TAREA DE RECAMBIO PARA DICHO MATERIAL--------------*/
                                        SELECT id INTO tarea_del_componente,tipo_de_tarea FROM tasks WHERE component_id = componente AND type = 'RECAMBIO' LIMIT 1;
                                    /*-------SOLICITAR EL RECAMBIO DEL COMPONENTE---------------------------*/
                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE work_order_id = orden_de_trabajo AND task_id = tarea_del_componente) THEN
                                            INSERT INTO work_order_details(work_order_id,task_id,task_type,component_implement_id,component_id) VALUES(orden_de_trabajo,tarea_del_componente,'RECAMBIO',componente_del_implemento,componente);
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
                                    /*----------EN CASO LAS HORAS PASADAS DESDE EL ÚLTIMO MANTENIMIENTO SEAN MAYORES A LA FRECUENCIA--------*/
                                        IF (horas_del_componente - horas_del_ultimo_mantenimiento_preventivo_del_componente) > frecuencia THEN
                                            SET dias_para_el_matenimiento_preventivo_del_componente = 0;
                                        ELSE
                                            SET dias_para_el_matenimiento_preventivo_del_componente = FLOOR((horas_del_componente - horas_del_ultimo_mantenimiento_preventivo_del_componente)/frecuencia_del_componente);
                                        END IF;
                                    /*----------CALCULAR LOS DÍAS QUE LE FALTAN PARA SU MANTENIMIENTO PREVENTIVO----------------------------*/
                                        SET dias_para_el_matenimiento_preventivo_del_componente = FLOOR((horas_del_componente - horas_del_ultimo_mantenimiento_preventivo_del_componente)/frecuencia_del_componente);
                                    /*---------HACER SI ES NECESARIO EL MATENIMIENTO DEL COMPONENTE-----------------------------------------*/
                                        IF dias_para_el_matenimiento_preventivo_del_componente <= dias_antes_del_aviso THEN
                                            BEGIN
                                        /*-----OBTENER LA FECHA EN LA CUAL ES NECESARIA EL MANTENIMIENTO PREVENTIVO-------------------------*/
                                            SET fecha = DATE_ADD(CURDATE(),INTERVAL (dias_para_el_recambio_del_componente+1) day);
                                        /*----------------------------------------------------------------------*/

                                            END
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
                                                    /*INSERT INTO prueba(implemento,componente,pieza) VALUES (implemento,componente,pieza);*/
                                                END LOOP bucle_piezas_del_componente;
                                            CLOSE lista_de_las_piezas_del_componente;
                                            SET pieza_del_componente_final = 0;
                                        END;
                                    /*-----------------FIN DE RECORRIDO DE TODAS LAS PIEZAS DEL COMPONENTE DEL IMPLEMENTNTO---------------------------------------------*/
                                    END
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
