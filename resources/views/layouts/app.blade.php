<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">

        <title>{{ config('app.name', 'Laravel') }}</title>

        <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap">

        <link rel="stylesheet" href="{{ mix('css/app.css') }}">

        @livewireStyles

        <script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
        <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
        <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>
        <script src="//cdn.jsdelivr.net/npm/sweetalert2@11"></script>

        <script src="{{ mix('js/app.js') }}" defer></script>
    </head>
    <body class="font-sans antialiased">
        <x-jet-banner />

        <div class="min-h-screen bg-gray-100">

            @livewire('navigation')

            <div>
                <div class="max-w-7xl mx-auto py-8 sm:px-6 lg:px-8">
                    {{ $slot }}
                </div>
            </div>

        </div>

        @stack('modals')

        @livewireScripts

        <script>
/*------Alerta para registro----------------------------------------------------*/
            Livewire.on('alert', function(){
                Swal.fire({
                    position: 'top-end',
                    icon: 'success',
                    title: 'Registrado correctamente',
                    showConfirmButton: false,
                    timer: 1000
                })
            });
/*---------------------------------------------------------------------------------------*/
        @if (Route::is('operator.request-materials'))
/*--------------ALERTAS PARA LA CONFIRMACION DE CERRAR PEDIDO(OPERADOR) --------------------*/
    /*--------------------Confirmacion para cerra el pedido--------------------------------------*/
            Livewire.on('confirmarCerrarPedido', implemento =>{
                Swal.fire({
                    title: '¿Está seguro de cerrar el pedido de '+implemento+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, cerrar!',
                    cancelButtonText: 'No, cancelar!',
                }).then((result) => {
                    if (result.isConfirmed) {

                        Livewire.emitTo('request-material', 'cerrarPedido');

                        Swal.fire(
                            'Pedido Cerrado!',
                            'Se procesó el pedido',
                            'success'
                        )
                    }
                })
            });
/*------------------------------------------------------------------------------------------------------*/
        @endif
        @if (Route::is('operator.pre-reserva'))
/*--------------ALERTAS PARA LA CONFIRMACION DE CERRAR Pre-Reserva(OPERADOR) --------------------*/
    /*--------------------Confirmacion para cerra la pre-reserva--------------------------------------*/
            Livewire.on('confirmarCerrarPreReserva', implemento =>{
                Swal.fire({
                    title: '¿Está seguro de cerrar la pre-reserva de '+implemento+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, cerrar!',
                    cancelButtonText: 'No, cancelar!',
                }).then((result) => {
                    if (result.isConfirmed) {
                        
                        Livewire.emitTo('pre-reserva', 'cerrarPreReserva');

                        Swal.fire(
                            'Pre-reserva Cerrado!',
                            'Se procesó la Pre-reserva',
                            'success'
                        )
                    }
                })
            });
/*------------------------------------------------------------------------------------------------------*/
        @endif
        @if(Route::is('planner.validate-request-materials'))
