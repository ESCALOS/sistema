<div>
    <button wire:click="$set('open_parte','true')" class="px-4 py-2 bg-red-500 hover:bg-red-700 text-white rounded-md w-full">
        Pieza
    </button>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_parte">
        <x-slot name="title">
            Agregar pieza
        </x-slot>
        <x-slot name="content">
                <div class="mb-4" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Componente: </x-jet-label>
                    <select wire:model='component_for_part' class="form-select text-center" style="width: 100%">
                        <option value="0">Seleccione una opción</option>
                        @foreach ($components as $component)
                            <option value="{{ $component->item_id }}">{{ $component->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="component_for_part"/>

                </div>
                @if($component_for_part > 0)
                <div class="mb-4" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Pieza: </x-jet-label>
                    <select wire:model='part_for_add' class="form-select text-center" style="width: 100%">
                        <option value="0">Seleccione una opción</option>
                        @foreach ($parts as $part)
                            <option value="{{ $part->item_id }}">{{ $part->part }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="part_for_add"/>

                </div>
                @if($part_for_add > 0)
                <div class="mb-4">
                    <x-jet-label class="text-md">Cantidad:</x-jet-label>
                    <div class="flex px-4">

                        <input class="text-center border-gray-300 focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="quantity_part_for_add"/>

                        <x-jet-input-error for="quantity_part_for_add"/>
                        <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                            {{$measurement_unit}}
                        </span>
                    </div>
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
                @endif
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_parte',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
