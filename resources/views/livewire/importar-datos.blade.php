<div>
    <div>
        <x-jet-label>Importar usuarios</x-jet-label>
        <input type="file" name="user" id="user" wire:model='user'>
        <button class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarUsuarios'>Importar Usuarios</button>
    </div>

    @isset($user)
    {{$user->temporaryUrl()}}
    @endisset
    <div>
        <x-jet-label>Importar Items</x-jet-label>
        <input type="file" name="item" id="item" wire:model='item'>
        <button class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarItems'>Importar Items</button>
    </div>
</div>
