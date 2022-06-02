<div class="p-4">
    <button type="button" wire:click="$set('open','true')" class="w-full inline-flex items-center justify-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-500 focus:outline-none focus:border-green-700 focus:ring focus:ring-green-200 active:bg-green-600 disabled:opacity-25 transition">
        Registrar
    </button>
    <x-jet-dialog-modal wire:model="open" class="bg-blue-500">
        <x-slot name="title" class="bg-red-500">
            Regitrar Reporte de tractores
        </x-slot>
        <x-slot name="content">

            <div class="grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                    <x-jet-label>Correlativo:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" />
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Día:</x-jet-label>
                    <x-jet-input type="date" id="date" min="2022-05-18" style="height:30px;width: 100%"/>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Turno:</x-jet-label>
                    <select id="shift" class="select2" style="width: 100%" wire:model='shift'>
                        <option value="">Seleccione una opción</option>
                        <option>MAÑANA</option>
                        <option>NOCHE</option>
                    </select>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Operador:</x-jet-label>
                    <select id="user" class="select2" style="width: 100%" wire:model='tractor'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($users as $user)
                            <option value="{{ $user->id }}">{{ $user->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Tractor:</x-jet-label>
                    <select id="tractor" class="select2" style="width: 100%" wire:model='tractor'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($tractors as $tractor)
                            <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                {{ $tractor->tractor_number }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Labor:</x-jet-label>
                    <select id="labor" class="select2" style="width: 100%" wire:model='labor'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($labors as $labor)
                            <option value="{{ $labor->id }}">{{ $labor->labor }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Implemento:</x-jet-label>
                    <select id="implement" class="select2" style="width: 100%" wire:model='implement'>
                        <option value="">Seleccione una opción</option>
                    @foreach ($implements as $implement)
                        <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                    @endforeach
                    </select>
                </div>
            </div>
        </x-slot>
        <x-slot name="footer">

        </x-slot>
    </x-jet-dialog-modal>
</div>
