<div>
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">ÓRDENES DE TRABAJO</h1>
    </div>
    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
        <x-jet-label>Dia:</x-jet-label>
        <select class="form-select" style="width: 100%" wire:model='dia'>
            <option value="">Seleccione una fecha</option>
            @foreach ($fechas as $fecha)
            <option value="{{ $fecha->date }}">{{ $fecha->date }}</option>
            @endforeach
        </select>
    </div>
<!-- Listar implementos que tienen componentes o piezas para cambiar  -->
    @isset($implementos)
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($implementos as $implement)
    <!-- Cards de los implementos que tienen componentes o piezas para cambiar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="{{ $implement->implement_model_id }}"/>
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $implement->implement_number }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{$implement->implement_model}}</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button wire:click="mostrarTareas({{$implement->work_order}})" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endisset
<!-- Modal para validar la orden de trabajo  -->
    <x-jet-dialog-modal maxWidth="2xl" wire:model="open_prereserva_materiales">
        <x-slot name="title">
            Reponer implemento de {{$nombre_implemento}}
        </x-slot>
        <x-slot name="content">
        <!------------------------ INICIO DE TABLAS --------------------------------------->
            <div class=" rounded-md bg-yellow-200 shadow-md py-4">
                <h1 class="text-lg font-bold">Materiales Requeridos</h1>
            </div>
            <div style="height:200px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Material</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Requerido</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Almacen</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Restante</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @isset($materiales)
                        @foreach ($materiales as $request)
                            <tr wire:click="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->item}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->quantity}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->quantity}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->quantity - $request->quantity}} </span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                        @endisset
                    </tbody>
                </table>
            </div>
            <div class=" rounded-md bg-green-200 shadow-md py-4">
                <h1 class="text-lg font-bold">Tareas</h1>
            </div>
            <div style="height:200px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Comp</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Pieza</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Tarea</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @isset($tareas)
                        @foreach ($tareas as $request)
                            <tr class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{strtoupper($request->componente)}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{strtoupper($request->pieza)}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center" style="max-width:150px">
                                    <div>
                                        <span class="font-medium">{{$request->task}} </span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                        @endisset
                    </tbody>
                </table>
            </div>
        <!------------------------ FIN DE TABLAS --------------------------------------->
        </x-slot>
    <!------------------------ FOOTER MODAL --------------------------------------->
        <x-slot name="footer">
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarValidarRecambio','{{$nombre_implemento}}')" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Validar
            </button>
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarRechazarRecambio','{{$nombre_implemento}}')" style="width: 200px" class="ml-2 px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Rechazar
            </button>
            <x-jet-secondary-button wire:click="$set('open_prereserva_materiales',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    <!---------------------------------------------------------------------------------------------------->
    </x-jet-dialog-modal>
</div>
