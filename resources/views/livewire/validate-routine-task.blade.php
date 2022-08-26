<div>
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl text-center"> REGISTRAR RUTINARIOS </h1>
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-{{$tlocation > 0 ? '3' : ($tsede > 0 ? '2' : '1')}} gap-4">
        <div>
            <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                <x-jet-label>Sede:</x-jet-label>
                <select class="form-select" style="width: 100%" wire:model='tsede'>
                    <option value="0">Seleccione una zona</option>
                @foreach ($sedes as $request)
                    <option value="{{ $request->id }}">{{ $request->sede }}</option>
                @endforeach
                </select>
            </div>
        </div>
        @if($tsede != 0)
            <div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='tlocation'>
                        <option value="0">Seleccione una zona</option>
                    @foreach ($locations as $location)
                        <option value="{{ $location->id }}">{{ $location->location }}</option>
                    @endforeach
                    </select>
                </div>
            </div>
            @if($tlocation != 0)
                <div>
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Fecha:</x-jet-label>
                        <select class="form-select" style="width: 100%" wire:model='tdate'>
                            <option value="">Seleccione una fecha</option>
                        @foreach ($dates as $date)
                            <option value="{{ $date->date }}">{{ $date->date }}</option>
                        @endforeach
                        </select>
                    </div>
                </div>
            @endif
        @endif
    </div>
    @if (count($implements))
    <div class="grid grid-cols-1 sm:grid-cols-3 mt-4 p-6 gap-4">
        @foreach ($implements as $implement)
    <!-- Cards de los usuarios con pedidos pendientes a validar  -->
        <div class="max-w-sm p-6 bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
            <div class="flex flex-col items-center text-center">
                <!--<img class="mb-3 w-24 h-24 rounded-full shadow-lg" src="{{ Auth::user()->profile_photo_url }}" alt="imagen"/>-->
                <h5 class="mb-1 text-lg font-medium text-gray-900 dark:text-white">{{ $implement->implement_model }} {{ $implement->implement_number }}</h5>
                <span class="text-sm text-gray-500 dark:text-gray-400">Implemento</span>
                <div class="flex mt-4 space-x-3 lg:mt-6">
                    <button wire:click="mostrarRutinario({{$implement->id}},'{{$implement->implement_model}}','{{$implement->implement_number}}')" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                        Registrar Rutinario
                    </button>
                </div>
            </div>
        </div>
        @endforeach
    </div>
    @endif
    <x-jet-dialog-modal wire:model="open_routine_task">
        <x-slot name="title">
            Registrar Rutinario
        </x-slot>
        <x-slot name="content">
            <div style="max-height:180px;overflow:auto">
                <table class="table-fixed w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th>Item</th>
                            <th class="py-3 text-center">Componente</th>
                            <th class="py-3 text-center">Tarea</th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @if(count($tasks))
                            @foreach ($tasks as $task)
                                <tr wire:click='cambiarVerificacion({{$task->id}})' class="border-b {{ $task->is_checked ? 'bg-red-200' : 'bg-green-200' }} border-gray-200 unselected">
                                    <td> {{++$item}} </td>
                                    <td class="py-3 px-6 text-center"> {{$task->component}} </td>
                                    <td class="py-3 px-6 text-center"> {{$task->task}} </td>
                                </tr>
                            @endforeach
                        @endif
                    </tbody>
                </table>
            </div>
            <div class=" mt-4 p-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                <x-jet-label>Observaciones:</x-jet-label>
                <textarea class="form-control w-full text-sm" rows=4 wire:model.defer="observation"></textarea>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="registrarRutinario()">
                Registrar
            </x-jet-button>
            <div wire:loading wire:target="registrarRutinario">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_routine_task',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
</div>
