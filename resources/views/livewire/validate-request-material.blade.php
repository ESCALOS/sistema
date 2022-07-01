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
<!-- Modal para validar solicitudes por implemento del operador  -->
    <x-jet-dialog-modal maxWidth="2xl" wire:model="open_validate_resquest">
        <x-slot name="title">
            Pedido de {{$operador}}
        </x-slot>
        <x-slot name="content">
        <!------------ Boton para materiales nuevos----------------------->
            @if($cantidad_materiales_nuevos > 0)
            <div>
                <button wire:loading.attr="disabled" style="width: 100%" wire:click="$set('open_validate_new_material',true)" class="px-4 py-2 bg-red-500 hover:bg-red-700 text-white rounded-md">
                @if($cantidad_materiales_nuevos > 1)
                    ¡Se solicitaron {{$cantidad_materiales_nuevos}} nuevos materiales! CLICK PARA VER
                @elseif ($cantidad_materiales_nuevos == 1)
                    ¡Se solicitó un nuevo material! CLICK PARA VER
                @endif
                </button>
            </div>
            @endif
        <!------------------------------------------- SELECT DE LOS IMPLEMENTOS ------------------------------------------------- -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 shadow-xl mb-4">
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

                <div class="p-6">
                    <h1 class="text-lg font-bold text-blue-500">Monto Asignado: S/.{{$monto_asignado}}</h1>
                </div>
            </div>
        <!-------------------------------------------TABLA DE LOS MATERIALES ------------------------------------------------- -->
                <div class="grid grid-cols-1 sm:grid-cols-1 gap-4 mt-4">
        <!------------------------ INICIO DE TABLAS --------------------------------------->
            <!------------------------ TABLA DE MATERIALES POR VALIDAR --------------------------------------->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4  rounded-md bg-yellow-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales No Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_usado > $monto_asignado ? 'text-red-500' : 'text-green-500'}}">Precio Estimado: S/.{{number_format($monto_usado,2)}}</h1>
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
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 rounded-md bg-yellow-200 shadow-md py-4">
                            <div>
                                <h1 class="text-lg font-bold">Materiales Validados</h1>
                            </div>
                            <div>
                                <h1 class="text-lg font-bold {{$monto_real > $monto_asignado ? 'text-red-500' : 'text-green-500'}} ">Precio Real: S/.{{number_format($monto_real,2)}}</h1>
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
                                    @foreach ($order_request_detail_planner as $request)
                                        <tr wire:dblclick="mostrarModalValidarMaterial({{$request->id}})" class="border-b border-gray-200 unselected">
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
        @if($idImplemento > 0)
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarValidarSolicitudPedido',[{{$idSolicitudPedido}},'{{$implemento}}',{{$monto_usado}},{{$cantidad_materiales_nuevos}}])" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Validar
            </button>
            <button wire:loading.attr="disabled" wire:click="$emit('confirmarRechazarSolicitudPedido','{{$implemento}}'" style="width: 200px" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md">
                Rechazar
            </button>
        @endif
            <x-jet-secondary-button wire:click="$set('open_validate_resquest',false)" class="ml-2">
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
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label>Precio Unitario</span></x-jet-label>
                <x-jet-input type="number" min="0" style="height:30px;width: 100%" class="text-center" wire:model="precio"/>
                <x-jet-input-error for="precio"/>
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
<!------------------------ MODAL PARA VALIDAR O RECHAZAR MATERIALES --------------------------------------->
    <x-jet-dialog-modal wire:model='open_validate_new_material'>
        <x-slot name="title">
           Materiales Nuevos Solicitados por {{$operador}}
        </x-slot>
        <x-slot name="content">
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
                        @foreach ($order_request_new_materials as $request)
                            <tr wire:dblclick="detalleMaterialNuevo({{$request->id}})" class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->new_item}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->brand}}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->quantity}} {{$request->measurementUnit->abbreviation}}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-secondary-button wire:click="$set('open_validate_new_material',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!------------------------MODAL DETALLES DE MATERIALES NUEVOS------------------------------->
    <x-jet-dialog-modal wire:model="open_detail_new_material">
        <x-slot name="title">
            Detalle del material {{$material_nuevo_nombre}}
        </x-slot>
        <x-slot name="content">
            <div class="grid grid-cols-2">
            <!-- Material Solicitado por el operador -->
                <div class="grid grid-cols-1 sm:grid-cols-2">
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                        <x-jet-label>Marca:</x-jet-label>
                        <x-jet-input type="text" style="height:30px;width: 100%" readonly value="{{$material_nuevo_marca}}"/>
                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                        <x-jet-label>Cantidad:</x-jet-label>
                        <x-jet-input type="text" style="height:30px;width: 100%" readonly value="{{$material_nuevo_cantidad}} {{$material_nuevo_unidad_medida}}" />
                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                        <x-jet-label>Especificaciones:</x-jet-label>
                        <textarea readonly class="form-control w-full text-sm" rows=5 wire:model.defer="material_nuevo_ficha_tecnica"></textarea>
                    </div>
                    <div class="p-2" style="margin-left:15px;margin-right:15px;grid-column: 2 span/ 2 span;height:16rem">
                            <img style="display:inline;height:100%" src="{{ str_replace('public','/storage',$material_nuevo_imagen) }}">
                    </div>
                </div>
            <!-- CRUD para agregar el material -->
                <div class="grid grid-cols-1">
                    <div class="py-2 text-center" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Sku:</x-jet-label>
                        <x-jet-input type="number" min="0" style="height:30px;width: 100%;text-align: center" wire:model="create_material_sku" />

                        <x-jet-input-error for="create_material_sku"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Nombre:</x-jet-label>
                        <x-jet-input type="text" style="height:30px;width: 100%;text-align: center" wire:model="create_material_item" />

                        <x-jet-input-error for="create_material_item"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                        <x-jet-label>Marca:</x-jet-label>
                        <div class="grid grid-cols-4">
                            <div style="grid-column: 3 span/ 4 span">
                                <select class="form-select" style="width: 100%;text-align: center" wire:model='create_material_brand'>
                                    <option value="">Seleccione una opción</option>
                                    @foreach ($brands as $brand)
                                        <option value="{{ $brand->id }}">{{ $brand->brand }} </option>
                                    @endforeach
                                </select>
                            </div>
                            <div>
                                <button class="px-4 bg-blue-400 text-white font-bold hover:bg-blue-600 rounded-md h-2" style="height:30px" wire:click="$set('open_add_new_brand',true)">
                                    +
                                </button>
                            </div>
                        </div>
                        <x-jet-input-error for="create_material_brand"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Tipo: </x-jet-label>
                        <select class="form-select" style="width: 100%;text-align: center" wire:model='create_material_type'>
                            <option value="">Seleccione una opción</option>
                            <option>FUNGIBLE</option>
                            <option>HERRAMIENTA</option>
                        </select>

                        <x-jet-input-error for="create_material_type"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Unidad de Medida: </x-jet-label>
                        <select class="form-select" style="width: 100%;text-align: center" wire:model='create_material_measurement_unit'>
                            <option value="">Seleccione una opción</option>
                            @foreach ($measurement_units as $measurement_unit)
                                <option value="{{ $measurement_unit->id }}">{{ $measurement_unit->measurement_unit }} </option>
                            @endforeach
                        </select>

                        <x-jet-input-error for="create_material_measurement_unit"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem; padding-right:1rem">
                        <x-jet-label>Precio Unitario:</x-jet-label>
                        <x-jet-input type="number" min="0" style="height:30px;width: 100%;text-align: center" wire:model="create_material_estimated_price" />

                        <x-jet-input-error for="create_material_estimated_price"/>

                    </div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem; padding-right:1rem">
                        <x-jet-label>Cantidad:</x-jet-label>
                        <x-jet-input type="number" min="0" style="height:30px;width: 100%;text-align: center" wire:model="create_material_quantity" />

                        <x-jet-input-error for="create_material_quantity"/>

                    </div>
                </div>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="agregarMaterialNuevo()">
                Guardar
            </x-jet-button>
            <div wire:loading wire:target="agregarMaterialNuevo()">
                Registrando...
            </div>
            <x-jet-button class="ml-2" wire:loading.attr="disabled" wire:click="$emit('confirmarRechazarMaterialNuevo','{{$material_nuevo_nombre}}')">
                Rechazar
            </x-jet-button>
            <x-jet-secondary-button wire:click="$set('open_detail_new_material',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!--------------------MODAL PARA AGREGAR MARCA-------------------------->
    <x-jet-dialog-modal maxWidth="sm" wire:model='open_add_new_brand'>
        <x-slot name="title">
            Agregar nueva marca
        </x-slot>
        <x-slot name="content">
            <div class="py-2 text-center" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Marca:</x-jet-label>
                <x-jet-input type="text" style="height:30px;width: 100%;text-align: center" wire:model="create_new_brand" />

                <x-jet-input-error for="create_new_brand"/>

            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="addNewBrand()">
                Guardar
            </x-jet-button>
            <div wire:loading wire:target="addNewBrand()">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_add_new_brand',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!---------------------------------------------------------------------------------------->
</div>
