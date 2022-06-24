<div>
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
                    <div class="h-32 md:h-16 w-full p-4 text-white text-2xl font-black bg-red-600 rounded-lg">
                        EL MONTO REBASA AL ASIGNADO
                    </div>
                </div>
            @endif
        </div>
    </div>
    <div class="grid grid-cols-1 {{$idImplemento!=0?'sm:grid-cols-2':''}} gap-4">
        <div>
            <div class="text-center">
                <h1 class="text-lg font-bold pb-2">
                    FECHA DE LLEGADA : {{strtoupper(strftime("%B de %Y", strtotime($fecha_pedido_llegada)))}}
                </h1>
            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <select class="form-select" style="width: 100%; height:2.5rem" wire:model='idImplemento'>
                    <option value="0" class="text-center text-md font-bold">Seleccione una implemento</option>
                @foreach ($implements as $implement)
                    <option value="{{ $implement->id }}" class="text-center text-md font-bold">Implemento: {{ strtoupper($implement->implementModel->implement_model) }} {{ $implement->implement_number }}</option>
                @endforeach
                </select>
            </div>
        </div>
        @if ($idImplemento != 0)
        <div style="display:flex; align-items:center;justify-content:center" class="px-6 py-4">
            <button wire:click="$emit('confirmarCerrarPedido','pxwuxakalx 6977')" class="w-full h-16 bg-orange-500 text-2xl font-bold hover:bg-orange-700 text-white rounded-full">
                Cerrar Pedido
            </button>
        </div>
        @endif
    </div>
    <div class="px-6 py-4 text-center">
        @if ($idImplemento > 0)
    <!-- Crud Materiales Existentes -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <!-------GRID DE BOTONES PARA AGREGAR MATERIALES -->
            <div style="height:280px">
                <div class="text-center">
                    <h1 class="text-md font-bold pb-4">Añadir a la solicitud:</h1>
                </div>
                <div class="p-4 grid grid-cols-1 sm:grid-cols-2 gap-4 text-center">
                    @livewire('add-component', ['idRequest' => $idRequest, 'idImplemento' => $idImplemento])
                    @livewire('add-part',  ['idRequest' => $idRequest, 'idImplemento' => $idImplemento])
                    @livewire('add-material',  ['idRequest' => $idRequest, 'idImplemento' => $idImplemento])
                    @livewire('add-tool',  ['idRequest' => $idRequest, 'idImplemento' => $idImplemento])
                </div>
            </div>
            <!-------TABLA DE MATERIALES PEDIDOS YA EXISTENTES -->
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
                        @foreach ($orderRequestDetails as $request)
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
        </div>
    <!-- Botones para elementos nuevos -->
        <div class="bg-white p-6 grid text-center gap-4" style="grid-column: 2 span/ 2 span">
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    @livewire('request-new-material', ['idRequest' => $idRequest, 'idImplemento' => $idImplemento])
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
        <div style="height:360px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Material Nuevo </span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Marca </span>
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
                                    <span class="font-bold">{{ strtoupper($request->brand) }}</span>
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
            <h1 class="text-3xl font-bold pb-4">NINGÚN IMPLEMENTO SELECCIONADO</h1>
        </div>
        @endif
    </div>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_edit">
        <x-slot name="title">
            {{ strtoupper($material_edit_name) }}
        </x-slot>
        <x-slot name="content">
            <div>

            </div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                <x-jet-label class="text-md">Cantidad:</x-jet-label>
                <x-jet-input type="number" min="0" style="height:30px;width: 100%" wire:model="quantity_edit" />

                <x-jet-input-error for="quantity_edit"/>

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
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
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
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Marca:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="material_new_edit_brand" />

                    <x-jet-input-error for="material_new_edit_brand"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 3 span/ 3 span">
                    <x-jet-label>Especificaciones:</x-jet-label>
                    <textarea class="form-control w-full text-sm" rows=5 wire:model.defer="material_new_edit_datasheet"></textarea>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 3 span/ 3 span">
                    <x-jet-label>Imagen:</x-jet-label>
                    <input type="file" style="height:30px;width: 100%" wire:model="material_new_edit_image" accept="image/*"/>

                    <x-jet-input-error for="material_new_edit_image"/>

                </div>

                <div wire:loading wire:target='material_new_edit_image' class="flex p-4 mb-4 text-sm text-blue-700 bg-blue-100 rounded-lg dark:bg-blue-200 dark:text-blue-800" style="grid-column: 3 span/ 3 span">
                    <div>
                        <strong class="font-bold">Imagen Cargando!</strong> <span class="block sm:inline">Espere a que termine de cargar.</span>
                    </div>
                </div>

                @if($material_new_edit_image)
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 3 span/ 3 span">
                        <img src="{{ $material_new_edit_image->temporaryUrl() }}" class="w-full">
                    </div>
                @else
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 3 span/ 3 span">
                        <img src="{{ str_replace('public','/storage',$material_new_edit_image_old) }}" class="w-full">
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
</div>
</div>
