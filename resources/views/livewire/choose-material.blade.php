<div>
    <x-jet-dialog-modal wire:model="open">
        <x-slot name="title">
            Lista de Componentes
        </x-slot>
        <x-slot name="content">
            nada por ahora
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="addItems()">
                Guardar
            </x-jet-button>
            <x-jet-button wire:loading.attr="disabled" wire:click="cerrar()">
                Cerrar
            </x-jet-button>
            <div wire:loading wire:target="addItems">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_edit',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
