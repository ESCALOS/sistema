BEGIN
/*-----VARIABLES PARA DETENER EL CICLO-----------*/
DECLARE componente_final INT DEFAULT 0;
DECLARE pieza_final INT DEFAULT 0;
/*----VARIABLES PARA ALMACENAR DATOS DEL COMPONENTE---*/
DECLARE orden_trabajo INT;
DECLARE implemento INT;
DECLARE componente INT;
DECLARE responsable INT;
DECLARE item INT;
DECLARE tiempo_vida DECIMAL(8,2);
DECLARE horas DECIMAL(8,2);
DECLARE cantidad DECIMAL(8,2);
DECLARE precio_estimado DECIMAL(8,2);
/*------VARIABLES PARA ALMACENAR DATOS DE LA PIEZA---------*/
DECLARE pieza INT;
DECLARE item_pieza INT;
DECLARE horas_pieza INT;
DECLARE tiempo_vida_pieza DECIMAL(8,2);
DECLARE cantidad_pieza DECIMAL(8,2);
DECLARE precio_estimado_pieza DECIMAL(8,2);
/*------CURSOR PARA ITERAR LOS COMPONENTES---------*/
DECLARE cur_comp CURSOR FOR SELECT i.id, c.id, c.item_id, c.lifespan, i.user_id, it.estimated_price FROM component_implement_model cim INNER JOIN implements i ON i.implement_model_id = cim.implement_model_id INNER JOIN components c ON c.id = cim.component_id INNER JOIN items it ON it.id = c.item_id;
/*-------DECLARAR HANDLER PARA DETENERSE---------------*/
DECLARE CONTINUE HANDLER FOR NOT FOUND SET componente_final = 1;
/*---------ABRIR CURSOR COMPONENTE---------------*/
OPEN cur_comp;
	bucle:LOOP
    IF componente_final = 1 THEN
    	LEAVE bucle;
    END IF;
    FETCH cur_comp INTO implemento,componente,item,tiempo_vida,responsable,precio_estimado;
/*-----OBTENER HORAS DEL COMPONENTE--------------------------*/
	IF EXISTS(SELECT * FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE") THEN
    	SELECT hours INTO horas FROM component_implement WHERE implement_id = implemento AND component_id = componente AND state = "PENDIENTE" LIMIT 1;
    ELSE
    	SELECT 0 INTO horas;
    END IF;
/*-----------CALCULAR SI NECESITA RECAMBIO DENTRO DE 3 DÍAS--------------------*/
	END LOOP bucle;
CLOSE cur_comp;
END