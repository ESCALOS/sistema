<div>
    @if ($fecha_pedido_en_proceso != "")
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-2xl text-center">CONFIRMAR PEDIDO <br> {{$fecha_pedido_en_proceso}}</h1>
    </div>
    <div class="grid grid-cols-1 sm:grid-cols-{{$tsede > 0 ? '2' : '1'}} gap-4">
        <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
            <x-jet-label>Sede:</x-jet-label>
            <select class="form-select" style="width: 100%; height:2.5rem" wire:model='tsede'>
                    <option value="0">Seleccione una zona</option>
            @foreach ($sedes as $request)
                <option value="{{ $request->id }}">{{ $request->sede }}</option>
            @endforeach
            </select>
        </div>
        @if ($tsede != 0)
        <div style="display:flex; align-items:center;justify-content:center" class="px-6 py-4">
            <button wire:click="$emit('confirmarProcesarPedido','{{$sede}}')" class="w-full h-16 bg-orange-500 text-2xl font-bold hover:bg-orange-700 text-white rounded-full">
                Procesar Pedido
            </button>
        </div>
        @endif
    </div>
    <!---------------Modal de Items por operador-------------------------->
    <x-jet-dialog-modal wire:model="open_en_proceso">
        <x-slot name="title">
            <h1>{{$detalle_item}} - S/.{{$precio_item}} </h1>
        </x-slot>
        <x-slot name="content">
            @isset($items_por_operador)
            <div class="p-6">
                <div style="max-height:400px;overflow:auto">
                    @if ($items_por_operador->count())
                        <table class="min-w-max w-full table-fixed">
                            <thead>
                                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Operador</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                            width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Cantidad</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/tractor.svg" alt="tractor"
                                            width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Precio Total</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="date" width="28">
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="text-gray-600 text-sm font-light">
                                @foreach ($items_por_operador as $request)
                                    <tr style="cursor:pointer" wire:click="detalleImplemento({{$request->user_id}})" class="border-b border-gray-200">
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $request->name }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ floatVal($request->quantity) }} {{ $request->abbreviation }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">S./ {{ number_format($request->quantity*$request->unit_price,2,".") }}</span>
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
                </div>
            </div>
            @endisset
        </x-slot>
        <x-slot name="footer">
            <x-jet-secondary-button wire:click="$set('open_en_proceso',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    <!---------------Modal de Items por implemento-------------------------->
    <x-jet-dialog-modal wire:model="open_en_proceso_implemento">
        <x-slot name="title">
            <h1> {{$detalle_item}} - {{$nombre_operador}} </h1>
        </x-slot>
        <x-slot name="content">
            @isset($items_por_implemento)
            <div class="p-6">
                <div>
                    @if ($items_por_implemento->count())
                        <table class="min-w-max w-full table-fixed">
                            <thead>
                                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Operador</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                            width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Cantidad</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/tractor.svg" alt="tractor"
                                            width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Precio Unitario</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/implement.png" alt="implement" width="25">
                                    </th>
                                    <th class="py-3 text-center">
                                        <span class="hidden sm:block">Precio Total</span>
                                        <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="date" width="28">
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="text-gray-600 text-sm font-light">
                                @foreach ($items_por_implemento as $request)
                                    <tr style="cursor:pointer" class="border-b border-gray-200">
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ $request->implement }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">{{ floatVal($request->quantity) }} {{ $request->abbreviation }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">S./ {{ number_format($request->unit_price,2,".") }}</span>
                                            </div>
                                        </td>
                                        <td class="py-3 text-center">
                                            <div>
                                                <span class="font-medium">S./ {{ number_format($request->quantity*$request->unit_price,2,".") }}</span>
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
                </div>
            </div>
            @endisset
        </x-slot>
        <x-slot name="footer">
            <x-jet-secondary-button wire:click="$set('open_en_proceso_implemento',false)" class="ml-2">
                Cerrar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
<!---------------Tabla Princial-------------------------------->
    @isset($solicitudes_en_proceso)
    <div class="text-center">
        <div class="px-6 pt-2">
            <x-jet-input type="text" class="w-full" placeholder="Ingrese el código o nombre del item" wire:model='search'></x-jet-input>
        </div>
        @foreach ($incluidos as $incluido)
            {{$incluido}}
        @endforeach
        <div class="p-6">
            <div>
                @if ($solicitudes_en_proceso->count())
                    <table class="min-w-max w-full table-fixed overflow-x-scroll">
                        <thead>
                            <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                                <th class="py-3 text-center">
                                    <span class="hidden sm:block">Codigo</span>
                                    <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                        width="25">
                                </th>
                                <th class="py-3 text-center">
                                    <span class="hidden sm:block">Item</span>
                                    <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                        width="25">
                                </th>
                                <th class="py-3 text-center">
                                    <span class="hidden sm:block">Cantidad</span>
                                    <img class="sm:hidden flex mx-auto" src="/img/tractor.svg" alt="tractor"
                                        width="25">
                                </th>
                                <th class="py-3 text-center">
                                    <span class="hidden sm:block">Precio Unitario</span>
                                    <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="date" width="28">
                                </th>
                                <th class="py-3 text-center">
                                    <span class="hidden sm:block">Precio Total</span>
                                    <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="date" width="28">
                                </th>
                            </tr>
                        </thead>
                        <tbody class="text-gray-600 text-sm font-light">
                            @foreach ($solicitudes_en_proceso as $request)
                                <tr style="cursor:pointer" wire:click="detalleOperador({{$request->item_id}})" class="border-b border-gray-200">
                                    <td class="py-3 text-center">
                                        <div>
                                            <span class="font-medium">{{ $request->sku }}</span>
                                        </div>
                                    </td>
                                    <td class="py-3 text-center">
                                        <div>
                                            <span class="font-bold {{$request->type == "PIEZA" ? 'text-red-500' : ( $request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "COMPONENTE" ? 'text-green-500' : ($request->type == "FUNGIBLE" ? 'text-amber-500' : 'text-blue-500')))}} ">{{ strtoupper($request->item) }}</span>
                                        </div>
                                    </td>
                                    <td class="py-3 text-center">
                                        <div>
                                            <span class="font-medium">{{ floatVal($request->quantity) }} {{ $request->abbreviation }}</span>
                                        </div>
                                    </td>
                                    <td class="py-3 text-center">
                                        <div>
                                            <span class="font-medium">S./ {{ number_format($request->unit_price,2,".") }}</span>
                                        </div>
                                    </td>
                                    <td class="py-3 text-center">
                                        <div>
                                            <span class="font-medium">S./ {{ number_format($request->unit_price*$request->quantity,2,".") }}</span>
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                    <div class="px-4 py-4">
                        {{ $solicitudes_en_proceso->links() }}
                    </div>
                @else
                    <div class="px-6 py-4">
                        No existe ningún registro coincidente
                    </div>
                @endif
            </div>
        </div>
    </div>
    @endisset
<!--------No hay pedids para validar----------------->
    @else
    <div style="display:flex; align-items:center;justify-content:center;margin-bottom:15px">
        <h1 class="font-bold text-4xl">NO HAY PEDIDOS PARA VALIDAR</h1>
    </div>
    @endif
</div>
