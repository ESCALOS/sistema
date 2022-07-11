<div>
    <button wire:click="$set('open_pieza','true')" class="px-4 py-2 bg-red-500 hover:bg-red-700 text-white rounded-md w-full">
        Pieza
    </button>
    <x-jet-dialog-modal maxWidth="sm" wire:model="open_pieza">
        <x-slot name="title">
            Agregar Pieza
        </x-slot>
        <x-slot name="content">

            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Componente: </x-jet-label>
                <select id="component" class="form-select text-center" style="width: 100%" wire:model='component_for_part'>
                    <option value="">Seleccione una opción</option>
                    @foreach ($components as $component)
                        <option value="{{ $component->item_id }}">{{ $component->item }} </option>
                    @endforeach
                </select>

                <x-jet-input-error for="component_for_part"/>

            </div>

            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Pieza: </x-jet-label>
                    <select id="part" class="form-select text-center" style="width: 100%" wire:model='part_for_add'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($parts as $part)
                            <option value="{{ $part->item_id }}">{{ $part->item }} </option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="part_for_add"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">

                    <x-jet-label>Cantidad:</x-jet-label>
                    <x-jet-input type="number" min="0" class="text-center" style="height:30px;width: 100%" wire:model="quantity_part_for_add" />

                    <x-jet-input-error for="quantity_part_for_add"/>

                </div>

                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">

                    <x-jet-label>Stock:</x-jet-label>
                    <x-jet-input type="number" min="0" class="text-center" style="height:30px;width: 100%" wire:model="stock_part_for_add" />

                    <x-jet-input-error for="stock_part_for_add"/>

                </div>

        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Agregar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_pieza',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
