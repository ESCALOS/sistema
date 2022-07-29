<div>

    <div class="px-6 py-4 text-center">

        <div class="p-4 grid grid-cols-1 sm:grid-cols-2 gap-4 text-center">
        <!--------Boton para filtros------------>
            <div x-data="{ open:false }">
                <button x-on:click="open = !open" id="dropdownSearchButton"  data-dropdown-toggle="dropdownSearch" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-blue-700 rounded-lg hover:bg-blue-800" type="button">
                    Dropdown search
                    <svg class="ml-2 w-4 h-4" aria-hidden="true" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                    </svg>
                </button>

                <div id="dropdownSearch" class="absolute z-10 w-60 bg-white rounded shadow dark:bg-gray-700" x-show="open">
                    <div style="padding: 0.75rem">
                        <div class="relative">
                            <div class="flex absolute inset-y-0 left-0 items-center pl-3 pointer-events-none">
                                <svg class="w-5 h-5 text-gray-500 dark:text-gray-400" aria-hidden="true" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd"></path></svg>
                            </div>
                            <input type="text" id="input-group-search" class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full pl-10 p-2.5  dark:bg-gray-600 dark:border-gray-500 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" placeholder="Search user">
                        </div>
                    </div>
                    <ul style="max-height: 12rem" class="overflow-y-auto px-3 pb-3 text-sm text-gray-700 dark:text-gray-200" aria-labelledby="dropdownSearchButton">
                        @foreach ($sedes as $sede)
                        <li>
                            <div class="flex items-center p-2 rounded hover:bg-gray-100 dark:hover:bg-gray-600">
                            <input id="checkbox-item-11" type="checkbox" wire:click='addSedeFilter({{$sede->id}})' class="w-4 h-4 text-blue-600 bg-gray-100 rounded border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-700 focus:ring-2 dark:bg-gray-600 dark:border-gray-500">
                            <label for="checkbox-item-11" class="ml-2 w-full text-sm font-medium text-gray-900 rounded dark:text-gray-300">{{$sede->sede}}</label>
                            </div>
                        </li>
                        @endforeach
                    </ul>
                </div>
            </div>
        <!--------Boton para importar----------->
            <div>
                <button wire:click="$set('open_import_stock',true)" class="inline-flex items-center py-2 px-4 text-sm font-medium text-center text-white bg-green-600 rounded-lg hover:bg-green-700">
                    <svg xmlns="http://www.w3.org/2000/svg"  viewBox="0 0 48 48" width="24px" height="24px">
                        <path fill="#169154" d="M29,6H15.744C14.781,6,14,6.781,14,7.744v7.259h15V6z"/><path fill="#18482a" d="M14,33.054v7.202C14,41.219,14.781,42,15.743,42H29v-8.946H14z"/><path fill="#0c8045" d="M14 15.003H29V24.005000000000003H14z"/><path fill="#17472a" d="M14 24.005H29V33.055H14z"/><g><path fill="#29c27f" d="M42.256,6H29v9.003h15V7.744C44,6.781,43.219,6,42.256,6z"/><path fill="#27663f" d="M29,33.054V42h13.257C43.219,42,44,41.219,44,40.257v-7.202H29z"/><path fill="#19ac65" d="M29 15.003H44V24.005000000000003H29z"/><path fill="#129652" d="M29 24.005H44V33.055H29z"/></g><path fill="#0c7238" d="M22.319,34H5.681C4.753,34,4,33.247,4,32.319V15.681C4,14.753,4.753,14,5.681,14h16.638 C23.247,14,24,14.753,24,15.681v16.638C24,33.247,23.247,34,22.319,34z"/><path fill="#fff" d="M9.807 19L12.193 19 14.129 22.754 16.175 19 18.404 19 15.333 24 18.474 29 16.123 29 14.013 25.07 11.912 29 9.526 29 12.719 23.982z"/>
                    </svg>
                    <span class="ml-2">Importar stock</span>
                </button>
            </div>
        </div>
        <div>
            <div>
                <table class="min-w-max w-full table-fixed overflow-x-scroll">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Sede</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Item</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Precio</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Pedido</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($general_stock_details as $request)
                            <tr wire:click="editar({{$request->id}})" class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$request->sede}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-bold {{$request->type == "PIEZA" ? 'text-red-500' : ( $request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">{{ strtoupper($request->item) }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-bold">{{floatVal($request->quantity)}} {{$request->abbreviation}}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-bold">S/. {{number_format($request->price,2,".")}} </span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-bold">
                                            @if($request->order_date == "")
                                                Stock Inicial
                                            @else
                                                {{$request->order_date}}
                                            @endif
                                        </span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
                <div class="px-4 py-4">
                    {{ $general_stock_details->links() }}
                </div>
            </div>
        </div>
        <x-jet-dialog-modal wire:model="open_import_stock">
            <x-slot name="title">
                Importar stock
            </x-slot>
            <x-slot name="content">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">

                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Pedidos: </x-jet-label>
                        <select class="form-select" style="width: 100%" wire:model='fecha_pedido'>
                            <option value="">Seleccione una opción</option>
                            @foreach ($order_dates as $order_date)
                                <option value="{{ $order_date->id }}">{{ $order_date->order_date }} </option>
                            @endforeach
                        </select>

                        <x-jet-input-error for="fecha_pedido"/>

                    </div>

                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                        <x-jet-label>Excel:</x-jet-label>
                        <input type="file"  id="upload{{$iteration}}" style="height:30px;width: 100%" wire:model="stock" accept="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>

                        <x-jet-input-error for="stock"/>

                    </div>

                @if ($fecha_pedido > 0)
                    <div class="py-2" style="padding-left: 1rem; padding-right:1rem; grid-column: 2 span/ 2 span">
                        <button wire:click="descargarPlantilla" class="p-6 w-full bg-green-500 hover:bg-green-700 rounded-md text-white text-lg">Descargar Plantilla</button>
                    </div>
                @endif

                </div>
            </x-slot>
            <x-slot name="footer">
                <x-jet-button wire:loading.attr="disabled" wire:click="importarStock()">
                    Importar
                </x-jet-button>
                <div wire:loading wire:target="actualizar_nuevo">
                    Registrando...
                </div>
                <x-jet-secondary-button wire:loading.attr="disabled" wire:click="$set('open_import_stock',false)" class="ml-2">
                    Cancelar
                </x-jet-secondary-button>
            </x-slot>
        </x-jet-dialog-modal>

    <x-jet-dialog-modal wire:model="open_errores_importar">
        <x-slot name="title">
            Detalle de errores
        </x-slot>
        <x-slot name="content">
            @if (isset($errores_stock) && count($errores_stock))
            <div style="max-height:180px;overflow:auto;grid-column: 2 span/ 2 span;">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Error</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Fila</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($errores_stock as $error)
                                <tr class="border-b border-gray-200 unselected">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{explode('"',serialize($error->errors()))[1]}} </span>
                                    </div>
                                </td>
                                @php
                                    $patrones = array();
                                    $patrones[0] = '/i:/';
                                    $patrones[1] = '/;/';
                                    $sus = array();
                                    $sus[0] = '';
                                    $sus[1] = ''
                                @endphp
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{preg_replace($patrones,$sus,serialize($error->row()))}} </span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            @endif
        </x-slot>
        <x-slot name="footer">
            <x-jet-secondary-button wire:loading.attr="disabled" wire:click="$set('open_errores_importar',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    </div>
</div>
