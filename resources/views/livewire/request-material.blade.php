<div>
    <div class="text-center">
        <h1 class="text-2xl font-bold pb-4">Solicitud de Pedido</h1>
    </div>
    <div class="px-6 py-4 grid grid-cols-1 sm:grid-cols-3" wire:ignore>
        @foreach ($implements as $implement)
        <div class="p-6 mb-4 ml-2 max-w-sm bg-white rounded-lg border border-gray-200 shadow-md dark:bg-gray-800 dark:border-gray-700">
                <h5 class="mb-2 text-2xl font-bold tracking-tight text-gray-900 dark:text-white">{{ $implement->implement->implementModel->implement_model }} {{ $implement->implement->implement_number }} </h5>
            <p class="mb-3 font-normal text-gray-700 dark:text-gray-400"></p>
            <button type="button" wire:click="abrir_modal({{$implement->id}})" class="inline-flex items-center py-2 px-3 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800">
                Ver detalle
                <svg class="ml-2 -mr-1 w-4 h-4" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>
            </button>
        </div>
        @endforeach
    </div>
    <div>
        <x-jet-dialog-modal wire:model="open">
            <x-slot name="title">
                Lista de Componentes
            </x-slot>
            <x-slot name="content">
                <table class="min-w-max w-full table-fixed overflow-x-scroll">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Componente</span>
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($inputs as $componente)
                        <tr class="border-b border-gray-200">
                            <td class="py-3 px-6 text-left">
                                <div class="flex items-center">
                                    <span class="font-medium">{{ $inputs[$loop->index]['componente']}}</span>
                                </div>
                            </td>
                            <td class="py-3 px-6 text-left">
                                <button class="px-4 py-2 bg-blue-500 rounded-md" wire:click="increase({{$loop->index}})">+</button>
                                <x-jet-input class="text-center" type="text" style="height:30px;width: 66%" wire:model="inputs.{{ $loop->index }}.quantity"/>
                                <button class="px-4 py-2 bg-red-500 rounded-md" wire:click="reduce({{$loop->index}})">-</button>
                            </td>
                        @endforeach
                    </tbody>
                </table>
            </x-slot>
            <x-slot name="footer">
                <x-jet-button wire:loading.attr="disabled" wire:click="addItems()">
                    Guardar
                </x-jet-button>
                <x-jet-danger-button class="ml-2" wire:loading.attr="disabled" wire:click="cerrar()">
                    Cerrar
                </x-jet-danger-button>
                <div wire:loading wire:target="addItems">
                    Registrando...
                </div>
                <x-jet-secondary-button wire:click="cerrar" class="ml-2">
                    Cancelar
                </x-jet-secondary-button>
            </x-slot>
        </x-jet-dialog-modal>
    </div>
</div>
