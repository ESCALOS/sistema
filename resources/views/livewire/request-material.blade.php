<div>
    @if($fecha_pedido != "")
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <div class="grid grid-cols-1 gap-4">
            <div class="text-center">
                <h1 class="font-bold text-4xl">
                    PEDIDO {{strtoupper(strftime("%B de %Y", strtotime($fecha_pedido)))}}
                </h1>
            </div>
            <div class="grid grid-cols-1 gap-4">
                <div class="text-center">
                    <h1 class="font-bold text-xl">
                        Abierto del {{strftime("%d", strtotime($fecha_pedido_abierto))}} al {{strftime("%d de %B de %Y", strtotime($fecha_pedido_cierre))}}
                    </h1>
                </div>
            </div>
            @if ($monto_usado > $monto_asignado)
                <div class="mt-4 mx-6 px-6 cursor-default" title="Este monto es calculado de todos las solicitudes del ceco" >
                    <div class="w-full p-4 text-white text-center text-2xl font-black bg-red-600 rounded-lg">
                        EL MONTO REBASA AL ASIGNADO
                    </div>
                </div>
            @endif
        </div>
    </div>
    <div class="grid grid-cols-1 {{$id_implemento!=0?'sm:grid-cols-2':''}} gap-4">
        <div>
            <div class="text-center">
                <h1 class="text-lg font-bold pb-2">
                    FECHA DE LLEGADA : {{strtoupper(strftime("%B de %Y", strtotime($fecha_pedido_llegada)))}}
                </h1>
            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <select class="form-select" style="width: 100%; height:2.5rem" wire:model='id_implemento'>
                    <option value="0" class="text-center text-md font-bold">Seleccione una implemento</option>
                @foreach ($implements as $implement)
                    <option value="{{ $implement->id }}" class="text-center text-md font-bold">Implemento: {{ strtoupper($implement->implementModel->implement_model) }} {{ $implement->implement_number }}</option>
                @endforeach
                </select>
            </div>
        </div>
        @if ($id_implemento != 0)
        <div style="display:flex; align-items:center;justify-content:center" class="px-6 py-4">
            <button wire:click="$emit('confirmarCerrarPedido','{{$implemento}}')" class="w-full h-16 bg-orange-500 text-2xl font-bold hover:bg-orange-700 text-white rounded-full">
                Cerrar Pedido
            </button>
        </div>
        @endif
    </div>
    <div class="px-6 py-4 text-center">
        @if ($id_implemento > 0)
    <!-------GRID DE BOTONES PARA AGREGAR MATERIALES -->
        <div>
                <div class="text-center">
                    <h1 class="text-md font-bold">Añadir a la solicitud:</h1>
                </div>
                <div class="p-4 grid grid-cols-2 sm:grid-cols-4 gap-4 text-center">
                    @livewire('add-component', ['id_request' => $id_request, 'id_implemento' => $id_implemento])
                    @livewire('add-part',  ['id_request' => $id_request, 'id_implemento' => $id_implemento])
                    @livewire('add-material',  ['id_request' => $id_request, 'id_implemento' => $id_implemento])
                    @livewire('add-tool',  ['id_request' => $id_request, 'id_implemento' => $id_implemento])
                </div>
        </div>
        <div>
            <!-------TABLA DE MATERIALES PEDIDOS YA EXISTENTES -->
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
                            <th class="py-3 text-center">
                                <span>Pedido</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Stock</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($orderRequestDetails as $request)
                            <tr wire:dblclick="editar({{$request->id}})" class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->sku}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-bold {{$request->type == "PIEZA" ? 'text-red-500' : ( $request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">{{ strtoupper($request->item) }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{floatVal($request->quantity)}} {{$request->abbreviation}}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{floatVal($request->ordered_quantity - $request->used_quantity)}} {{$request->abbreviation}}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{floatVal($request->stock)}} {{$request->abbreviation}}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
    <!-- Botones para elementos nuevos -->
        <div class="bg-white p-6 grid text-center gap-4" style="grid-column: 2 span/ 2 span">
                <div class="grid grid-cols-3 gap-4">
                    @livewire('request-new-material', ['id_request' => $id_request, 'id_implemento' => $id_implemento])
                    <div>
                        <button wire:click="editar_nuevo()" class="px-4 py-2 w-full bg-yellow-500 hover:bg-yellow-700 text-white rounded-md">
                            Editar
                        </button>
                    </div>
                    <div>
                        <button wire:click="eliminar_nuevo()" class="px-4 py-2 w-full bg-orange-500 hover:bg-orange-700 text-white rounded-md">
                            Eliminar
                        </button>
                    </div>
                </div>
            </div>
        <div>
    <!-- Tabla para elementos nuevos -->
        <div style="max-height:360px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Material Nuevo </span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($orderRequestNewItems as $request)
                        <tr wire:click='seleccionar({{$request->id}})' class="border-b {{ $request->id == $material_new_edit ? 'bg-blue-200' : '' }} border-gray-200 unselected">
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-bold">{{ strtoupper($request->new_item) }}</span>
                                </div>
                            </td>
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-medium">{{$request->quantity}} {{$request->measurementUnit->abbreviation}} </span>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                    </tbody>
                </table>
            </div>
        </div>
        @else
        <div class="px-6 py-4 text-center">
            <h1 class="text-3xl font-bold pb-4">NINGÚN IMPLEMENTO SELECCIONADO </h1>
        </div>
        @endif
    </div>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_edit">
        <x-slot name="title">
            {{ strtoupper($material_edit_name) }}
        </x-slot>
        <x-slot name="content">

            <div class="mb-4">
                <x-jet-label class="text-md">Cantidad:</x-jet-label>
                <div class="flex">

                    <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="quantity_edit"/>

                    <x-jet-input-error for="quantity_edit"/>
                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit_edit}}
                    </span>
                </div>
            </div>

            <div class="mb-4">
                <x-jet-label class="text-md">Pedida:</x-jet-label>
                <div class="flex">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" value="{{$ordered_quantity}}"/>

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit_edit}}
                    </span>
                </div>
            </div>

            <div class="mb-4">
                <x-jet-label class="text-md">En Almacén:</x-jet-label>
                <div class="flex">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="text" style="height:30px;width: 100%" value="{{$stock}}"/>

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit_edit}}
                    </span>
                </div>
            </div>

        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="actualizar()">
                Actualizar
            </x-jet-button>
            <div wire:loading wire:target="actualizar">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_edit',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>

    <x-jet-dialog-modal wire:model="open_edit_new">
        <x-slot name="title">
            {{ strtoupper($material_new_edit_name) }}
        </x-slot>
        <x-slot name="content">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" min="0" style="height:30px;width: 100%" wire:model="material_new_edit_quantity" />

                    <x-jet-input-error for="material_new_edit_quantity"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Unidad de Medida: </x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='material_new_edit_measurement_unit'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($measurement_units as $measurement_unit)
                            <option value="{{ $measurement_unit->id }}">{{ $measurement_unit->measurement_unit }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="material_new_edit_measurement_unit"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                    <x-jet-label>Especificaciones:</x-jet-label>
                    <textarea class="form-control w-full text-sm" rows=5 wire:model.defer="material_new_edit_datasheet"></textarea>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Imagen:</x-jet-label>
                    <input type="file"  id="upload{{$iteration}}" style="height:30px;width: 100%" wire:model="material_new_edit_image" accept="image/*"/>

                    <x-jet-input-error for="material_new_edit_image"/>

                </div>

                <div wire:loading wire:target='material_new_edit_image' class="flex p-4 mb-4 text-sm text-blue-700 bg-blue-100 rounded-lg dark:bg-blue-200 dark:text-blue-800" style="grid-column: 2 span/ 2 span">
                    <div>
                        <strong class="font-bold">Imagen Cargando!</strong> <span class="block sm:inline">Espere a que termine de cargar.</span>
                    </div>
                </div>

                @if($material_new_edit_image)
                <div class="p-2" style="margin-left:15px;margin-right:15px;grid-column: 3 span/ 3 span;max-height:16rem">
                        <img style="display:inline;height:100%" src="{{ $material_new_edit_image->temporaryUrl() }}">
                    </div>
                @else
                    <div class="p-2" style="margin-left:15px;margin-right:15px;grid-column: 3 span/ 3 span;max-height:16rem">
                        <img style="display:inline;height:100%" src="{{ str_replace('public','/storage',$material_new_edit_image_old) }}">
                    </div>
                @endif
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="actualizar_nuevo()">
                Actualizar
            </x-jet-button>
            <div wire:loading wire:target="actualizar_nuevo">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_edit_new',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    @else
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <div class="text-center">
            <h1 class="font-bold text-4xl">
                NO HAY PEDIDOS ABIERTOS
            </h1>
        </div>
    </div>
    @endif
</div>
