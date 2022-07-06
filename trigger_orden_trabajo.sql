BEGIN
/*-----VARIABLES PARA DETENER EL CICLO-----------*/
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final INT DEFAULT 0;
DECLARE tarea_final INT DEFAULT 0;
/*----VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE---*/
DECLARE orden_trabajo INT;
DECLARE ubicacion INT;
DECLARE implemento INT;
DECLARE componente INT;
DECLARE responsable INT;
DECLARE item INT;
DECLARE tiempo_vida DECIMAL(8,2);
DECLARE horas DECIMAL(8,2);
DECLARE cantidad DECIMAL(8,2);
DECLARE precio_estimado DECIMAL(8,2);
DECLARE tarea_componente INT;
/*------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA---------*/
DECLARE pieza INT;
DECLARE item_pieza INT;
DECLARE horas_pieza INT;
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza DECIMAL(8,2);
DECLARE precio_estimado_pieza DECIMAL(8,2);
DECLARE tarea_pieza INT;
/*-----ID DEL COMPONENTE POR SU IMPLEMENTO Y LA PIEZA POR SU COMPONENTE PARA LA ORDEN DE TRABAJO----------------*/
DECLARE implemento_componente INT;
DECLARE componente_pieza INT;
/*------CURSOR PARA ITERAR LOS COMPONENTES---------*/
DECLARE cur_comp CURSOR FOR SELECT i.id, c.id, c.item_id, c.lifespan, i.user_id,u.location_id, it.estimated_price FROM component_implement_model cim INNER JOIN implements i ON i.implement_model_id = cim.implement_model_id INNER JOIN users u ON u.id = i.user_id INNER JOIN components c ON c.id = cim.component_id INNER JOIN items it ON it.id = c.item_id;
/*--------------------------DECLARAR HANDLER PARA DETENERSE---------------*/
DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
/*-----------------------------------ABRIR CURSOR COMPONENTE---------------*/
OPEN cur_comp;
	bucle_comp:LOOP
    IF componente_final = 1 THEN
    	LEAVE bucle_comp;
    END IF;
    FETCH cur_comp INTO implemento,componente,item,tiempo_vida,responsable,ubicacion,precio_estimado;
