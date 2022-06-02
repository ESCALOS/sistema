<div>
    <x-jet-danger-button class="w-full" wire:click="$set('open',true)">
        Registrar
    </x-jet-danger-button>

    <x-jet-dialog-modal wire:model='open'>
        <x-slot name="title">
            Registrar Reporte de Tractores
        </x-slot>

        <x-slot name="content">

            <div class="grid grid-cols-1 sm:grid-cols-3">
                    <div class="py-4">
                        <label for="tractor">Tractor:</label><br>
                        <select id="tractor" class="select2" wire:model='tractor'>
                            <option value="">Seleccione el tractor</option>
                            @foreach ($tractors as $tractor)
                                <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                    {{ $tractor->tractor_number }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="py-4">
                        <label for="labor">Labor:</label><br>
                        <select id="labor" class="select2" wire:model='labor'>
                            <option value="">Seleccione la labor</option>
                            @foreach ($labors as $labor)
                                <option value="{{ $labor->id }}">{{ $labor->labor }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="py-4">
                        <label for="implement">Implemento:</label><br>
                        <select id="implement" class="select2" wire:model='implement'>
                            <option value="">Seleccione el implemento</option>
                            @foreach ($implements as $implement)
                                <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                            @endforeach
                        </select>
                    </div>
        </x-slot>

        <x-slot name="footer">
            <x-jet-secondary-button wire:click="$toggle('open')">
                Cancelar
            </x-jet-secondary-button>
            <x-jet-danger-button class="ml-2" wire:click="$toggle('open')">
                Registrar
            </x-jet-danger-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
