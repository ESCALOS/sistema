<div>
    <button wire:click="$set('open_material','true')" class="px-4 py-2 bg-amber-500 hover:bg-amber-700 text-white rounded-md w-full">
        Material
    </button>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_material">
        <x-slot name="title">
            Agregar Material
        </x-slot>
        <x-slot name="content">
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Componente: </x-jet-label>
                <select class="select2 text-center" id="material_for_add" style="width: 100%" wire:model='material_for_add'>
                    <option value="0">Seleccione una opción</option>
                    @foreach ($components as $component)
                        <option value="{{ $component->id }}"> {{$component->sku}} - {{ $component->item }} </option>
                    @endforeach
                </select>

                <x-jet-input-error for="material_for_add"/>

            </div>
            @if($material_for_add > 0)
            <div class="grid grid-cols-2">
                <div class="mb-4">
                    <x-jet-label class="text-md">En Proceso:</x-jet-label>
                    <div class="flex px-4">

                        <input readonly class="text-center border-gray-300 bg-amber-600 text-white font-bold text-lg focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" value="{{$ordered_quantity}}"/>

                        <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                            {{$measurement_unit}}
                        </span>
                    </div>
                </div>

                <div class="mb-4">
                    <x-jet-label class="text-md">Stock:</x-jet-label>
                    <div class="flex px-4">

                        <input readonly class="text-center border-gray-300 bg-green-600 text-white font-bold text-lg focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="text" style="height:30px;width: 100%" value="{{$stock}}"/>

                        <span class="inline-flex items-center px-3 text-sm text-gray-900 bg-gray-200 border border-r-0 border-gray-300 rounded-r-md dark:bg-gray-600 dark:text-gray-400 dark:border-gray-600">
                            {{$measurement_unit}}
                        </span>
                    </div>
                </div>
            </div>
            <div class="mb-4">
                <x-jet-label class="text-md">Solicitado:</x-jet-label>
                <div class="flex px-4">

                    <input class="text-center border-gray-300 bg-red-600 text-white font-bold text-lg focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 rounded-l-md shadow-sm" type="number" min="0" style="height:30px;width: 100%" wire:model="quantity_material_for_add"/>

                    <x-jet-input-error for="quantity_material_for_add"/>
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
            <x-jet-secondary-button wire:click="$set('open_material',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    <script>
        $('#material_for_add').on('change', function() {
            @this.set('material_for_add', this.value);
        });
    </script>
</div>
