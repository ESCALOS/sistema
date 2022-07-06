BEGIN
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
                IF NOT EXISTS(SELECT * FROM work_order_epps WHERE work_order_id = new.work_order_id AND epp_id = equipo_proteccion) THEN
                    INSERT INTO work_order_epps(work_order_id ,epp_id) VALUES (new.work_order_id,equipo_proteccion);
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