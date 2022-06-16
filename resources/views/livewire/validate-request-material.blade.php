<div>
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">PEDIDO DE JULIO</h1>
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Zona:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='tzone'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($zones as $zone)
                    <option value="{{ $zone->id }}">{{ $zone->zone }}</option>
                @endforeach
                </select>
            </div>
        </div>
        @if ($tzone != 0)
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Sede:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='tsede'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($sedes as $sede)
                    <option value="{{ $sede->id }}">{{ $sede->sede }}</option>
                @endforeach
                </select>
            </div>
        </div>
            @if($tsede != 0)
            <div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='tlocation'>
                        <option value="0">Seleccione una zona</option>
                    @foreach ($locations as $location)
                        <option value="{{ $location->id }}">{{ $location->location }}</option>
                    @endforeach
                    </select>
                </div>
            </div>
            @endif
        @endif

        @if ($tlocation != 0)
            <div class="grid grid-cols-3 sm:grid-cols-6 gap-4 p-6">
                @foreach ($users as $user)
                    <div>
                        {{$user->name}}
                    </div>
                @endforeach
            </div>
        @endif
</div>
