<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div x-data="{ open:false }" x-on:click="open = !open" >
                <div class="text-center mb-4">
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
                <div class="p-4">
                    <button type="button" class="inline-flex items-center justify-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-500 focus:outline-none focus:border-green-700 focus:ring focus:ring-green-200 active:bg-green-600 disabled:opacity-25 transition">
                        Registrar
                    </button>
                </div>
                <div class="p-4">
                    <button type="button" class="inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Editar
                    </button>
                </div>
                <div class="p-4">
                    <button type="button" class="inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Anular
                    </button>
                </div>
            </div>
            <div class="p-6">
                    @if ($tractorReports->count())
                        <table class="min-w-max w-full table-fixed overflow-x-scroll">
                            <thead>
                                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Tractor</span>
                                        <img class="sm:hidden flex mx-auto" src="img/tractor.svg" alt="tractor"
                                            width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Labor</span>
                                        <img class="sm:hidden flex mx-auto" src="img/labor.svg" alt="labor" width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Día</span>
                                        <img class="sm:hidden flex mx-auto" src="img/date.svg" alt="date" width="28">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Turno</span>
                                        <img class="sm:hidden flex mx-auto" src="img/shift.svg" alt="shift" width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Turno</span>
                                        <img class="sm:hidden flex mx-auto" src="img/actions.svg" alt="actions"
                                            width="25">
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="text-gray-600 text-sm font-light">
                                @foreach ($tractorReports as $tractorReport)
                                    <tr class="border-b border-gray-200 hover:bg-gray-100">
                                        <td class="py-3 px-6 text-left">
                                            <div class="flex items-center">
                                                <span
                                                    class="font-medium">{{ $tractorReport->tractor->tractorModel->model }}
                                                    {{ $tractorReport->tractor->tractor_number }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-2 text-left">
                                            <div class="flex items-center">
                                                <span class="font-medium">{{ $tractorReport->labor->labor }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-2 text-left">
                                            <div class="flex items-center">
                                                <span class="font-medium">{{ $tractorReport->date }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-2 text-center">
                                            <div class="flex items-center justify-center">
                                                <img src="img/{{ $tractorReport->shift == 'MAÑANA' ? 'sun' : 'moon' }}.svg"
                                                    alt="shift" width="25">
                                            </div>
                                        </td>
                                        <td class="py-3 px-2 text-center">
                                            <div class="flex item-center justify-center">
                                                <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                        viewBox="0 0 24 24" stroke="currentColor">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                            stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                            stroke-width="2"
                                                            d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                    </svg>
                                                </div>
                                                <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                        viewBox="0 0 24 24" stroke="currentColor">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                            stroke-width="2"
                                                            d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                                                    </svg>
                                                </div>
                                                <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none"
                                                        viewBox="0 0 24 24" stroke="currentColor">
                                                        <path stroke-linecap="round" stroke-linejoin="round"
                                                            stroke-width="2"
                                                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                    </svg>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    @else
                        <div class="px-6 py-4">
                            No existe ningún registro coincidente
                        </div>
                    @endif
                        <div class="px-4 py-4">
                            {{ $tractorReports->links() }}
                        </div>
                    </div>
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
