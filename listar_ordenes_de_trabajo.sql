-- Active: 1663248452468@@127.0.0.1@3306@sistema
BEGIN
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
        DECLARE horas_del_ultimo_mantenimiento_del_componente DECIMAL(8,2);
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
                            /*-----------------INICIO DE RECORRIDO DE TODOS LAS PIEZAS DEL COMPONENTE DEL IMPLEMENTO---------------------------------------------*/
                                BEGIN
                                    DECLARE lista_de_las_piezas_del_componente CURSOR FOR SELECT part FROM component_part_model WHERE component = componente;
                                    DECLARE CONTINUE HANDLER FOR NOT FOUND SET pieza_del_componente_final = 1;
                                    OPEN lista_de_las_piezas_del_componente;
                                        bucle_piezas_del_componente:LOOP
                                            FETCH lista_de_las_piezas_del_componente INTO pieza;
                                            IF pieza_del_componente_final THEN
                                                LEAVE bucle_piezas_del_componente;
                                            END IF;
                                            INSERT INTO prueba(implemento,componente,pieza) VALUES (implemento,componente,pieza);
                                        END LOOP bucle_piezas_del_componente;
                                    CLOSE lista_de_las_piezas_del_componente;
                                    SET pieza_del_componente_final = 0;
                                END;
                            /*-----------------FIN DE RECORRIDO DE TODAS LAS PIEZAS DEL COMPONENTE DEL IMPLEMENTNTO---------------------------------------------*/
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
