<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div class="p-6">
                    @if ($tractorReports->count())
                        <table class="min-w-max w-full table-fixed overflow-x-scroll">
                            <thead>
                                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Correlativo</span>
                                        <img class="sm:hidden flex mx-auto" src="img/correlative.svg" alt="correlative"
                                            width="25">
                                    </th>
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
                                </tr>
                            </thead>
                            <tbody  x-data="{open:false}" class="text-gray-600 text-sm font-light">
                                @foreach ($pedidos as $pedido)
                                    <tr style="cursor:pointer" wire:click="seleccionar({{$pedido->id}})" class="border-b {{ $pedido->id == $idPedido ? 'bg-blue-200' : '' }} border-gray-200">
                                        <td class="py-3 px-6 text-left">
                                            <div class="flex items-center">
                                                <span class="font-medium">{{ $tractorReport->correlative }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 px-6 text-left">
                                            <div class="flex items-center">
                                                <span class="font-medium">{{ $tractorReport->tractor->tractorModel->model }}
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
