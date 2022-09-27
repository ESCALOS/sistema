<div>
    <div>
        <x-jet-label>Importar usuarios</x-jet-label>
        <input type="file" name="user" id="user" wire:model='user'>
        <button wire:loading.attr="disabled" class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarUsuarios'>Importar Usuarios</button>
    </div>

    <div>
        <x-jet-label>Importar Items</x-jet-label>
        <input type="file" name="item" id="item" wire:model='item'>
        <button wire:loading.attr="disabled" class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarItems'>Importar Items</button>
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
