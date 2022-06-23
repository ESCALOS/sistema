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
        @if (Route::is('operator.request-materials'))
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
                            'Se le notificará cuando se apruebe'
                        )
                    }
                })
            });
        @endif
        @if(Route::is('planner.validate-request-materials'))
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
                            'Pedido Reinsertado!',
                            'El pedido se encuentra pendiente a validar',
                            'success'
                        )
                    }
                })
            });
        @endif
        </script>
    </body>
</html>
