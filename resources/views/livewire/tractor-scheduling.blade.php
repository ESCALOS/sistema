<!-- component -->
<div class="overflow-x-auto">
    <div class="min-w-screen min-h-3/4 bg-gray-100 flex items-center justify-center bg-gray-100 font-sans overflow-hidden">
        <div class="w-full lg:w-5/6">
            <div class="bg-white shadow-md rounded my-6">
                <table class="min-w-max w-full table-fixed overflow-x-auto">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Tractor</span>
                                <img class="sm:hidden flex mx-auto" src="tractor.svg" alt="tractor" width="25">
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
                                <img class="sm:hidden flex mx-auto" src="img/actions.svg" alt="actions" width="25">
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($tractorSchedulings as $tractorScheduling)
                        <tr class="border-b border-gray-200 hover:bg-gray-100">
                            <td class="py-3 px-6 text-left whitespace-nowrap">
                                <div class="flex items-center">
                                    <span class="font-medium">{{ $tractorScheduling->tractor->tractorModel->model }} {{ $tractorScheduling->tractor->tractor_number }}</span>
                                </div>
                            </td>
                            <td class="py-3 px-2 text-left whitespace-nowrap">
                                <div class="flex items-center">
                                    <span class="font-medium">{{ $tractorScheduling->labor->labor }}</span>
                                </div>
                            </td>
                            <td class="py-3 px-2 text-left whitespace-nowrap">
                                <div class="flex items-center">
                                    <span class="font-medium">{{ $tractorScheduling->date}}</span>
                                </div>
                            </td>
                            <td class="py-3 px-2 text-center">
                                <div class="flex items-center justify-center">
                                    <img src="http://sistema/img/{{ $tractorScheduling->shift=='MAÑANA' ? 'sun' : 'moon'}}.svg" alt="shift" width="25">
                                </div>
                            </td>
                            <td class="py-3 px-2 text-center">
                                <div class="flex item-center justify-center">
                                    <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    </div>
                                    <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                                        </svg>
                                    </div>
                                    <div class="w-4 mr-2 transform hover:text-purple-500 hover:scale-110">
                                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                        </svg>
                                    </div>
                                </div>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                <div class="px-4 py-4">
                    {{ $tractorSchedulings->links() }}
                </div>
            </div>
        </div>
    </div>
</div>
