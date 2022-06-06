<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div x-data="{ open:false }">
                <div class="text-center mb-4" x-on:click="open = !open">
                    <x-jet-button>Filtros</x-jet-button>
                </div>
                <div x-show="open" class="bg-white shadow-md rounded my-6">
                    <div class="px-6 py-4 grid grid-cols-1 sm:grid-cols-3" wire:ignore>
                        <div class="px-6 py-2">
                            <label for="stractor">Tractor:</label><br>
                            <select id="stractor" class="select2" wire:model='stractor'>
                                <option value="">Seleccione el tractor</option>
                                @foreach ($tractors as $tractor)
                                    <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                        {{ $tractor->tractor_number }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="px-6 py-2">
                            <label for="slabor">Labor:</label><br>
                            <select id="slabor" class="select2" wire:model='slabor'>
                                <option value="">Seleccione la labor</option>
                                @foreach ($labors as $labor)
                                    <option value="{{ $labor->id }}">{{ $labor->labor }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="px-6 py-2">
                            <label for="simplement">Implemento:</label><br>
                            <select id="simplement" class="select2" wire:model='simplement'>
                                <option value="">Seleccione el implemento</option>
                                @foreach ($implements as $implement)
                                    <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                </div>
            </div>
            <div class="bg-white p-6 grid items-center" style="grid-template-columns: repeat(3, minmax(0, 1fr))">
                @livewire('create-tractor-scheduling')
                <div>
                    <div class="p-4">
                        <button type="button" wire:click="editar" class="w-full inline-flex items-center justify-center px-4 py-2 bg-amber-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-500 focus:outline-none focus:border-amber-700 focus:ring focus:ring-amber-200 active:bg-amber-600 disabled:opacity-25 transition">
                            Editar
                        </button>
                    </div>
                    <x-jet-dialog-modal wire:model="open_edit">
                        <x-slot name="title">
                            Editar reporte
                        </x-slot>
                        <x-slot name="content">
                            <div class="grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
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
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 1 /  span 2">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select id="location" class="form-select" style="width: 100%" wire:model.defer='location'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($locations as $location)
                            <option value="{{ $location->id }}">{{ $location->location }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="location"/>

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
                        <option value="">Seleccione una opción</option>
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
                    <button type="button" wire:click='anular()' class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Anular
                    </button>
                </div>
            </div>
            <div class="p-6">
                @if ($tractorSchedulings->count())
                <table class="min-w-max w-full table-fixed overflow-x-scroll">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Operario</span>
                                <img class="sm:hidden flex mx-auto" src="img/correlative.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Tractor</span>
                                <img class="sm:hidden flex mx-auto" src="img/tractor.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Labor</span>
                                <img class="sm:hidden flex mx-auto" src="img/labor.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Fecha</span>
                                <img class="sm:hidden flex mx-auto" src="img/date.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Turno</span>
                                <img class="sm:hidden flex mx-auto" src="img/shift.svg" alt="correlative"
                                    width="25">
                            </th>
                        </tr>
                    </thead>
                    <tbody  x-data="{open:false}" class="text-gray-600 text-sm font-light">
                        @foreach ($tractorSchedulings as $tractorScheduling)
                            <tr style="cursor:pointer" wire:click="seleccionar({{$tractorScheduling->id}})" class="border-b {{ $tractorScheduling->id == $idSchedule ? 'bg-blue-200' : '' }} border-gray-200">
                                <td class="py-3 px-6 text-left">
                                    <div class="flex items-center">
                                        <span class="font-medium">{{ $tractorScheduling->user->name }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-left">
                                    <div class="flex items-center">
                                        <span class="font-medium">{{ $tractorScheduling->tractor->tractorModel->model }}
                                            {{ $tractorScheduling->tractor->tractor_number }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-2 text-left">
                                    <div class="flex items-center">
                                        <span class="font-medium">{{ $tractorScheduling->labor->labor }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-2 text-left">
                                    <div class="flex items-center">
                                        <span class="font-medium">{{ $tractorScheduling->date }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-2 text-center">
                                    <div class="flex items-center justify-center">
                                        <img src="img/{{ $tractorScheduling->shift == 'MAÑANA' ? 'sun' : 'moon' }}.svg"
                                            alt="shift" width="25">
                                    </div>
                                </td>
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
                        {{ $tractorSchedulings->links() }}
                    </div>
            </div>
        </div>
    </div>
    <script>
        document.addEventListener('livewire:load', function() {
            $('.select2').select2();
            $('#stractor').on('change', function() {
                @this.set('stractor', this.value);
            });
            $('#slabor').on('change', function() {
                @this.set('slabor', this.value);
            });
            $('#simplement').on('change', function() {
                @this.set('simplement', this.value);
            });
        })

    </script>
</div>
