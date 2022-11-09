<div>
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <div class="text-center">
            <h1 class="font-bold text-4xl">
                Registro de Rutinarios
            </h1>
        </div>
    </div>
    <div class="p-6">
        @if (count($routine_tasks))
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
                @foreach ($routine_tasks as $routine_task)
                    <tr style="cursor:pointer" class="border-b border-gray-200">
                        <td class="py-3 text-center">
                            <div>
                                <span class="font-medium">{{ $routine_task->user->name }}</span>
                            </div>
                        </td>
                        <td class="py-3 text-center">
                            <div>
                                <span class="font-medium">{{ $routine_task->implement->implementModel->implement_model }} {{$routine_task->implement->implement_number}} </span>
                            </div>
                        </td>
                        <td class="py-3 text-center">
                            <div>
                                <span class="font-medium">{{ $routine_task->date }}</span>
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
                {{ $routine_tasks->links() }}
            </div>
    </div>
</div>
