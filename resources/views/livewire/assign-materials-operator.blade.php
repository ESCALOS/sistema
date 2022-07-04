<div>
<!-- Título de Asignar materiales  -->
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">Asignar materiales </h1>
    </div>
<!-- Filtrar operarios que tienen pedidos por zona, sede y ubicación  -->
    <div class="grid grid-cols-1 sm:grid-cols-{{ $tlocation > 0 ? '4' : ($tsede > 0 ? '3' : ($tzone > 0 ? '2' : '1'))}} gap-4">
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Zona:  </x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='tzone'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($zones as $zone)
                    <option value="{{ $zone->id }}">{{ $zone->zone }}</option>
                @endforeach
                </select>
            </div>
        </div>
        @if ($tzone != 0)
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Sede:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='tsede'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($sedes as $sede)
                    <option value="{{ $sede->id }}">{{ $sede->sede }}</option>
                @endforeach
                </select>
            </div>
        </div>
            @if($tsede != 0)
            <div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='tlocation'>
                        <option value="0">Seleccione una zona</option>
                    @foreach ($locations as $location)
                        <option value="{{ $location->id }}">{{ $location->location }}</option>
                    @endforeach
                    </select>
                </div>
            </div>
                @if ($tlocation != 0)
                    <div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Fecha Pedido:</x-jet-label>
                            <select class="form-select" style="width: 100%" wire:model='tfecha'>
                                <option value="0">Seleccione una opción</option>
                            @foreach ($order_dates as $order_date)
                                <option value="{{ $order_date->id }}">{{ $order_date->order_date }}</option>
                            @endforeach
                            </select>
                        </div>
                    </div>
                @endif
            @endif
        @endif
    </div>
<!-- Listar usuarios que tienen pedidos por validar  -->
    @if ($users->count())
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($users as $user)
    <!-- Cards de los usuarios con pedidos pendientes a validar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="{{ $user->lastname }}"/>
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $user->name }} {{ $user->lastname }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">Operario</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button wire:click="mostrarPedidos({{$user->id}},'{{$user->name}}','{{$user->lastname}}')" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
<!-- Modal para validar solicitudes por implemento del operador  -->
    <x-jet-dialog-modal maxWidth="2xl" wire:model="open_request_list">
        <x-slot name="title">
            Pedido de {{$operador}}
        </x-slot>
        <x-slot name="content">
        <!------------------------------------------- SELECT DE LOS IMPLEMENTOS ------------------------------------------------- -->
            <div class="shadow-xl mb-4">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Implemento: </x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model="id_implemento">
                        <option value="0">Seleccione una implemento</option>
                        @foreach ($implements as $implement)
                            <option value="{{ $implement->id }}"> {{$implement->implement_model}} {{ $implement->implement_number }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="id_implemento"/>
            </div>
        <!-------------------------------------------TABLA DE LOS MATERIALES ------------------------------------------------- -->
                <div class="grid grid-cols-1 sm:grid-cols-1 gap-4 mt-4">
        <!------------------------ INICIO DE TABLAS --------------------------------------->
            <!------------------------ TABLA DE MATERIALES POR VALIDAR --------------------------------------->
                        <div class=" rounded-md bg-yellow-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Lista de Materiales Pedidos</h1>
                            </div>
                        </div>
                        <div style="height:180px;overflow:auto">
                            <table class="min-w-max w-full">
                                <thead>
                                    <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                        <th class="py-3 text-center">
                                            <span>Código</span>
                                        </th>
                                        <th class="py-3 text-center">
                                            <span>Componentes</span>
                                        </th>
                                        <th class="py-3 text-center">
                                            <span>Cantidad</span>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody class="text-gray-600 text-sm font-light">
                                    @foreach ($order_request_detail as $request)
                                    <tr wire:dblclick="modalAsignarOperador({{$request->id}})" class="border-b border-gray-200 unselected">
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{$request->item->sku}} </span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-bold {{$request->item->type == "PIEZA" ? 'text-red-500' : ( $request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">
                                                    {{ strtoupper($request->item->item) }}
                                                </span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{($request->quantity - $request->assigned_quantity)}} {{$request->item->measurementUnit->abbreviation}}</span>
                                            </div>
                                        </td>
                                    </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
            <!----------------------- TABLA DE MATERIALES VALIDADOS -------------------------------------------->
                        <div class=" rounded-md bg-green-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Lista de Materiales Asignados</h1>
                            </div>
                        </div>
                        <div style="height:180px;overflow:auto">
                            <table class="min-w-max w-full">
                                <thead>
                                    <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                        <th class="py-3 text-center">
                                            <span>Código</span>
                                        </th>
                                        <th class="py-3 text-center">
                                            <span>Componentes</span>
                                        </th>
                                        <th class="py-3 text-center">
                                            <span>Cantidad</span>
                                        </th>
                                    </tr>
                                </thead>
                                <tbody class="text-gray-600 text-sm font-light">
                                    @isset($operator_stock)
                                    @foreach ($operator_stock as $request)
                                    <tr wire:dblclick="$emit('confirmarAnularAsignacionMaterial',[{{$request->id}},'{{$request->item->item}}'])" class="border-b border-gray-200 unselected">
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{$request->item->sku}} </span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-bold {{$request->item->type == "PIEZA" ? 'text-red-500' : ( $request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">
                                                    {{ strtoupper($request->item->item) }}
                                                </span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{($request->quantity - $request->assigned_quantity)}} {{$request->item->measurementUnit->abbreviation}}</span>
                                            </div>
                                        </td>
                                    </tr>
                                    @endforeach
                                    @endisset
                                </tbody>
                            </table>
                        </div>
            <!-- ------------------------ TABLA DE MATERIALES RECHAZADOS ---------------------------------------  -->

        <!------------------------ FIN DE TABLAS --------------------------------------->
                </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-secondary-button wire:click="$set('open_request_list',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!------------------------ MODAL ASIGNAR MATERIAL --------------------------------------->
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_assign_material">
        <x-slot name="title">
            <h1>{{$detalle_pedido_material}}</h1>
        </x-slot>
        <x-slot name="content">
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Cantidad Pedida</x-jet-label>
                <div class="flex">
                        <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="detalle_pedido_cantidad" />

                        <span class="detalle_pedido_unidad_medida-flex items-center pt-1 px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                            {{$detalle_pedido_unidad_medida}}
                        </span>
                    </div>
                <x-jet-input-error for="detalle_pedido_cantidad"/>
            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Precio Unitario</span></x-jet-label>
                <x-jet-input readonly type="number" min="0" style="height:30px;width: 100%" class="text-center" value="{{$detalle_pedido_precio}}"/>
            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Precio Total</span></x-jet-label>
                <x-jet-input type="number" min="0" readonly style="height:30px;width: 100%" class="text-center" wire:model="detalle_pedido_precio_total"/>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="asignarMaterial()">
                Asignar
            </x-jet-button>
            <div wire:loading wire:target="asignarMaterial">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_assign_material',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
