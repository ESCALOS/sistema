<div>
    <button wire:click="$set('open_material','true')" style="width: 150px" class="px-4 py-2 bg-amber-500 hover:bg-amber-700 text-white rounded-md">
        Material
    </button>
    <x-jet-dialog-modal wire:model="open_material">
        <x-slot name="title">
            Agregar Material
        </x-slot>
        <x-slot name="content">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Componente: </x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='material_for_add'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($components as $component)
                            <option value="{{ $component->id }}">{{ $component->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="material_for_add"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model="quantity_material_for_add" />

                    <x-jet-input-error for="quantity_material_for_add"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Precio Aproximado: </x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" disabled value="{{ $estimated_price_material }}"/>

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
