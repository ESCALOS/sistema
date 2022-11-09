<div class="text-center">
    <button wire:click="$set('open_new_material','true')" class="px-4 py-2 w-full bg-cyan-500 hover:bg-cyan-700 text-white rounded-md">
        Agregar
    </button>
    <x-jet-dialog-modal wire:model="open_new_material">
        <x-slot name="title">
            Agregar Nuevo Material
        </x-slot>
        <x-slot name="content">
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Nombre:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="material_new_item" />

                    <x-jet-input-error for="material_new_item"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; padding-right:1rem">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" min="0" style="height:30px;width: 100%" wire:model="material_new_quantity" />

                    <x-jet-input-error for="material_new_quantity"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Unidad de Medida: </x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='material_new_measurement_unit'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($measurement_units as $measurement_unit)
                            <option value="{{ $measurement_unit->id }}">{{ $measurement_unit->measurement_unit }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="material_new_measurement_unit"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                    <x-jet-label>Especificaciones:</x-jet-label>
                    <textarea class="form-control w-full text-sm" rows=4 wire:model.defer="material_new_datasheet"></textarea>

                    <x-jet-input-error for="material_new_datasheet"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Imagen:</x-jet-label>
                    <input type="file" style="height:30px;width: 100%" wire:model="material_new_image" id="upload{{$iteration}}" accept="image/*"/>

                    <x-jet-input-error for="material_new_image"/>

                </div>

                <div wire:loading wire:target='material_new_image' class="flex p-4 mb-4 text-sm text-blue-700 bg-blue-100 rounded-lg dark:bg-blue-200 dark:text-blue-800" style="grid-column: 2 span/ 2 span">
                    <div>
                        <strong class="font-bold">Imagen Cargando!</strong> <span class="block sm:inline">Espere a que termine de cargar.</span>
                    </div>
                </div>

                @if($material_new_image)
                    <div class="p-2" style="margin-left:15px;margin-right:15px;grid-column: 2 span/ 2 span;height:16rem">
                        <img style="display:inline;height:100%" src="{{ $material_new_image->temporaryUrl() }}">
                    </div>
                @endif
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_new_material',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>