/*--------------ALERTAS PARA LA VISTA DE VALIDAR SOLICITUD DE PEDIDO(PLANNER)---------------*/
    /*--------------------Confirmacion Reinsertar Pedido Rechazado--------------------------------------*/
            Livewire.on('confirmarReinsertarRechazado', solicitud =>{
                Swal.fire({
                    title: '¿Está seguro de reinsertar el material '+solicitud[1]+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, reinsertar!',
                    cancelButtonText: 'No, cancelar!',
                }).then((result) => {
                    if (result.isConfirmed) {

                        Livewire.emit('reinsertarRechazado',solicitud[0]);

                        Swal.fire(
                            'Material Reinsertado!',
                            'El material se encuentra pendiente a validar',
                            'success'
                        )
                    }
                })
            });
    /*----------Confirmación para cerrar solicitud de pedido-----------------*/
        /*-------[0] => id   --  [1] => Nombre Implemento -- [2] => Monto Usado--  [3] => Cantidad de materiales nuevos pendientes -----------*/
            Livewire.on('confirmarValidarSolicitudPedido', solicitud =>{
                if(solicitud[0] <= 0){
                    Swal.fire(
                                'Implemento no seleccionado',
                                'Seleccione un implemento',
                                'error'
                            )
                }else if(solicitud[2] > 0){
                    Swal.fire(
                                'Hay pedidos pendientes a validar',
                                'Valide o rechace los pedidos',
                                'info'
                            )
                }else if(solicitud[3] > 0){
                    Swal.fire(
                                'Hay ' + solicitud[3] + ' materiales nuevos por validar',
                                'Valide o rechace los pedidos',
                                'info'
                            )
                }else{
                    Swal.fire({
                    title: '¿Validar la solicitud de pedido del implemento '+solicitud[1]+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, validar!',
                    cancelButtonText: 'No, cancelar!',
                    }).then((result) => {
                        if (result.isConfirmed) {

                            Livewire.emitTo('validate-request-material','validarSolicitudPedido');

                            Swal.fire(
                                'Solicitud de pedido validado!',
                                'El pedido se validó correctamente',
                                'success'
                            )
                        }
                    })
                }
            });
    /*------------------------Rechazar solicitud de pedido ---------------------------------*/
        /*------------- [0] => Nombre Implemento ---------------------------------*/
        Livewire.on('confirmarRechazarSolicitudPedido', implemento =>{

            Swal.fire({
            title: 'Rechazar la solicitud de pedido del implemento '+implemento+'?',
            text: "Esta acción es irreversible",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#3085d6',
            cancelButtonColor: '#d33',
            confirmButtonText: 'Sí, validar!',
            cancelButtonText: 'No, cancelar!',
            }).then((result) => {
                if (result.isConfirmed) {

                    Livewire.emitTo('validate-request-material','rechazarSolicitudPedido');

                    Swal.fire(
                        'Solicitud de pedido rechazada!',
                        'El pedido se rechazó correctamente',
                        'success'
                    )
                }
            })
        });
    /*----------------------Confirmar recharzar nuevo material-------------------------------*/
            Livewire.on('confirmarRechazarMaterialNuevo', nombre_material =>{
                Swal.fire({
                    title: '¿Rechazar el material '+nombre_material+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, rechazar!',
                    cancelButtonText: 'No, cancelar!',
                    }).then((result) => {
                        if (result.isConfirmed) {

                            Livewire.emitTo('validate-request-material','rechazarMaterialNuevo');

                            Swal.fire(
                                'Solicitud de pedido validado!',
                                'El pedido se validó correctamente',
                                'success'
                            )
                        }
                    })
            });
/*----------------------------------------------------------------------------------*/
        @endif
        @if(Route::is('planner.assign-materials-operator'))
/*--------------ALERTA PARA CONFIRMACION DE ANULAR ASIGNACION DE MATERIAL---------------------------*/
        Livewire.on('confirmarAnularAsignacionMaterial', material =>{
                Swal.fire({
                    title: 'Anular la asignación de ' + material [1]+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, anular!',
                    cancelButtonText: 'No, cancelar!',
                    }).then((result) => {
                        if (result.isConfirmed) {

                            Livewire.emit('anularAsignacionMaterial',material[0]);

                            Swal.fire(
                                'La asignación de ' + material[1] + ' ha sido anulada!',
                                'Se anuló correctamente',
                                'success'
                            )
                        }
                    })
            });
/*------------------------------------------------------------------------------------------*/
        @endif
        @if(Route::is('overseer.validate-work-order'))
/*--------------ALERTA PARA VALIDAR EL RECAMBIO DE MATERIALES---------------------------*/
        Livewire.on('confirmarValidarRecambio', implemento =>{
                Swal.fire({
                    title: 'Validar el recambio de ' + implemento+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, validar!',
                    cancelButtonText: 'No, cancelar!',
                    }).then((result) => {
                        if (result.isConfirmed) {

                            Livewire.emit('validarRecambio');

                            Swal.fire(
                                'Se validó el recambio del implemento!',
                                'Recambio validado',
                                'success'
                            )
                        }
                    })
            });
/*------------------------------------------------------------------------------------------*/
/*--------------ALERTA PARA RECHAZAR EL RECAMBIO DE MATERIALES---------------------------*/
        Livewire.on('confirmarRechazarRecambio', implemento =>{
                Swal.fire({
                    title: 'Rechazar el recambio de ' + implemento+'?',
                    text: "Esta acción es irreversible",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#3085d6',
                    cancelButtonColor: '#d33',
                    confirmButtonText: 'Sí, rechazar!',
                    cancelButtonText: 'No, cancelar!',
                    }).then((result) => {
                        if (result.isConfirmed) {

                            Livewire.emit('rechazarRecambio');

                            Swal.fire(
                                'Se rechazó el recambio del implemento!',
                                'Recambio rechazado',
                                'success'
                            )
                        }
                    })
            });
/*------------------------------------------------------------------------------------------*/
        @endif
        </script>
    </body>
</html>
