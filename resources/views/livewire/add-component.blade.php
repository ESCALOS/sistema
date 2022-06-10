<div>
    <button wire:click="$set('open_componente','true')" class="px-4 py-2 w-48 bg-green-500 hover:bg-green-700 text-white rounded-md">
        Agregar Componente
    </button>
    <x-jet-dialog-modal wire:model="open_componente">
        <x-slot name="title">
            Agregar componente
        </x-slot>
        <x-slot name="content">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Componente: </x-jet-label>
                    <select id="component" class="form-select" style="width: 100%" wire:model='component_for_add'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($components as $component)
                            <option value="{{ $component->item_id }}">{{ $component->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="componente_for_add"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model="quantity_component_for_add" />

                    <x-jet-input-error for="quantity_component_for_add"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Precio Aproximado: </x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" disabled value="{{ $estimated_price_component }}"/>

                </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_componente',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
