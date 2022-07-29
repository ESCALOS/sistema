BEGIN
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
                                                                                                        /*----------OBTENER EL MATERIAL DE LA TAREA-----------------------------*/
                                                                                                            FETCH cursor_materiales_preventivo INTO item_componente,cantidad_componente_preventivo;
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
                                                                                                                                        INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_recambio,precio_pieza);
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
                                                                                                                                    INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_pieza,cantidad_pieza_preventivo,precio_pieza);
                                                                                                                                ELSE
                                                                                                                                    UPDATE order_request_details SET quantity = quantity + cantidad_pieza_preventivo WHERE order_request_id = solicitud_pedido AND item_id = item_pieza;
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
                /*---------ABRIR SOLICITUD DE PEDIDO-------------------*/
                    UPDATE order_dates SET state = "ABIERTO" WHERE id = fecha_solicitud;
            END;
        END IF;
END