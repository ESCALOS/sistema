<div>
    <!-- Título de Asignar materiales  -->
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl">Asignar materiales </h1>
    </div>
    <!-- Filtrar operarios que tienen pedidos por zona, sede y ubicación  -->
    <div class="grid grid-cols-1 sm:grid-cols-{{ $tlocation > 0 ? '4' : ($tsede > 0 ? '3' : ($tzone > 0 ? '2' : '1'))}} gap-4">
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
                @if ($tlocation != 0)
                    <div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Fecha Pedido:</x-jet-label>
                            <select class="form-select" style="width: 100%" wire:model='tlocation'>
                                <option value="0">Seleccione una opción</option>
                            @foreach ($order_dates as $order_date)
                                <option value="{{ $order_date->id }}">{{ $order_date->arrival_date }}</option>
                            @endforeach
                            </select>
                        </div>
                    </div>
                @endif
            @endif
        @endif
    </div>
<!-- Listar usuarios que tienen pedidos por validar  -->
    @if ($tfecha != 0 && $users->count())
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($users as $user)
    <!-- Cards de los usuarios con pedidos pendientes a validar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="{{ $user->lastname }}"/>
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $user->name }} {{ $user->lastname }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">Operario</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">Ver Pedido</button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
</div>