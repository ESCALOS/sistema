@php
    $i=0;
@endphp
<div>
    <div class="grid grid-cols-2">
        <center class="pt-2">
            <label for="select_import">¿Qué desea importar?</label><br>
            <select id="select_import" class="select2 w-full mt-4" wire:model='select_import'>
                @foreach ($modelos as $modelo)
                    <option value="{{ $i++ }}">{{ ucfirst($modelo['nombre']) }}</option>
                @endforeach
            </select>
        </center>
        <div>
            <div class="px-2">
                <div class="pt-2">
                    <x-jet-label>Importar {{ $modelos[$select_import]['nombre'] }}</x-jet-label>
                </div>
                <div class="pt-2">
                    <div class="mb-2">
                        <input type="file" name="{{ $modelos[$select_import]['tabla'] }}" id="{{ $modelos[$select_import]['tabla'] }}" wire:model='file_import'>
                    </div>
                    <div class="mb-2">
                        <button type="button" {{  $file_import == "" ? 'disabled' : '' }} class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition" wire:click='importar{{ ucfirst($modelos[$select_import]['nombre']) }}'>Importar {{ ucfirst($modelos[$select_import]['nombre']) }}</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div>
        <table class="table-fixed w-full">
            <thead>
                <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                @foreach ($modelos[$select_import]['campos'] as $campo)
                    <th>{{ $campo['header'] }}</th>
                @endforeach
                </tr>
            </thead>
            <tbody class="text-gray-600 text-sm font-light">
                @foreach ($datos as &$dato)
                    @php
                        $dato = get_object_vars($dato);
                    @endphp
                    <tr class="border-b border-gray-200">
                        @foreach ($modelos[$select_import]['campos'] as $campo)
                            @if(isset($campo['show']))
                        <td>{{ $dato[$campo['show']] }}</td>
                            @elseif (preg_match('/_id$/',$campo['field']))
                        <td>{{ $dato[str_replace('_id','',$campo['field'])] }}</td>
                            @else
                        <td>{{ $dato[$campo['field']] }}</td>
                            @endif
                        @endforeach
                    </tr>
                @endforeach
            </tbody>
        </table>

        {{ $datos->links() }}
    </div>

    @isset($errores_item)
    <div>
        <ul>
        @foreach ($errores_item as $error)
            <li>{{explode('"',serialize($error->errors()))[1]}} en la fila {{serialize($error->row())[2]}}</li>
        @endforeach
        </ul>
    </div>
    @endisset

    @if (isset($errores_user) && count($errores_user))
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
                        @foreach ($errores_user as $error)
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
</div>
