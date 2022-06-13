<div>
    <div class="text-center">
        <h1 class="text-2xl font-bold pb-4">Solicitud de Pedido : {{strtoupper($implemento)}} </h1>
    </div>
    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
        <select class="form-select" style="width: 100%" wire:model='idImplemento'>
            <option value="0">Seleccione una implemento</option>
        @foreach ($implements as $implement)
            <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
        @endforeach
        </select>
    </div>
    <div class="px-6 py-4">
        @if ($idImplemento > 0)
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div style="height:180px;overflow:auto">
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
            <div style="height:180px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
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
            <div style="height:200px;overflow:auto;">
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
                        <tr wire:dblclick='editar_nuevo({{$request->id}})' class="border-b border-gray-200 unselected">
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-bold">{{ strtoupper($request->new_item) }}</span>
                                </div>
                            </td>
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-medium">{{$request->quantity}} {{$request->measurementUnit->measurement_unit}} </span>
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
            <h1 class="text-2xl font-bold pb-4">NINGÚN IMPLEMENTO SELECCIONADO</h1>
        </div>
        @endif
    </div>
    <x-jet-dialog-modal wire:model="open_edit">
        <x-slot name="title">
            {{ strtoupper($material_edit_name) }}
        </x-slot>
        <x-slot name="content">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model="quantity_edit" />

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
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model="material_new_edit_quantity" />

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
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Imagen:</x-jet-label>
                    <x-jet-input type="file" style="height:30px;width: 100%" wire:model="material_new_edit_image" />

                    <x-jet-input-error for="material_new_edit_image"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 3 span/ 3 span">
                    <x-jet-label>Observaciones:</x-jet-label>
                    <textarea class="form-control w-full text-sm" rows=5 wire:model.defer="material_new_edit_observation"></textarea>
                </div>
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
