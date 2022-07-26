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
            <li>{{explode('"',serialize($error->errors()))[1]}} Nombre del item: {{explode('"',serialize($error->values()))[5]}}, en la fila {{serialize($error->row())[2]}}</li>
        @endforeach
        </ul>
    </div>
    @endisset
</div>
