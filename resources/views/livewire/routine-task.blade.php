<div>
    <div class="p-6">
        @if ($routine_tasks->count())
        <table class="min-w-max w-full overflow-x-scroll">
            <thead>
                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                    <th class="py-3 text-center">
                        <span class="hidden sm:block">Operador</span>
                        <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                            width="25">
                    </th>
                    <th class="py-3 text-center">
                        <span class="hidden sm:block">Implemento</span>
                        <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="tractor"
                            width="25">
                    </th>
                    <th class="py-3 text-center">
                        <span class="hidden sm:block">Fecha</span>
                        <img class="sm:hidden flex mx-auto" src="/img/implement.png" alt="implement"
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
</div>
