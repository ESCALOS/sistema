<div>
    <div class="min-w-screen min-h-3/4 flex items-center justify-center bg-gray-100 font-sans overflow-y-hidden">
        <div class="w-full lg:w-5/6">
            <div class="bg-white p-6 grid items-center" style="grid-template-columns: repeat(3, minmax(0, 1fr))">
                <div class="p-4">
                    <button type="button" wire:click="$set('open_create','true')" class="w-full inline-flex items-center justify-center px-4 py-2 bg-green-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-green-500 focus:outline-none focus:border-green-700 focus:ring focus:ring-green-200 active:bg-green-600 disabled:opacity-25 transition">
                        Registrar
                    </button>
                </div>
                
                <div class="p-4">
                    <button type="button" wire:click="editar" class="w-full inline-flex items-center justify-center px-4 py-2 bg-amber-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-amber-500 focus:outline-none focus:border-amber-700 focus:ring focus:ring-amber-200 active:bg-amber-600 disabled:opacity-25 transition">
                        Editar
                    </button>
                </div>
                <div class="p-4">
                    <button type="button" wire:click='anular' class="w-full inline-flex items-center justify-center px-4 py-2 bg-red-600 border border-transparent rounded-md font-semibold text-xs text-white uppercase tracking-widest hover:bg-red-500 focus:outline-none focus:border-red-700 focus:ring focus:ring-red-200 active:bg-red-600 disabled:opacity-25 transition">
                        Anular
                    </button>
                </div>
            </div>
            <div class="p-6">
                @if ($users->count())
                <table class="min-w-max w-full overflow-x-scroll">
                    <thead>
                        <tr class="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Código</span>
                                <img class="sm:hidden flex mx-auto" src="/img/driver.png" alt="driver"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Nombre</span>
                                <img class="sm:hidden flex mx-auto" src="/img/tractor.svg" alt="tractor"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Apellido</span>
                                <img class="sm:hidden flex mx-auto" src="/img/implement.png" alt="implement"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Roles</span>
                                <img class="sm:hidden flex mx-auto" src="/img/date.svg" alt="correlative"
                                    width="25">
                            </th>
                            <th class="py-3 text-center">
                                <span class="hidden sm:block">Ubicación</span>
                                <img class="sm:hidden flex mx-auto" src="/img/shift.svg" alt="correlative"
                                    width="25">
                            </th>
                        </tr>
                    </thead>
                    <tbody class="text-gray-600 text-sm font-light">
                        @foreach ($users as $user)
                            <tr style="cursor:pointer" wire:click="seleccionar({{$user->id}})" class="border-b {{ $user->id == $id_usuario ? 'bg-blue-200' : '' }} border-gray-200">
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $user->code }}</span>
                                    </div>
                                </td>
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $user->name }}</span>
                                    </div>
                                </td>
                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $user->lastname }}</span>
                                    </div>
                                </td>

                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $user->location->location }}</span>
                                    </div>
                                </td>

                                <td class="py-3 text-center">
                                    <div>
                                        <span class="font-medium">{{ $user->location->location }}</span>
                                    </div>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
                @else
                    <div class="text-center">
                        <h1 class="text-gray-500">No hay registros</h1>
                    </div>
                @endif
                    <div class="px-4 py-4">
                        {{ $users->links() }}
                    </div>
            </div>
        </div>
    </div>
    <x-jet-dialog-modal wire:model='open_create'>
        <x-slot name="title">
            Crear Usuario
        </x-slot>
        <x-slot name="content">
            <div class="grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Code:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="create_code" />

                    <x-jet-input-error for="create_code"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='location'>
                        <option value="0">Seleccione una opción</option>
                        @foreach ($locations as $location)
                            <option value="{{ $location->id }}">{{ $location->location }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="location"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Nombre:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="create_name" />

                    <x-jet-input-error for="create_name"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Apellido:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="create_lastname" />

                    <x-jet-input-error for="create_lastname"/>

                </div>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="store()">
                Guardar
            </x-jet-button>
            <div wire:loading wire:target="store">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_create',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    <x-jet-dialog-modal wire:model="open_edit">
        <x-slot name="title">
            Editar usuario
        </x-slot>
        <x-slot name="content">
            <div class="grid" style="grid-template-columns: repeat(2, minmax(0, 1fr));">
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Code:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="edit_code" />

                    <x-jet-input-error for="edit_code"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Nombre:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="edit_name" />

                    <x-jet-input-error for="edit_name"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem;grid-column: 2 span/ 2 span">
                    <x-jet-label>Apellido:</x-jet-label>
                    <x-jet-input type="text" style="height:30px;width: 100%" wire:model="edit_lastname" />

                    <x-jet-input-error for="edit_lastname"/>

                </div>
                <div class="py-2" style="padding-left: 1rem; padding-right:1rem">
                    <x-jet-label>Ubicación:</x-jet-label>
                    <select class="form-select" style="width: 100%" wire:model='location'>
                        <option value="0">Seleccione una opción</option>
                        @foreach ($locations as $location)
                            <option value="{{ $location->id }}">{{ $location->location }}</option>
                        @endforeach
                    </select>

                    <x-jet-input-error for="location"/>

                </div>
            </div>
        </x-slot>
        <x-slot name="footer">
            <x-jet-button wire:loading.attr="disabled" wire:click="actualizar()">
                Guardar
            </x-jet-button>
            <div wire:loading wire:target="actualizar">
                Registrando...
            </div>
            <x-jet-secondary-button wire:click="$set('open_edit',false)" class="ml-2">
                Cancelar
            </x-jet-secondary-button>
        </x-slot>
    </x-jet-dialog-modal>
    <script>
        document.addEventListener('livewire:load', function() {
            $('.select2').select2();
            $('#stractor').on('change', function() {
                @this.set('stractor', this.value);
            });
            $('#slabor').on('change', function() {
                @this.set('slabor', this.value);
            });
            $('#simplement').on('change', function() {
                @this.set('simplement', this.value);
            });
        })

    </script>
</div>
