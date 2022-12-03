<div class="pt-4">
    <div style="padding-left: 1rem; padding-right:1rem; grid-column: 3 span/ 3 span" x-data="{ open:false }">
        <div class="text-center mb-4" x-on:click="open = !open">
            <x-jet-button>Filtros</x-jet-button>
        </div>
        <div x-show="open" class="bg-white shadow-md rounded my-6">
            <div class="px-6 py-4 grid grid-cols-1 sm:grid-cols-4" wire:ignore>
                <div class="px-6 py-2">
                    <label for="subicacion">Código:</label><br>
                    <input type="text" wire:model='scodigo'>
                </div>
                <div class="px-6 py-2">
                    <label for="subicacion">DNI:</label><br>
                    <input type="text" wire:model='sdni'>
                </div>
                <div class="px-6 py-2">
                    <label for="subicacion">Nombre o Apellido:</label><br>
                    <input type="text" wire:model='snombre'>
                </div>
                <div class="px-6 py-2">
                    <label for="subicacion">Ubicación:</label><br>
                    <select id="subicacion" class="select2" wire:model='subicacion'>
                        <option value="">Seleccione la ubicación</option>
                        @foreach ($locations as $location)
                        <option value="{{ $location->id }}">{{ $location->location }}</option>
                        @endforeach
                    </select>
                </div>
            </div>
        </div>
    </div>
    <div class="bg-white p-6 grid grid-cols-3 items-center">
        @livewire('overseer.tractor-scheduling.create-tractor-scheduling')
        <div>
            <div class="p-4">
                <button type="button" wire:click="editar" {{ $idSchedule > 0 ? '' : 'disabled' }} class="w-full inline-flex items-center justify-center px-4 py-2 bg-amber-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-500 focus:outline-none focus:border-amber-700 focus:ring focus:ring-amber-200 active:bg-amber-600 disabled:opacity-25 transition">
                    Editar
                </button>
            </div>
            <x-jet-dialog-modal wire:model="open_edit">
                <x-slot name="title">
                    Editar reporte
                </x-slot>
                <x-slot name="content">
                    <div class="grid grid-cols-1 sm:grid-cols-2">
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Día:</x-jet-label>
                            <x-jet-input readonly type="date" min="2022-05-18" style="height:40px;width: 100%" value="{{$date}}"/>

                            <x-jet-input-error for="date"/>
                        </div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Turno:</x-jet-label>
                            <x-jet-input readonly type="text" style="height:30px;width: 100%" value="{{$shift}}"/>

                            <x-jet-input-error for="shift"/>

                        </div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Ubicación:</x-jet-label>

                            <x-jet-input readonly type="text" style="height:30px;width: 100%" value="{{$location_name}}"/>

                            <x-jet-input-error for="location"/>

                        </div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Lote:</x-jet-label>

                            <x-jet-input readonly type="text" style="height:30px;width: 100%" value="{{$lote_name}}"/>

                            <x-jet-input-error for="lote"/>

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
                            <select id="tractor" class="form-select" style="width: 100%" wire:model.defer='tractor'>
                                <option value="0">Seleccione una opción</option>
                                @foreach ($tractors as $tractor)
                                    <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                        {{ $tractor->tractor_number }}</option>
                                @endforeach
                            </select>

                            <x-jet-input-error for="tractor"/>

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
                    </div>
                </x-slot>
                <x-slot name="footer">
                    <x-jet-button wire:loading.attr="disabled" wire:click="actualizar()">
                        Guardar
                    </x-jet-button>
                    <div wire:loading wire:target="actualizar">
                        Registrando...
                    </div>
                    <x-jet-secondary-button wire:click="$set('open_edit',false)" class="ml-2">
                        Cancelar
                    </x-jet-secondary-button>
                </x-slot>
            </x-jet-dialog-modal>
        </div>
        <div class="p-4">
            <button type="button" wire:click='anular()' {{ $idUser > 0 ? '' : 'disabled' }} class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                Anular
            </button>
        </div>
    </div>
    @if ($users->count())
    <table class="table table-fixed w-full">
        <thead class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
            <tr>
                <th class="py-3 text-center">Código</th>
                <th class="py-3 text-center">DNI</th>
                <th class="py-3 text-center">Nombre y Apellido</th>
                <th class="py-3 text-center">Ubicación</th>
            </tr>
        </thead>
        <tbody class="text-gray-600 text-sm font-light">
            @foreach ($users as $user)
            <tr style="cursor:pointer" wire:click="seleccionar({{$user->id}})" class="border-b {{ $user->id == $idUser ? 'bg-blue-200' : '' }} border-gray-200">
                <td class="py-3 text-center">{{ $user->code }}</td>
                <td class="py-3 text-center">{{ $user->dni }}</td>
                <td class="py-3 text-center">{{ $user->name }} {{ $user->lastname }}</td>
                <td class="py-3 text-center">{{ $user->location->location }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
    @else
    <div class="text-center">
        <h1 class="text-gray-500">No hay registros</h1>
    </div>
    @endif
    <div class="px-4 py-4">
        {{ $users->links() }}
    </div>
    
</div>
