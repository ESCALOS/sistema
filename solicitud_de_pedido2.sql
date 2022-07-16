BEGIN
    /*------VARIABLES PARA LA ALMACENAR LA FECHA PARA ABRIR EL PEDIDO---------------------*/
        DECLARE fecha_solicitud INT;
        DECLARE fecha_abrir_solicitud DATE;
    /*------OBTENER LA FECHA DE APERTURA DEL PEDIDO MÁS CERCANO-----------------------------*/
        SELECT id,open_request INTO fecha_solicitud,fecha_abrir_solicitud FROM order_dates WHERE state = "PENDIENTE" ORDER BY open_request ASC LIMIT 1;
    /*------HACER EN CASO SEA FECHA DE ABRIR EL PEDIDO--------------------------------------*/
        IF(fecha_abrir_solicitud <= NOW()) THEN
            BEGIN
                /*-----------VARIABLES PARA DETENER LOS CICLOS------------------------------*/
                    DECLARE implemento_final INT DEFAULT 0;
                    DECLARE componente_final INT DEFAULT 0;
                    DECLARE pieza_final INT DEFAULT 0;
                    DECLARE tarea_final INT DEFAULT 0;
                    DECLARE material_final INT DEFAULT 0;
                /*-----------VARIABLES PARA LA CABECERA DE LA SOLICITUD DE PEDIDO------------*/
                    DECLARE implemento INT;
                    DECLARE responsable INT;
                /*-----------VARIABLES PARA EL DETALLE DE LA SOLICITUD DEL PEDIDO------------*/
                    DECLARE solicitud_pedido INT;
                    DECLARE componente_del_implemento INT;
                    DECLARE pieza_del_componente INT;
                /*-----------VARIABLE PARA ALMACENAR EL MODELO DEL IMPLEMENTO-----------------*/
                    DECLARE modelo_del_implemento INT;
                /*-----------VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE--------------------*/
                    DECLARE componente INT;
                    DECLARE horas_componente DECIMAL(8,2);
                    DECLARE tiempo_vida_componente DECIMAL(8,2);
                    DECLARE cantidad_componente DECIMAL(8,2);
                    DECLARE item_componente DECIMAL(8,2);
                    DECLARE precio_componente DECIMAL(8,2);
                /*-----------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA------------------------*/
                    DECLARE pieza INT;
                    DECLARE horas_pieza DECIMAL(8,2);
                    DECLARE tiempo_vida_pieza DECIMAL(8,2);
                    DECLARE cantidad_pieza DECIMAL(8,2);
                    DECLARE item_pieza DECIMAL(8,2);
                    DECLARE precio_pieza DECIMAL(8,2);
                /*---------VARIABLES PARA LA TAREA Y SUS MATERIALES-----------------------------------------------------*/
                    DECLARE tarea INT;
                    DECLARE material INT;
                /*-----------CURSOR PARA ITERAR CADA IMPLEMENTO--------------------------------*/
                    DECLARE cursor_implementos CURSOR FOR SELECT id,implement_model_id,user_id,location_id FROM implements;
                    DECLARE CONTINUE HANDLER for NOT FOUND SET implemento_final = 1;
                /*-----------ABRIR CURSOR DE LOS IMPLEMENTOS-----------------------------------*/
                    OPEN cursor_implementos;
                        bucle_implementos:LOOP
                            /*--------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS-------------*/
                                IF implemento_final = 1 THEN
                                    LEAVE bucle_implementos;
                                END IF;
                            /*--------OBTENER LOS DATOS DEL IMPLEMENTO DEL CICLO-----------------------*/
                                FETCH cursor_implementos INTO implemento,modelo_del_implemento,responsable;
                            /*---------HACER EN CASO LA SOLICITUD DE PEDIDO SI NO ESTÁ CREADA AÚN-----*/
                                IF NOT EXISTS(SELECT * FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud) THEN
                                    /*----------------------CREAR CABECERA DE LA SOLICITUD DE PEDIDO---------------------------------*/
                                        INSERT INTO order_requests (user_id,implement_id,order_date_id) VALUES (responsable,implemento,fecha_solicitud);
                                    /*----------------------OBTENER ID DE LA CABECERA DEL PEDIDO-------------------------------*/
                                        SELECT id INTO solicitud_pedido FROM order_requests WHERE implement_id = implemento AND state = "PENDIENTE" AND order_date_id = fecha_solicitud;
                                    /*----------------------CURSOR PARA ITERAR CADA COMPONENTE DEL IMPLEMENTO DEL CICLO---------------*/
                                        BEGIN
                                            DECLARE cursor_componentes CURSOR FOR SELECT component_id FROM component_implement_model WHERE implement_model_id = modelo_del_implemento;
                                            DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
                                            /*--------------ABRIR CURSOR DE LOS COMPONENTES--------------------------------------------*/
                                                OPEN cursor_componentes;
                                                    bucle_componentes:LOOP
                                                        /*--------DETENER EL CICLO CUANDO NO ENCUENTRE MÁS IMPLEMENTOS-------------*/
                                                            IF componente_final = 1 THEN
                                                                LEAVE bucle_componentes;
                                                            END IF;
                                                        /*---------OBTENER LOS DATOS DEL COMPONENTE DEL CICLO------------------------*/
                                                            FETCH cursor_componentes INTO componente;
                                                        /*---------HACER EN CASO NO EXISTA REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO-------*/
                                                            IF NOT EXISTS(SELECT * FROM component_implement WHERE component_id = componente AND implement_id = implemento)
                                                                /*-----------CREAR REGISTRO DE HORAS DEL COMPONENTE DEL IMPLEMENTO---------------*/
                                                                 INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
                                                            END IF;
                                                        /*--------OBTENER EL ID Y HORAS DEL COMPONENTE DEL IMPLEMENTO ----------------------------------------*/
                                                            SELECT id,hours INTO componente_del_implemento,horas_componente FROM component_implement WHERE component_id = componente AND implement_id = implemento AND state = "PENDIENTE";
                                                        /*--------OBTENER TIEMPO DE VIDA Y EL ID DEL ITEM DEL COMPONENTE -------------------------------------*/
                                                            SELECT c.lifespan,c.item_id,i.estimated_price INTO tiempo_vida_componente,item_componente,precio_componente FROM components c INNER JOIN items i ON i.id = c.item_id WHERE c.id = componente;
                                                        /*--------HACER SI EL TIEMPO DE VIDA SUPERA A LAS HORAS DEL COMPONENTE--------------------------------*/
                                                            IF horas_componente > tiempo_vida_componente THEN
                                                                /*-----------PONER EL TIEMPO DE VIDA COMO EL TOTAL DE HORAS-----------------------------------*/
                                                                SELECT tiempo_vida_componente INTO horas_componente
                                                            END IF;
                                                        /*--------CALCULAR CANTIDAD DE RECAMBIOS DENTRO DE 2 MESES----------------------------------------------*/
                                                            SELECT FLOOR((horas_componente+336)/tiempo_vida_componente) INTO cantidad_componente;
                                                        /*--------HACER EN CASO NECESITE RECAMBIO---------------------------------------------------------------*/
                                                            IF cantidad_componente > 0 THEN
                                                                /*-----CURSOR PARA ITERAR TODAS LAS TAREAS PARA EL RECAMBIO DEL COMPONENTE-----------------------*/
                                                                BEGIN
                                                                    DECLARE cursor_componente_tareas CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND type = "RECAMBIO";
                                                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                                                                    /*--------ABRIR CURSOR DE LAS TAREAS DE RECAMBIO PARA LOS COMPONENTES------------------------*/
                                                                    OPEN cursor_componente_tareas;
                                                                        bucle_componente_tareas:LOOP
                                                                            /*-----DETENER EL CICLO CUANDO NO ENCUENTRE MAS TAREAS----------------*/
                                                                            IF tarea_final = 1 THEN
                                                                                LEAVE bucle_componente_tareas;
                                                                            END IF;
                                                                            /*----------OBTENER LA TAREA DEL COMPONENTE-------------------------------*/
                                                                                FETCH cursor_componente_tareas INTO tarea_componente;
                                                                            /*----------CURSOR PARA ITERAR LOS MATERIALES DE DICHA TAREA--------------*/
                                                                            BEGIN
                                                                                DECLARE cursor_materiales CURSOR FOR SELECT item_id,quantity FROM task_required_materials WHERE task_id = tarea_componente;
                                                                                DECLARE CONTINUE HANDLER FOR NOT FOUND SET material_final = 1;
                                                                                /*----------ABRIR CURSOR DE MATERIALES-------------------------------*/
                                                                                OPEN cursor_materiales;
                                                                                    bucle_materiales:LOOP
                                                                                        /*----------DETENER CICLO CUANDO NO SE ENCUENTREN MAS MATERIALES-----------------*/
                                                                                        IF material_final = 1 THEN
                                                                                            LEAVE cursor_materiales;
                                                                                        END IF;
                                                                                        /*----------PONER MATERIALES PARA PEDIDO------------------------------*/
                                                                                        IF NOT EXISTS(SELECT * FROM order_request_details WHERE item_id = item_componente AND order_request_id = solicitud_pedido) THEN
                                                                                            INSERT INTO order_request_details(order_request_id,item_id,quantity,estimated_price) VALUES (solicitud_pedido,item_componente,cantidad_componente,precio_componente);
                                                                                        ELSE 
                                                                                            UPDATE order_request_details SET quantity = quantity + cantidad_componente WHERE order_request_id = solicitud_pedido AND item_id = item_componente;
                                                                                        END IF;
                                                                                    END LOOP bucle_materiales;
                                                                                CLOSE cursor_materiales;
                                                                                SELECT 0 INTO material_final;
                                                                            END;
                                                                        END LOOP bucle_componente_tareas;
                                                                    CLOSE cursor_componente_tareas;
                                                                    SELECT 0 INTO tarea_final;
                                                                END;
                                                            END IF;
                                                        /*---------CALCULAR MANTENIMIENTO PREVENTIVOS------------------------------------------------------*/
                                                        
                                                    END LOOP bucle_componentes;
                                                CLOSE cursor_componentes;
                                                SELECT 0 INTO componente_final;
                                        END;
                                END IF;
                        END LOOP bucle_implementos;
                    CLOSE cursor_implementos;
                    SELECT 0 INTO implemento_final;
            END
        END IF;
END