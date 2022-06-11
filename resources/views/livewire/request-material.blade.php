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
                            <tr style="cursor:pointer" wire:dblclick="editar({{$request->id}})" class="border-b border-gray-200">
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
                                <span>Material Nuevo </span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($orderRequestNewItems as $request)
                        <tr style="cursor:pointer" wire:dblclick="seleccionar_material_nuevo({{$request->id}})" class="border-b {{ $request->id == $material_nuevo_seleccionado ? 'bg-blue-200' : '' }} border-gray-200">
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-bold">{{ strtoupper($request->new_item) }}</span>
                                </div>
                            </td>
                            <td class="py-3 px-6 text-center">
                                <div>
                                    <span class="font-medium">{{$request->quantity}} </span>
                                </div>
                            </td>
                        </tr>
                    @endforeach
                    </tbody>
                </table>
            </div>
            <div style="height:180px;overflow:auto">
                <div class="text-center">
                    <h1 class="text-md font-bold pb-4">Añadir a la solicitud:</h1>
                </div>
                <div class="p-6 grid grid-cols-1 sm:grid-cols-2 gap-4 text-center">
                    <div>
                        <button class="px-4 py-2 w-48 bg-green-500 hover:bg-green-700 text-white rounded-md">Agregar Componente</button>
                    </div>
                    <div>
                        <button class="px-4 py-2 w-48 bg-red-500 hover:bg-red-700 text-white rounded-md">Agregar Pieza</button>
                    </div>
                    <div>
                        <button class="px-4 py-2 w-48 bg-amber-500 hover:bg-amber-700 text-white rounded-md">Agregar Material</button>
                    </div>
                    <div>
                        <button class="px-4 py-2 w-48 bg-blue-500 hover:bg-blue-700 text-white rounded-md">Agregar Herramienta</button>
                    </div>
                </div>
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
            Modificar componente {{ $material_edit_name }}
        </x-slot>
        <x-slot name="content">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model="cantidad_edit" />

                    <x-jet-input-error for="cantidad_edit"/>

                </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="actualizar()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="actualizar">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_edit',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
