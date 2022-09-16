BEGIN
    /*-----------VARIABLES PARA DETENER LOS CICLOS------------------------------*/
        DECLARE implemento_final INT DEFAULT 0;
        DECLARE componente_final INT DEFAULT 0;
        DECLARE pieza_final INT DEFAULT 0;
        DECLARE tarea_final INT DEFAULT 0;
        DECLARE material_final INT DEFAULT 0;
    /*-----------VARIABLES PARA LA CABECERA DE LA ORDEN DE TRABAJO-------------------*/
        DECLARE implemento INT;
        DECLARE responsable INT;
        DECLARE dias_para_mantenimiento INT;
        DECLARE fecha DATE;
    /*-----------VARIABLES PARA EL DETALLE DE LA ORDEN DE TRABAJO--------------------*/
        DECLARE orden_de_trabajo INT;
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
                                        SELECT lifespan,frequency,item_id INTO tiempo_vida_componente,frecuencia_componente,item_componente FROM components WHERE id = componente;
                                    /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DEL COMPONENTE--------------------------------*/
                                        IF horas_componente > tiempo_vida_componente THEN
                                            /*-----------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS-----------------------------------*/
                                            SELECT tiempo_vida_componente INTO horas_componente;
                                        END IF;
                                    /*---------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE LOS 3 DÍAS SIGUIENTES--------------------------------------------*/
                                        SELECT FLOOR((horas_componente+21)/tiempo_vida_componente) INTO cantidad_componente_recambio;
                                    /*---------OBTENER HORAS DEL ÚLTIMO MANTENIMIENTO DEL COMPONENTE EN CASO HUBIERA-----------------------*/
                                        IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_implement_id = componente_del_implemento AND t.type = "PREVENTIVO") THEN
                                            SELECT component_hours INTO horas_ultimo_mantenimiento_componente FROM work_order_details WHERE component_implement_id = componente_del_implemento AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                        ELSE
                                            SELECT 0 INTO horas_ultimo_mantenimiento_componente;
                                        END IF;
                                    /*---------HACER EN CASO NECESITE RECAMBIO-------------------------------------------------------------*/
                                        IF cantidad_componente_recambio > 0 THEN
                                            IF cantidad_componente_recambio > 1 THEN
                                                SET dias_para_mantenimiento = 3;
                                            ELSE
                                                SET dias_para_mantenimiento = (tiempo_vida_componente - horas_componente)/7;
                                            END IF;
                                            SET fecha = DATE_ADD(CURDATE(),INTERVAL dias_para_mantenimiento day);
                                            /*---------HACER EN CASO ORDEN DE TRABAJO SI NO ESTÁ CREADA AÚN--------------------------------------*/
                                                IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE") THEN
                                                /*----------------------CREAR CABECERA DE LA ORDEN DE TRABAJO---------------------------------*/
                                                    INSERT INTO work_orders (user_id,implement_id,date) VALUES (responsable,implemento,fecha);
                                                /*----------------------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------------------------*/
                                                    SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE";
                                                END IF;
                                            /*---------OBTENER LA TAREA PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                SELECT id INTO tarea_componente FROM tasks WHERE component_id = componente AND type = "RECAMBIO" limit 1;
                                                IF NOT EXISTS(SELECT * FROM work_order_details WHERE task_id = tarea_componente AND work_order_id = orden_de_trabajo AND component_implement_id = componente_del_implemento) THEN
                                                    INSERT INTO work_order_details(work_order_id, task_id,component_implement_id, component_hours) VALUES (orden_de_trabajo, tarea_componente, componente_del_implemento, horas_componente);
                                                END IF;
                                        ELSE
                                        /*---------CALCULAR MANTENIMIENTO PREVENTIVOS----------------------------------------------------------*/
                                            SELECT (FLOOR(((horas_componente - horas_ultimo_mantenimiento_componente) + 21)/frecuencia_componente)) INTO cantidad_componente_preventivo;
                                        /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS---------------------------*/
                                            IF cantidad_componente_preventivo > 0 THEN
                                                IF cantidad_componente_preventivo > 1 THEN
                                                    SET dias_para_mantenimiento = 3;
                                                ELSE
                                                    SET dias_para_mantenimiento = (frecuencia_componente - (horas_componente - horas_ultimo_mantenimiento_componente))/7;
                                                END IF;
                                                SET fecha = DATE_ADD(CURDATE(),INTERVAL dias_para_mantenimiento day);
                                                /*---------HACER EN CASO ORDEN DE TRABAJO SI NO ESTÁ CREADA AÚN--------------------------------------*/
                                                    IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE") THEN
                                                        /*----------------------CREAR CABECERA DE LA ORDEN DE TRABAJO---------------------------------*/
                                                            INSERT INTO work_orders (user_id,implement_id,date) VALUES (responsable,implemento,fecha);
                                                        /*----------------------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------------------------*/
                                                            SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE" AND date = fecha;
                                                    END IF;
                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL MANTENIMIENTO PREVENTIVO DEL COMPONENTE-------------------------*/
                                                    BEGIN
                                                        DECLARE cursor_componente_tareas_preventivo CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "PREVENTIVO";
                                                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                        /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                            OPEN cursor_componente_tareas_preventivo;
                                                                bucle_componente_tareas_preventivo:LOOP
                                                                    /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                        IF tarea_final = 1 THEN
                                                                            LEAVE bucle_componente_tareas_preventivo;
                                                                        END IF;
                                                                    /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                        FETCH cursor_componente_tareas_preventivo INTO tarea_componente;
                                                                    /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE task_id = tarea_componente AND work_order_id = orden_de_trabajo AND component_implement_id = componente_del_implemento) THEN
                                                                            INSERT INTO work_order_details(work_order_id,task_id,component_implement_id,component_hours) VALUES (orden_de_trabajo,tarea_componente,componente_del_implemento,horas_componente);
                                                                        END IF;
                                                                END LOOP bucle_componente_tareas_preventivo;
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
                                                            /*---------OBTENER EL TIEMPO DE VIDA, LA FRECUENCIA Y EL ID DE LA PIEZA------------------------------*/
                                                                SELECT lifespan,frequency, item_id INTO tiempo_vida_pieza,frecuencia_pieza,item_pieza FROM components WHERE id = pieza;
                                                            /*---------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DE LA PIEZA------------------------------*/
                                                                IF horas_pieza >= tiempo_vida_pieza THEN
                                                                    /*---------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS----------*/
                                                                        SELECT tiempo_vida_pieza INTO horas_pieza;
                                                                END IF;
                                                            /*---------CALCULAR SI NECESITA RECAMBIO DENTRO DE 2 MESES----------------------------------------*/
                                                                SELECT FLOOR((horas_pieza+21)/tiempo_vida_pieza) INTO cantidad_pieza_recambio;
                                                            /*---------OBTENER HORAS DEL ÚLTIMO MATENIMIENTO DE LA PIEZA EN CASO HUBIERA----------------------*/
                                                                IF EXISTS(SELECT * FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1) THEN
                                                                    SELECT wod.component_hours INTO horas_ultimo_mantenimiento_pieza FROM work_order_details wod INNER JOIN tasks t ON t.id = wod.task_id WHERE wod.component_part_id = pieza_del_componente AND t.type = "PREVENTIVO" AND is_checked = 1 ORDER BY id DESC LIMIT 1;
                                                                ELSE
                                                                    SELECT 0 INTO horas_ultimo_mantenimiento_pieza;
                                                                END IF;
                                                            /*---------HACER EN CASO NECESITE RECAMBIO--------------------------------------------------------*/
                                                                IF(cantidad_pieza_recambio > 0) THEN
                                                                    IF cantidad_pieza_recambio > 1 THEN
                                                                        SET dias_para_mantenimiento = 3;
                                                                    ELSE
                                                                        SET dias_para_mantenimiento = (tiempo_vida_pieza - horas_pieza)/7;
                                                                    END IF;
                                                                    SET fecha = DATE_ADD(CURDATE(),INTERVAL dias_para_mantenimiento day);
                                                                    /*---------HACER EN CASO ORDEN DE TRABAJO SI NO ESTÁ CREADA AÚN--------------------------------------*/
                                                                        IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE") THEN
                                                                            /*----------------------CREAR CABECERA DE LA ORDEN DE TRABAJO---------------------------------*/
                                                                                INSERT INTO work_orders (user_id,implement_id,date) VALUES (responsable,implemento,fecha);
                                                                            /*----------------------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------------------------*/
                                                                                SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE" AND date = fecha;
                                                                        END IF;
                                                                    /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                        SELECT id INTO tarea_pieza FROM tasks WHERE component_id = pieza AND type = "RECAMBIO" limit 1;
                                                                        IF NOT EXISTS(SELECT * FROM work_order_details WHERE task_id = tarea_pieza AND work_order_id = orden_de_trabajo) THEN
                                                                            INSERT INTO work_order_details(work_order_id,task_id,component_part_id,component_hours) VALUES (orden_de_trabajo,tarea_pieza,pieza_del_componente,horas_pieza);
                                                                        END IF;
                                                                ELSE
                                                                    /*---------CALCULAR MANTENIMIENTO PREVENTIVOS-----------------------------------------------------*/
                                                                        SELECT (FLOOR(((horas_pieza - horas_ultimo_mantenimiento_pieza)+21)/frecuencia_pieza)) INTO cantidad_pieza_preventivo;
                                                                    /*---------HACER EN CASO NECESITE MATERIALES PARA MANTENIMIENTOS PREVENTIVOS----------------------*/
                                                                        IF cantidad_pieza_preventivo > 0 THEN
                                                                            IF cantidad_pieza_preventivo > 1 THEN
                                                                                SET dias_para_mantenimiento = 3;
                                                                            ELSE
                                                                                SET dias_para_mantenimiento = (frecuencia_pieza - (horas_pieza - horas_ultimo_mantenimiento_pieza))/7;
                                                                            END IF;
                                                                            SET fecha = DATE_ADD(CURDATE(),INTERVAL dias_para_mantenimiento day);
                                                                            /*---------HACER EN CASO ORDEN DE TRABAJO SI NO ESTÁ CREADA AÚN--------------------------------------*/
                                                                                IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE") THEN
                                                                                    /*----------------------CREAR CABECERA DE LA ORDEN DE TRABAJO---------------------------------*/
                                                                                        INSERT INTO work_orders (user_id,implement_id,date) VALUES (responsable,implemento,fecha);
                                                                                    /*----------------------OBTENER ID DE LA CABECERA DE LA ORDEN DE TRABAJO-------------------------------------*/
                                                                                        SELECT id INTO orden_de_trabajo FROM work_orders WHERE implement_id = implemento AND state = "PENDIENTE" AND date = fecha;
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
                                                                                                /*----------PONER TAREAS A LA ORDEN DE TRABAJO------------------------------*/
                                                                                                    IF NOT EXISTS(SELECT * FROM work_order_details WHERE task_id = tarea_pieza AND work_order_id = orden_de_trabajo AND component_implement_id = componente_del_implemento) THEN
                                                                                                        INSERT INTO work_order_details(work_order_id,task_id,component_implement_id,component_hours) VALUES (orden_de_trabajo,tarea_pieza,componente_del_implemento,horas_componente);
                                                                                                    END IF;
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
END;
