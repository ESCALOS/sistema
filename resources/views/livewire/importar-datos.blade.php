<div>
    <div>
        <x-jet-lable>Importar items</x-jet-lable>
        <input type="file" name="file" id="file" wire:model='user'>
        <button class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarUsuarios'>Importar Usuarios</button>
    </div>
    <div>
        <x-jet-lable>Importar Items</x-jet-lable>
        <input type="file" name="file" id="file" wire:model='item'>
        <button class="p-6 text-center border-none rounded-md shadow-md bg-red-500 hover:bg-red-700 text-white font-black text-xl" wire:click='importarItems'>Importar Items</button>
    </div>
</div>
