<div>
    <div class="text-center">
        <h1 class="text-2xl font-bold pb-4">Solicitud de Pedido : {{strtoupper($implemento)}}</h1>
    </div>
    <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
        <select class="form-select" style="width: 100%" wire:model='idImplemento'>
            <option value="0">Seleccione una implemento</option>
        @foreach ($implements as $implement)
            <option value="{{ $implement->id }}">{{ $implement->implement_model }} {{ $implement->implement_number }}</option>
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
                                        <span class="font-medium {{$component->is_part == 0 ? 'text-green-500' : 'text-red-500'}}">{{ strtoupper($component->component) }}</span>
                                    </div>
                                </td>
                                @foreach($component as $part)
                                <td class="py-3 px-6 text-center">
                                    <div>
                                        <span class="font-medium">{{$part}}</span>
                                    </div>
                                </td>
                                @endforeach
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div style="height:180px;overflow:auto">
                <div class="text-center">
                    <h1 class="text-md font-bold pb-4">Añadir Componente:</h1>
                </div>
                
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
