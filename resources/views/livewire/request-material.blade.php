<div>
    <div class="text-center">
        <h1 class="text-2xl font-bold pb-4">Solicitud de Pedido : {{$implemento}}</h1>
    </div>
    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
        <select class="form-select" style="width: 100%" wire:model='idRequest'>
            <option value="0">Seleccione una implemento</option>
        @foreach ($requests as $request)
            <option value="{{ $request->id }}">{{ $request->implement->implementModel->implement_model }} {{ $request->implement->implement_number }}</option>
        @endforeach
        </select>
    </div>
    <div class="px-6 py-4">
        @if ($components->count())
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div style="height:180px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Componentes</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($components as $component)
                            <tr style="cursor:pointer" class="border-b border-gray-200">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->item->item }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->id }}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div style="height:180px;overflow:auto">
                <div class="text-center">
                    <h1 class="text-md font-bold pb-4">Añadir Componente:</h1>
                </div>
                @if ($select_comps->count())
                <div class="px-6 py-2">
                    <x-jet-label>Componente:</x-jet-label>
                    <select id="comp_add" class="form-select" style="width: 100%" wire:model.defer='comp_add'>
                        <option value="">Seleccione una opción</option>
                        @foreach ($select_comps as $select_comp)
                            <option value="{{ $select_comp->item->id }}">{{ $select_comp->item->item }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="mt-4 text-center">
                    <button type="button" class="bg-green-500 shadow-md rounded-md px-4 py-2 text-white hover:bg-green-700">Agregar</button>
                </div>
                @else
                <div class="text-center p-6">
                    <h1 class="text-2xl font-bold pb-4">Todos los componentes añadidos</h1>
                </div>
                @endif
            </div>
            <div style="height:180px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Componentes</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($components as $component)
                            <tr style="cursor:pointer" class="border-b border-gray-200">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->item->item }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->id }}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div style="height:180px;overflow:auto">
                <table class="min-w-max w-full">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span>Componentes</span>
                            </th>
                            <th class="py-3 text-center">
                                <span>Cantidad</span>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($components as $component)
                            <tr style="cursor:pointer" class="border-b border-gray-200">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->item->item }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->id }}</span>
                                    </div>
                                </td>
                            </tr><tr style="cursor:pointer" class="border-b border-gray-200">
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->item->item }}</span>
                                    </div>
                                </td>
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{ $component->id }}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>
        @else
        <div class="px-6 py-4 text-center">
            <h1 class="text-2xl font-bold pb-4">NINGÚN IMPLEMENTO SELECCIONADO</h1>
        </div>
        @endif
    </div>
</div>
