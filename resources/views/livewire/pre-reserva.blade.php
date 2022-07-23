<div>
    @if($fecha_pre_reserva != "")
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <div class="grid grid-cols-1 gap-4">
            <div class="text-center">
                <h1 class="font-bold text-4xl">
                    PEDIDO DEL MES DE {{strtoupper(strftime("%B de %Y", strtotime($fecha_pre_reserva)))}}
                </h1>
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
    <div class="grid grid-cols-1 {{$id_implemento!=0 ? 'sm:grid-cols-2' : ''}} gap-4">
        <div style="display:flex; align-items:center;justify-content:center">
            <div class="py-2 w-full" style="padding-left: 1rem; padding-right:1rem">
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
            <button wire:click="$emit('confirmarCerrarPreReserva','{{$implemento}}')" class="w-full h-16 bg-orange-500 text-2xl font-bold hover:bg-orange-700 text-white rounded-full">
                Cerrar Pre-reserva
            </button>
        </div>
        @endif
    </div>
    <div class="px-6 py-4 text-center">
        @if ($id_implemento > 0)
    <!-- Crud Materiales Existentes -->
        <div>
        <!-------GRID DE BOTONES PARA AGREGAR MATERIALES -->
            <div class="pb-2">
                <div class="text-center">
                    <h1 class="text-md font-bold">Añadir a la solicitud:</h1>
                </div>
                <div class="p-4 grid grid-cols-2 sm:grid-cols-4 gap-4 text-center">
                    @livewire('add-component-pre-reserva', ['id_pre_reserva' => $id_pre_reserva, 'id_implemento' => $id_implemento])
                    @livewire('add-part-pre-reserva', ['id_pre_reserva' => $id_pre_reserva, 'id_implemento' => $id_implemento])
                    @livewire('add-material-pre-reserva', ['id_pre_reserva' => $id_pre_reserva, 'id_implemento' => $id_implemento])
                    @livewire('add-tool-pre-reserva', ['id_pre_reserva' => $id_pre_reserva, 'id_implemento' => $id_implemento])
                </div>
            </div>
            <!-------TABLA DE MATERIALES PEDIDOS YA EXISTENTES -->
            <div style="height:240px;overflow:auto">
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
                                <span>Requedio</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Stock</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($pre_stockpile_details as $request)
                            <tr wire:click="editar({{$request->id}})" class="border-b border-gray-200 unselected">
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
                                        <span class="font-medium">{{$request->quantity}} {{$request->abbreviation}}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->ordered_quantity - $request->used_quantity}} {{$request->abbreviation}}</span>
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

            <div class="mb-2">
                <x-jet-label class="text-md">Cantidad:</x-jet-label>
                <div class="flex" style="padding-left: 1rem; padding-right:1rem;">

                    <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" max="{{$material_stock_edit}}" style="height:30px;width: 100%" wire:model="material_edit_quantity" />

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$material_measurement_edit}}
                    </span>
                </div>

                <x-jet-input-error for="material_edit_quantity"/>
            </div>

            <div class="mb-2">
                <x-jet-label class="text-md">Stock:</x-jet-label>
                <div class="flex" style="padding-left: 1rem; padding-right:1rem;">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="material_stock_edit" />

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$material_measurement_edit}}
                    </span>
                </div>
                <x-jet-input-error for="material_stock_edit"/>
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
    @else
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <div class="text-center">
            <h1 class="font-bold text-4xl">
                NO HAY PRE-RESERVAS ABIERTAS
            </h1>
        </div>
    </div>
    @endif
</div>
