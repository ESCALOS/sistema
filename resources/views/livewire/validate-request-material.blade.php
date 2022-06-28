<div>
    <!-- Fecha del pedido actual  -->
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">{{$fecha_pedido}} </h1>
    </div>
    <!-- Filtrar operarios que tienen pedidos por zona, sede y ubicación  -->
    <div class="grid grid-cols-1 sm:grid-cols-{{$tsede > 0 ? '3' : ($tzone > 0 ? '2' : '1')}} gap-4">
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Zona:</x-jet-label>
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
            @endif
        @endif
    </div>
<!-- Listar usuarios que tienen pedidos por validar  -->
    @if ($tlocation != 0 && $users->count())
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($users as $user)
    <!-- Cards de los usuarios con pedidos pendientes a validar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="{{ $user->lastname }}"/>
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $user->name }} {{ $user->lastname }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">Operario</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button wire:click="mostrarImplementos({{$user->id}},'{{$user->name}}','{{$user->lastname}}')" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
<!-- Modal para validar materiales por usuario  -->
    <x-jet-dialog-modal maxWidth="2xl" wire:model="open_validate_resquest">
        <x-slot name="title">
            Pedido de {{$operador}}
        </x-slot>
        <x-slot name="content">
            <div class="grid grid-cols-2 sm:grid-cols-1 gap-4">
    <!------------------------------------------- SELECT DE LOS IMPLEMENTOS ------------------------------------------------- -->
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Implemento: </x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model="idImplemento">
                        <option value="0">Seleccione una implemento</option>
                        @foreach ($implements as $implement)
                            <option value="{{ $implement->id }}"> {{$implement->implement_model}} {{ $implement->implement_number }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="idImplemento"/>

                </div>

                <div>
                    <h1 class="text-lg font-bold text-blue-500">Monto Asignado: S/.{{$monto_asignado}}</h1>
                </div>
            </div>
    <!-------------------------------------------TABLA DE LOS MATERIALES ------------------------------------------------- -->
                <div class="grid grid-cols-1 sm:grid-cols-1 gap-4">
        <!------------------------ INICIO DE TABLAS --------------------------------------->
            <!------------------------ TABLA DE MATERIALES POR VALIDAR --------------------------------------->
                        <div class="grid grid-cols-2 sm:grid-cols-1 gap-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales No Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_usado > $monto_asignado ? 'text-red-500' : 'text-green-500'}}">Precio Estimado: S/.{{number_format($monto_usado,2)}}</h1>
                            </div>
                        </div>
                        <div style="height:200px;overflow:auto">
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
                                    @foreach ($order_request_detail_operator as $request)
                                        <tr wire:dblclick="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
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
                                                    <span class="font-medium">{{$request->quantity}} {{$request->item->measurementUnit->abbreviation}}</span>
                                                </div>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
            <!----------------------- TABLA DE MATERIALES VALIDADOS -------------------------------------------->
                        <div class="grid grid-cols-2 sm:grid-cols-1 gap-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_real > $monto_asignado ? 'text-red-500' : 'text-green-500'}} ">Precio Real: S/.{{number_format($monto_real,2)}}</h1>
                            </div>
                        </div>
                        <div style="height:200px;overflow:auto">
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
                                    @foreach ($order_request_detail_planner as $request)
                                        <tr wire:dblclick="editar({{$request->id}})" class="border-b border-gray-200 unselected">
                                            <td class="py-3 px-6 text-center">
                                                <div>
                                                    <span class="font-medium">{{$request->item->sku}} </span>
                                                </div>
                                            </td>
                                            <td class="py-3 px-6 text-center">
                                                <div>
                                                    <span class="font-bold {{$request->item->type == "PIEZA" ? 'text-red-500' : ( $request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">{{ strtoupper($request->item->item) }}</span>
                                                </div>
                                            </td>
                                            <td class="py-3 px-6 text-center">
                                                <div>
                                                    <span class="font-medium">{{$request->quantity}} {{$request->item->measurementUnit->abbreviation}}</span>
                                                </div>
                                            </td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        </div>
            <!-- ------------------------ TABLA DE MATERIALES RECHAZADOS ---------------------------------------  -->
                    <h1 class="text-lg font-bold">Materiales Rechazados</h1>
                    <div style="height:200px;overflow:auto">
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
                                @foreach ($order_request_detail_rechazado as $request)
                                    <tr wire:dblclick="$emit('confirmarReinsertarRechazado',[{{$request->id}},'{{$request->item->item}}'])" class="border-b border-gray-200 unselected">
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{$request->item->sku}} </span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-bold {{$request->item->type == "PIEZA" ? 'text-red-500' : ( $request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "COMPONENTE" ? 'text-green-500' : ($request->item->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">{{ strtoupper($request->item->item) }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-center">
                                            <div>
                                                <span class="font-medium">{{$request->quantity}} {{$request->item->measurementUnit->abbreviation}}</span>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
        <!------------------------ FIN DE TABLAS --------------------------------------->
                </div>
        </x-slot>
        <x-slot name="footer">
            <button wire:loading.attr="disabled" {{$idImplemento <= 0 ? 'disabled' : '' }} wire:click="store()" style="width: 200px" class="px-4 py-2 {{ $idImplemento > 0 ? 'bg-blue-500 hover:bg-blue-700' : 'bg-blue-400 opacity-75' }} text-white rounded-md">
                Validar
            </button>
            <button wire:loading.attr="disabled" {{$idImplemento <=0 ? 'disabled' : '' }} wire:click="$emit('confirmarSolicitarCorrecion')" style="width: 200px" class="ml-2 px-4 py-2 {{ $idImplemento > 0 ? 'bg-green-500 hover:bg-green-700' : 'bg-green-400 opacity-75' }}  text-white rounded-md">
                Mandar a Corregir
            </button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_validate_resquest',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    <!------------------------ MODAL PARA VALIDAR O RECHAZAR SOLICITUD --------------------------------------->
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_validate_material">
        <x-slot name="title">
            <h1>{{$material}}</h1>
        </x-slot>
        <x-slot name="content">
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Item</x-jet-label>
                <x-jet-input type="text" style="height:30px;width: 100%" class="text-center" value="{{$material}}"/>

            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Cantidad - <span class="text-blue-700 text-sm">(0 para rechazar)</span></x-jet-label>
                <x-jet-input type="number" min="0" style="height:30px;width: 100%" class="text-center" wire:model='cantidad'/>

                <x-jet-input-error for="cantidad"/>
            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Precio Unitario Estimado</span></x-jet-label>
                <x-jet-input type="number" min="0" style="height:30px;width: 100%" class="text-center" wire:model="precio"/>

            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Precio Total</span></x-jet-label>
                <x-jet-input type="number" min="0" disabled style="height:30px;width: 100%" class="text-center" value="{{$precioTotal}}"/>

            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 3 span/ 3 span">
                <x-jet-label>Observaciones:</x-jet-label>
                <textarea class="form-control w-full text-sm" rows=5 wire:model.defer="observation"></textarea>
                <x-jet-input-error for="observation"/>
            </div>
        </x-slot>
        <x-slot name="footer">
            @if ($cantidad == 0)
                <x-jet-button wire:loading.attr="disabled" wire:click="validarMaterial()">
                    Rechazar
                </x-jet-button>
            @else
                <x-jet-button wire:loading.attr="disabled" wire:click="validarMaterial()">
                    Validar
                </x-jet-button>
            @endif
            <div wire:loading wire:target="validarMaterial">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_validate_material',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