/*---------------------OBTENER HORAS DEL COMPONENTE--------------------------*/
	IF NOT EXISTS(SELECT * FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE") THEN
    	INSERT INTO component_implement(component_id,implement_id) VALUES (componente,implemento);
    END IF;
    SELECT id,hours INTO implemento_componente,horas FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE" LIMIT 1;
/*-----------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DÍAS--------------------*/
    SELECT ROUND((horas+20)/tiempo_vida) INTO cantidad;
/*---------------VERIFICAR SI EXISTE LA CABECERA DE LA SOLICITUD-------*/
    IF NOT EXISTS(SELECT * FROM work_orders WHERE implement_id = implemento  AND user_id = responsable AND state = "PENDIENTE") THEN
        INSERT INTO work_orders(implement_id,user_id,location_id,`date`,maintenance,created_at,updated_at) VALUES (implemento,responsable,ubicacion,DATE_ADD(NOW(),INTERVAL 3 DAY),1,NOW(),NOW());
    END IF;
/*--------------OBTENIENDO LA CABECERA DE LA SOLICITUD------------------*/
    SELECT id INTO orden_trabajo FROM work_orders WHERE implement_id = implemento AND user_id = responsable AND state = "PENDIENTE" LIMIT 1;
/*----------VERIFICAR SI SE REQUIERE CAMBIAR EL COMPONENTE---------------------*/
    IF(cantidad > 0) THEN
        /*-------------OBTENER LA TAREA DE RECAMBIO DEL COMPONENTE-----*/
        SELECT id INTO tarea_componente FROM tasks WHERE task = "RECAMBIO" AND component_id = componente;
        /*-------------CAMBIAR COMPONENTE-----------------------*/
        INSERT INTO work_order_details(work_order_id,task_id,created_at,updated_at) VALUES (orden_trabajo,tarea_componente,NOW(),NOW());
    ELSE
        /*------------RUTINARIO DEL COMPONENTE------------------*/
        BEGIN
            /*--------CURSOR PARA ITERAR TAREAS POR COMPONENTE----*/
            DECLARE cur_task CURSOR FOR SELECT id FROM tasks WHERE component_id = componente AND task <> "RECAMBIO";
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
            /*-------ABRIR CURSOR PARA ITERAR TAREAS POR COMPONENTE---*/
            OPEN cur_task;
                bucle_comp_task:LOOP
                IF tarea_final = 1 THEN
                    LEAVE bucle_comp_task;
                END IF;
                FETCH cur_task INTO tarea_componente;
                IF NOT EXISTS(SELECT * FROM work_order_details WHERE state = "RECOMENDADO" AND work_order_id = orden_trabajo AND task_id = tarea_componente) THEN
                    INSERT INTO work_order_details(work_order_id,task_id,component_implement_id,created_at,updated_at) VALUES (orden_trabajo,tarea_componente,implemento_componente,NOW(),NOW());
                END IF;
                END LOOP bucle_comp_task;
            /*--------RESETEAR CONTADOR DE TAREAS PARA EL SIGUIENTE COMPONENTE----*/
            SELECT 0 INTO tarea_final;
            /*-----CERRAR CURSOR DE TAREAS-----------*/
            CLOSE cur_task;
        END;
        BEGIN
            /*------------CURSOR PARA PIEZAS------------------------*/
            DECLARE cur_part CURSOR FOR SELECT cpm.part,c.lifespan,c.item_id,it.estimated_price FROM component_part_model cpm INNER JOIN components c ON c.id = cpm.part INNER JOIN items it ON it.id = c.item_id WHERE cpm.component = componente;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_final = 1;
            /*------------ABRIR CURSOR PARA PIEZA-----------------------*/
            OPEN cur_part;
                bucle_part:LOOP
                IF pieza_final = 1 THEN
            	    LEAVE bucle_part;
                END IF;
                FETCH cur_part INTO pieza,tiempo_vida_pieza,item_pieza,precio_estimado_pieza;
                /*--------------OBTENER LAS HORAS DE LAS PIEZAS-------------------------------*/
                IF NOT EXISTS(SELECT * FROM component_part cp WHERE cp.component_implement_id = implemento_componente AND cp.part = pieza AND cp.state = "PENDIENTE") THEN
                    INSERT INTO component_part(component_implement_id ,part) VALUES (implemento_componente,pieza);
    		    END IF;
    			    SELECT cp.id,cp.hours INTO componente_pieza,horas_pieza FROM component_part cp WHERE cp.component_implement_id = implemento_componente AND cp.part = pieza AND cp.state = "PENDIENTE" LIMIT 1;
                /*-------------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DÍAS---------------------*/
                SELECT ROUND((horas_pieza+20)/tiempo_vida_pieza) INTO cantidad_pieza;
                /*----------VERIFICAR SI SE REQUIERE CAMBIAR EL COMPONENTE----------------------------*/
                IF(cantidad_pieza > 0) THEN
                    /*----------OBTENER LA TAREA DE RECAMBIO DE LA PIEZA-------------------------------*/
                    SELECT id INTO tarea_pieza FROM tasks WHERE task = "RECAMBIO" AND component_id = pieza;
                    /*-------------CAMBIAR COMPONENTE--------------------------------------------------*/
                    INSERT INTO work_order_details(work_order_id,task_id,created_at,updated_at) VALUES (orden_trabajo,tarea_componente,NOW(),NOW());
                ELSE
                    /*------------RUTINARIO DE PIEZAS-----------------------------*/
                    BEGIN
                        /*------------CURSOR PARA ITERAR TAREAS POR PIEZA-----------------*/
                        DECLARE cur_task CURSOR FOR SELECT id FROM tasks WHERE component_id = pieza AND task <> "RECAMBIO";
                        DECLARE CONTINUE HANDLER FOR NOT FOUND SET tarea_final = 1;
                        /*----------------ABRIR CURSOR PARA ITERAR TAREAS POR PIEZA----------------------*/
                        OPEN cur_task;
                            bucle_part_task:LOOP
                            IF tarea_final = 1 THEN
                                LEAVE bucle_part_task;
                            END IF;
                            FETCH cur_task INTO tarea_pieza;
                            IF NOT EXISTS(SELECT * FROM work_order_details WHERE state = "RECOMENDADO" AND work_order_id = orden_trabajo AND task_id = tarea_pieza) THEN
                    			INSERT INTO work_order_details(work_order_id,task_id,component_part_id ,created_at,updated_at) VALUES (orden_trabajo,tarea_pieza,componente_pieza,NOW(),NOW());
                            END IF;
                            END LOOP bucle_part_task;
                        CLOSE cur_task;
                    END;
                END IF;
                END LOOP bucle_part;
                SELECT 0 INTO tarea_final;
            CLOSE cur_part;
        END;
    END IF;
    /*------TERMINAR BUCLE DE COMPONENTES------------*/
	END LOOP bucle_comp;
/*-----------CERRAR CURSOR DE COMPONENTES---------------*/
CLOSE cur_comp;
END
