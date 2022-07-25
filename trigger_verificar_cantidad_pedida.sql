BEGIN
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
                        INSERT INTO general_order_requests(item_id,quantity,quantity_to_arrive,price,sede_id,order_date_id) VALUES (material, cantidad, cantidad, precio*cantidad, sede, new.order_date_id);
                    ELSE
                        UPDATE general_order_requests SET quantity = quantity + cantidad, quantity_to_arrive = quantity_to_arrive + cantidad, price = price + (precio*cantidad) WHERE item_id = material AND sede_id = sede AND order_date_id = new.order_date_id;
                    END IF;
                END LOOP bucle;
            CLOSE cursor_item;
        END;
    END;
END IF;
END
