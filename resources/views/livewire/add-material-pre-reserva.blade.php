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
                    <x-jet-label>Material: </x-jet-label>
                    <select id="material" class="form-select text-center" style="width: 100%" wire:model='material_for_add'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($materials as $material)
                            <option value="{{ $material->id }}">{{ $material->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="material_for_add"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">

                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" min="0" class="text-center" style="height:30px;width: 100%" wire:model="quantity_material_for_add" />

                    <x-jet-input-error for="quantity_material_for_add"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">

                    <x-jet-label>Stock:</x-jet-label>
                    <x-jet-input type="number" readonly min="0" class="text-center" style="height:30px;width: 100%" wire:model="stock_material_for_add" />

                    <x-jet-input-error for="stock_material_for_add"/>

                </div>

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
</div>
