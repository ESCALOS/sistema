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
                @livewire('edit-tractor-report')
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
