<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div class="grid grid-cols-1 sm:grid-cols-4">
                <div style="padding-left: 1rem; padding-right:1rem; grid-column: 3 span/ 3 span" x-data="{ open:false }">
                    <div class="text-center mb-4" x-on:click="open = !open">
                        <x-jet-button>Filtros</x-jet-button>
                    </div>
                    <div x-show="open" class="bg-white shadow-md rounded my-6">
                        <div class="px-6 py-4 grid grid-cols-1 sm:grid-cols-2" wire:ignore>
                            <div class="px-6 py-2">
                                <label for="stractor">Tractor:</label><br>
                                <select id="stractor" class="select2" wire:model='stractor'>
                                    <option value="">Seleccione el tractor</option>
                                    @foreach ($filtro_tractores as $tractor)
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
                                    @foreach ($filtro_implementos as $implement)
                                        <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="text-center mb-4" style="margin-right: 2.5rem">
                    <button wire:click="$set('open_print_schedule',true)" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-black hover:text-white bg-cyan-400 rounded-lg hover:bg-cyan-500">
                        <svg xmlns="http://www.w3.org/2000/svg"  viewBox="0 0 48 48" width="24px" height="24px">
                            <path d="M42.5,19.408H40V1.843c0-0.69-0.561-1.25-1.25-1.25H6.25C5.56,0.593,5,1.153,5,1.843v17.563H2.5 c-1.381,0-2.5,1.119-2.5,2.5v20c0,1.381,1.119,2.5,2.5,2.5h40c1.381,0,2.5-1.119,2.5-2.5v-20C45,20.525,43.881,19.408,42.5,19.408z M32.531,38.094H12.468v-5h20.063V38.094z M37.5,19.408H35c-1.381,0-2.5,1.119-2.5,2.5v5h-20v-5c0-1.381-1.119-2.5-2.5-2.5H7.5 V3.093h30V19.408z M32.5,8.792h-20c-0.69,0-1.25-0.56-1.25-1.25s0.56-1.25,1.25-1.25h20c0.689,0,1.25,0.56,1.25,1.25 S33.189,8.792,32.5,8.792z M32.5,13.792h-20c-0.69,0-1.25-0.56-1.25-1.25s0.56-1.25,1.25-1.25h20c0.689,0,1.25,0.56,1.25,1.25 S33.189,13.792,32.5,13.792z M32.5,18.792h-20c-0.69,0-1.25-0.56-1.25-1.25s0.56-1.25,1.25-1.25h20c0.689,0,1.25,0.56,1.25,1.25 S33.189,18.792,32.5,18.792z"/>
                        </svg>
                        <span class="ml-2">Imprimir Programación</span>
                    </button>
                </div>
            </div>
            <div class="bg-white p-6 grid grid-cols-3 items-center">
                @livewire('create-tractor-scheduling')
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
                    <button type="button" wire:click='anular()' {{ $idSchedule > 0 ? '' : 'disabled' }} class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Anular
                    </button>
                </div>
            </div>
            <div class="p-6">
                @if ($tractorSchedulings->count())
                <table class="table-fixed w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Tractorista</span>
                                <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Tractor</span>
                                <img class="sm:hidden flex mx-auto" src="/img/tractor.svg" alt="tractor"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Implemento</span>
                                <img class="sm:hidden flex mx-auto" src="/img/implement.png" alt="implement"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Fecha</span>
                                <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Turno</span>
                                <img class="sm:hidden flex mx-auto" src="/img/shift.svg" alt="correlative"
                                    width="25">
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($tractorSchedulings as $tractorScheduling)
                            <tr style="cursor:pointer" wire:click="seleccionar({{$tractorScheduling->id}})" class="border-b {{ $tractorScheduling->id == $idSchedule ? 'bg-blue-200' : '' }} border-gray-200">
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $tractorScheduling->user->name }}</span>
                                    </div>
                                </td>
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $tractorScheduling->tractor->tractorModel->model }}
                                            {{ $tractorScheduling->tractor->tractor_number }}</span>
                                    </div>
                                </td>
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $tractorScheduling->implement->implementModel->implement_model }} {{$tractorScheduling->implement->implement_number}} </span>
                                    </div>
                                </td>
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $tractorScheduling->date }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-2 text-center">
                                    <div class="flex items-center justify-center">
                                        <img src="/img/{{ $tractorScheduling->shift == 'MAÑANA' ? 'sun' : 'moon' }}.svg"
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
            <x-jet-dialog-modal maxWidth="sm" wire:model="open_print_schedule">
                <x-slot name="title">
                        <label>Imprimir Programación</label>
                        <button style="position:fixed; margin-left:40px; font-weight: 900" class="hover:text-gray-500 text-2xl"  wire:click="$set('open_print_schedule',false)">X</button>
                </x-slot>
                <x-slot name="content">
                    <div>
                        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                            <x-jet-label>Día</x-jet-label>
                            <x-jet-input type="date" min="2022-05-18" style="height:40px;width: 50%" wire:model='schedule_date'/>

                            <x-jet-input-error for="schedule_date"/>
                        </div>
                    </div>
                </x-slot>
                <x-slot name="footer">
                    <x-jet-button wire:loading.attr="disabled" wire:click="print_schedule()">
                        Programación
                    </x-jet-button>
                    <x-jet-button wire:loading.attr="disabled" class="ml-2" wire:click="print_routines()">
                        Rutinarios
                    </x-jet-button>
                    <div wire:loading wire:target="print_schedule">
                        Descargando...
                    </div>
                    <div wire:loading wire:target="print_routines">
                        Descargando...
                    </div>
                </x-slot>
            </x-jet-dialog-modal>
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
