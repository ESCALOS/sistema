<div>
    @if ($fecha_pre_reserva != "")
<!-- Fecha del pedido actual  -->
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px" class="text-center">
        <h1 class="font-bold text-2xl">{{"PRE-RESERVA PARA EL MES DE ". strtoupper(strftime("%B de %Y", strtotime($fecha_pre_reserva)))}} </h1>
    </div>
<!-- Filtrar operarios que tienen pedidos por zona, sede y ubicación  -->
    <div class="grid grid-cols-1 sm:grid-cols-{{$tsede > 0 ? '2' : '1'}} gap-4">
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
                    <button wire:click="mostrarPreReserva({{$user->id}},'{{$user->name}}','{{$user->lastname}}')" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
<!-- Modal para validar solicitudes por implemento del operador  -->
    <x-jet-dialog-modal maxWidth="2xl" wire:model="open_validate_pre_reserva">
        <x-slot name="title">
            Pedido de {{$operador}}
        </x-slot>
        <x-slot name="content">
        <!------------------------------------------- SELECT DE LOS IMPLEMENTOS ------------------------------------------------- -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 shadow-xl mb-4">
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

                <div class="p-6">
                    <h1 class="text-lg font-bold text-blue-500">Monto Disponible: S/.{{$monto_asignado}} - {{$monto_usado}}</h1>
                </div>
            </div>
        <!-------------------------------------------TABLA DE LOS MATERIALES ------------------------------------------------- -->
                <div class="grid grid-cols-1 sm:grid-cols-1 gap-4 mt-4">
        <!------------------------ INICIO DE TABLAS --------------------------------------->
            <!------------------------ TABLA DE MATERIALES POR VALIDAR --------------------------------------->
                    @if(count($pre_stockpile_detail_operator))
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4  rounded-md bg-yellow-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales No Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_pre_reservado > $monto_asignado ? 'text-red-500' : 'text-green-500'}}">Precio Estimado: S/.{{number_format($monto_pre_reservado,2)}}</h1>
                            </div>
                        </div>
                        <div style="max-height:180px;overflow:auto">
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
                                    @foreach ($pre_stockpile_detail_operator as $request)
                                        <tr wire:click="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
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
                    @endif
            <!----------------------- TABLA DE MATERIALES VALIDADOS -------------------------------------------->
                    @if(count($pre_stockpile_detail_planner))
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 rounded-md bg-yellow-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_real > $monto_asignado ? 'text-red-500' : 'text-green-500'}} ">Precio Real: S/.{{number_format($monto_real,2)}}</h1>
                            </div>
                        </div>
                        <div style="max-height:180px;overflow:auto">
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
                                    @foreach ($pre_stockpile_detail_planner as $request)
                                        <tr wire:click="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
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
                    @endif
            <!-- ------------------------ TABLA DE MATERIALES RECHAZADOS ---------------------------------------  -->
                    @if(count($pre_stockpile_detail_rechazado))
                        <div class="rounded-md bg-yellow-200 shadow-md py-4">
                            <h1 class="text-lg font-bold">Materiales Rechazados</h1>
                        </div>
                        <div style="max-height:180px;overflow:auto">
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
                                    @foreach ($pre_stockpile_detail_rechazado as $request)
                                        <tr wire:click="$emit('confirmarReinsertarRechazado',[{{$request->id}},'{{$request->item->item}}'])" class="border-b border-gray-200 unselected">
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
                    @endif
        <!------------------------ FIN DE TABLAS --------------------------------------->
                </div>
        </x-slot>
        <x-slot name="footer">
        @if($id_implemento > 0)
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarValidarPreReserva',[{{$id_pre_reserva}},'{{$implemento}}',{{$monto_usado}}])" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Validar
            </button>
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarRechazarPreReserva','{{$implemento}}')" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Rechazar
            </button>
        @endif
            <x-jet-secondary-button wire:click="$set('open_validate_pre_reserva',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!------------------------ MODAL PARA VALIDAR O RECHAZAR MATERIAL --------------------------------------->
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_validate_material">
        <x-slot name="title">
            <h1>{{$material}}</h1>
        </x-slot>
        <x-slot name="content">
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Cantidad - <span class="text-blue-700 text-sm">(0 para rechazar)</span></x-jet-label>
                   <div class="flex">
                     <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="cantidad" />

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit}}
                    </span>
                    </div>
                <x-jet-input-error for="cantidad"/>
            </div>

            <div class="mb-2">
                <x-jet-label class="text-md">Cantidad Pedida:</x-jet-label>
                <div class="flex" style="padding-left: 1rem; padding-right:1rem;">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="cantidad_pedida" />

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit}}
                    </span>
                </div>
                <x-jet-input-error for="cantidad_pedida"/>
            </div>

            <div class="mb-2">
                <x-jet-label class="text-md">Stock:</x-jet-label>
                <div class="flex" style="padding-left: 1rem; padding-right:1rem;">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="cantidad_stock" />

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit}}
                    </span>
                </div>
                <x-jet-input-error for="cantidad_stock"/>
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
<!---------------------MENSAJE CUANDO NO HAY PEDIDOS ABIERTOS-------------------------------------->
    @else
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-4xl">NO HAY PRE-RESERVAS PARA VALIDAR</h1>
    </div>
    @endif
<!---------------------------------------------------------------------------------------->
</div>
