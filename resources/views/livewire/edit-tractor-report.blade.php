<div>
    <div class="p-4">
        <button type="button" wire:click="$set('open','true')" class="w-full inline-flex items-center justify-center px-4 py-2 bg-amber-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-500 focus:outline-none focus:border-amber-700 focus:ring focus:ring-amber-200 active:bg-amber-600 disabled:opacity-25 transition">
            Editar
        </button>
    </div>
    <x-jet-dialog-modal wire:model="open">
        <x-slot name="title">
            Regitrar Reporte de tractores {{$idReporte}}
        </x-slot>
        <x-slot name="content">

            <div class="grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                    <x-jet-label>Correlativo:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model.defer="correlative" />

                    <x-jet-input-error for="correlative"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Día:</x-jet-label>
                    <x-jet-input type="date" min="2022-05-18" style="height:30px;width: 100%" wire:model.defer="date"/>

                    <x-jet-input-error for="date"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Turno:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model.defer='shift'>
                        <option>MAÑANA</option>
                        <option>NOCHE</option>
                    </select>

                    <x-jet-input-error for="shift"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Operador:</x-jet-label>
                    <select id="user" class="form-select" style="width: 100%" wire:model.defer='user'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($users as $user)
                            <option value="{{ $user->id }}">{{ $user->name }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="user"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Tractor:</x-jet-label>
                    <select class="form-select" wire:model='tractor'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($tractors as $tractor)
                            <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                {{ $tractor->tractor_number }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="tractor"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Horometro Inicial: </x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" disabled value="{{ $horometro_inicial }}"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                    <x-jet-label>Horometro Final:</x-jet-label>
                    <x-jet-input type="number" style="height:30px;width: 100%" wire:model.defer="hour_meter_end" />

                    <x-jet-input-error for="hour_meter_end"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Implemento:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model.defer='implement'>
                        <option value="">Seleccione una opción</option>
                    @foreach ($implements as $implement)
                        <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                    @endforeach
                    </select>

                    <x-jet-input-error for="implement"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Labor:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model.defer='labor'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($labors as $labor)
                            <option value="{{ $labor->id }}">{{ $labor->labor }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="labor"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                    <x-jet-label>Observaciones:</x-jet-label>
                    <textarea class="form-control w-full text-sm" rows=6 wire:model.defer="observations"></textarea>
                </div>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Guardar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
