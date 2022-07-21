<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div x-data="{ open:false }">
                <div class="text-center mb-4" x-on:click="open = !open">
                    <x-jet-button>Filtros  </x-jet-button>
                </div>
                <div x-show="open" class="bg-white shadow-md rounded my-6">
                    <div class="px-6 py-4 grid grid-cols-1 sm:grid-cols-3" wire:ignore>
                        <div class="px-6 py-2">
                            <label for="stractor">Tractor:</label><br>
                            <select id="stractor" class="select2" wire:model='stractor'>
                                <option value="0">Seleccione el tractor</option>
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
                                <option value="0">Seleccione el implemento</option>
                                @foreach ($filtro_implementos as $implement)
                                    <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                                @endforeach
                            </select>
                        </div>
                    </div>
                </div>
            </div>
            <div class="bg-white p-6 grid items-center" style="grid-template-columns: repeat(3, minmax(0, 1fr))">
                @livewire('create-tractor-report')
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
                                    <x-jet-input readonly type="date" min="2022-05-18" style="height:30px;width: 100%" value="{{$date}}"/>

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
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                                    <x-jet-label>Correlativo:</x-jet-label>
                                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model.defer="correlative" />

                                    <x-jet-input-error for="correlative"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                                    <x-jet-label>Operador:</x-jet-label>
                                    <select id="user" class="form-select" style="width: 100%" wire:model.defer='user'>
                                        <option value="0">Seleccione una opción</option>
                                        @foreach ($users as $user)
                                            <option value="{{ $user->id }}">{{ $user->name }}</option>
                                        @endforeach
                                    </select>

                                    <x-jet-input-error for="user"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                                    <x-jet-label>Tractor:</x-jet-label>
                                    <select class="form-select" wire:model='tractor'>
                                        <option value="0">Seleccione una opción</option>
                                        @foreach ($tractors as $tractor)
                                            <option value="{{ $tractor->id }}">{{ $tractor->tractorModel->model }}
                                                {{ $tractor->tractor_number }}</option>
                                        @endforeach
                                    </select>

                                    <x-jet-input-error for="tractor"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                                    <x-jet-label>Horometro Inicial: </x-jet-label>
                                    <x-jet-input type="number" min="0" style="height:30px;width: 100%" disabled wire:model.defer="hour_meter_start"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;">
                                    <x-jet-label>Horometro Final:</x-jet-label>
                                    <x-jet-input type="number" min="0" style="height:30px;width: 100%" wire:model.defer="hour_meter_end" />

                                    <x-jet-input-error for="hour_meter_end"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                                    <x-jet-label>Implemento:</x-jet-label>
                                    <select class="form-select" style="width: 100%" wire:model.defer='implement'>
                                        <option value="0">Seleccione una opción</option>
                                    @foreach ($implements as $implement)
                                        <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                                    @endforeach
                                    </select>

                                    <x-jet-input-error for="implement"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                                    <x-jet-label>Labor:</x-jet-label>
                                    <select class="form-select" style="width: 100%" wire:model.defer='labor'>
                                        <option value="0">Seleccione una opción</option>
                                        @foreach ($labors as $labor)
                                            <option value="{{ $labor->id }}">{{ $labor->labor }}</option>
                                        @endforeach
                                    </select>

                                    <x-jet-input-error for="labor"/>

                                </div>
                                <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                                    <x-jet-label>Observaciones:</x-jet-label>
                                    <textarea class="form-control w-full text-sm" rows=2 wire:model.defer="observations"></textarea>
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
                    @if ($tractorReports->count())
                        <table class="min-w-max w-full table-fixed overflow-x-scroll">
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
                                        <img class="sm:hidden flex mx-auto" src="/img/implement.png" alt="implement" width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Día</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="date" width="28">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Turno</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/shift.svg" alt="shift" width="25">
                                    </th>
                                </tr>
                            </thead>
                            <tbody  x-data="{open:false}" class="text-gray-600 text-sm font-light">
                                @foreach ($tractorReports as $tractorReport)
                                    <tr style="cursor:pointer" wire:click="seleccionar({{$tractorReport->id}})" class="border-b {{ $tractorReport->id == $idReporte ? 'bg-blue-200' : '' }} border-gray-200">
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $tractorReport->user->name }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $tractorReport->tractor->tractorModel->model }}
                                                    {{ $tractorReport->tractor->tractor_number }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $tractorReport->implement->implementModel->implement_model }} {{$tractorReport->implement->implement_number}}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $tractorReport->date }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-2 text-center">
                                            <div class="flex items-center justify-center">
                                                <img src="img/{{ $tractorReport->shift == 'MAÑANA' ? 'sun' : 'moon' }}.svg"
                                                    alt="shift" width="25">
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
</div>
