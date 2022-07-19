<div>
    <button wire:click="$set('open_tool','true')" class="px-4 py-2 bg-blue-500 hover:bg-blue-700 text-white rounded-md w-full">
        Herramienta
    </button>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_tool">
        <x-slot name="title">
            Agregar tool
        </x-slot>
        <x-slot name="content">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Componente: </x-jet-label>
                    <select class="form-select text-center" style="width: 100%" wire:model='tool_for_add'>
                        <option value="0">Seleccione una opción</option>
                        @foreach ($components as $component)
                            <option value="{{ $component->id }}">{{ $component->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="tool_for_add"/>

                </div>
                @if($tool_for_add > 0)
            <x-jet-label class="text-md">Cantidad:</x-jet-label>
            <div class="flex px-4">

                <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="quantity_tool_for_add"/>

                <x-jet-input-error for="quantity_tool_for_add"/>
                <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                    {{$measurement_unit}}
                </span>
            </div>

            <div class="mb-4">
                <x-jet-label class="text-md">Pedida:</x-jet-label>
                <div class="flex px-4">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" value="{{$ordered_quantity}}"/>

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit}}
                    </span>
                </div>
            </div>

            <div class="mb-4">
                <x-jet-label class="text-md">En Almacén:</x-jet-label>
                <div class="flex px-4">

                    <input readonly class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="text" style="height:30px;width: 100%" value="{{$stock}}"/>

                    <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                        {{$measurement_unit}}
                    </span>
                </div>
            </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_tool',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
