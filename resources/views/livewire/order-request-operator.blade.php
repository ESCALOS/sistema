<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div x-data="{ open:false }">
                <div class="text-center mb-4" x-on:click="open = !open">
                    <x-jet-button>Filtros</x-jet-button>
                </div>
                <div x-show="open" class="bg-white shadow-md rounded my-6">
                    <div class="px-6 py-4 grid grid-cols-2 sm:grid-cols-3" wire:ignore>
                        <div class="px-6 py-2">
                            <label for="simplement">Implemento:</label><br>
                            <select id="simplement" class="select2" wire:model='simplement'>
                                <option value="">Seleccione el tractor</option>
                                @foreach ($implements as $implement)
                                    <option value="{{ $implement->id }}">{{ $implement->implementModel->implement_model }} {{ $implement->implement_number }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="px-6 py-2">
                            <label for="sstate">Estado:</label><br>
                            <select id="sstate" class="select2" wire:model='sstate'>
                                <option value="">Seleccione una opción</option>
                                <option>PENDIENTE</option>
                                <option>CERRADO</option>
                                <option>VALIDADO</option>
                                <option>RECHAZADO</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>
            <div class="bg-white p-6 grid items-center" style="grid-template-columns: repeat(3, minmax(0, 1fr))">
                @livewire('create-tractor-report')
                @livewire('edit-tractor-report')
                <div class="p-4">
                    <button type="button" wire:click='anular()' class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Anular
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
