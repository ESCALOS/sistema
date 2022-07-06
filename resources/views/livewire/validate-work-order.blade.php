<div>
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">ÓRDENES DE TRABAJO</h1>
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='modelo_implemento'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($implement_models as $request)
                    <option value="{{ $request->id }}">{{$request->implement_model }}</option>
                @endforeach
                </select>
            </div>
        </div>
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Modelo del Implemento:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='modelo_implemento'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($implement_models as $request)
                    <option value="{{ $request->id }}">{{$request->implement_model }}</option>
                @endforeach
                </select>
            </div>
        </div>
    </div>
<!-- Listar usuarios que tienen pedidos por validar  -->
@isset($implements)
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($implements as $implement)
    <!-- Cards de los usuarios con pedidos pendientes a validar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="{{ $implement->implement_model_id }}"/>
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $implement->implement_number }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{$implement->implement_model}}</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button wire:click="mostrarOrdenTrabajo({{$implement->id}},'{{$implement->implement_model}}','{{$implement->implement_number}}','{{$implement->name}}','{{$implement->lastname}}')" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
@endisset
<!-- Modal para validar la orden de trabajo  -->
<x-jet-dialog-modal maxWidth="2xl" wire:model="open_validate_work_order">
    <x-slot name="title">
        Pedido de {{$nombre_modelo}} {{$numero_implemento}} - {{$nombre_operador}}
    </x-slot>
    <x-slot name="content">
            <div class="grid grid-cols-1 sm:grid-cols-1 gap-4 mt-4">
    <!------------------------ INICIO DE TABLAS --------------------------------------->
        <!----------------------- TABLA DE TAREAS VALIDADAS -------------------------------------------->
                    <div class=" rounded-md bg-yellow-200 shadow-md py-4">
                        <h1 class="text-lg font-bold">TAREAS REQUERIDAS</h1>
                    </div>
                    <div style="height:180px;overflow:auto">
                        <table class="min-w-max w-full">
                            <thead>
                                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                    <th class="py-3 text-center">
                                        <span>Tarea</span>
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="text-gray-600 text-sm font-light">
                                @isset($tareas)
                                @foreach ($tareas as $request)
                                    <tr wire:dblclick="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{$request->task->task}} </span>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                                @endisset
                            </tbody>
                        </table>
                    </div>
        <!-- ------------------------ TABLA DE TAREAS RECHAZADAS ---------------------------------------  -->
        <div class=" rounded-md bg-green-200 shadow-md py-4">
            <h1 class="text-lg font-bold">TAREAS RECHAZADAS</h1>
        </div>
        <div style="height:180px;overflow:auto">
            <table class="min-w-max w-full">
                <thead>
                    <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                        <th class="py-3 text-center">
                            <span>Tarea</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="text-gray-600 text-sm font-light">
                    @isset($tareas)
                    @foreach ($tareas_rechazadas as $request)
                        <tr wire:dblclick="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-medium">{{$request->task->task}} </span>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                    @endisset
                </tbody>
            </table>
        </div>
    <!------------------------ FIN DE TABLAS --------------------------------------->
            </div>
    </x-slot>
<!------------------------ FOOTER MODAL --------------------------------------->
    <x-slot name="footer">
        <button wire:loading.attr="disabled" wire:click="$emit('confirmarValidarSolicitudPedido',[])" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
            Validar
        </button>
        <button wire:loading.attr="disabled" wire:click="$emit('confirmarRechazarSolicitudPedido','')" style="width: 200px" class="ml-2 px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
            Rechazar
        </button>
        <x-jet-secondary-button wire:click="$set('open_validate_work_order',false)" class="ml-2">
            Cancelar
        </x-jet-secondary-button>
    </x-slot>
<!---------------------------------------------------------------------------------------------------->
</x-jet-dialog-modal>
</div>
