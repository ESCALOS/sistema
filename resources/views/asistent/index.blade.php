<x-app-layout>
    <slot name="menu">
        @livewire('navigation')
    </slot>
    <div>
        <div class="max-w-7xl mx-auto py-10 sm:px-6 lg:px-8">
            <x-jet-form-section submit="">
                <x-slot name="title">
                    Reporte de Tractores
                </x-slot>

                <x-slot name="description">
                    Reportede los tractores
                </x-slot>

                <x-slot name="form">
                    <!-- Tractor -->
                    <div class="col-span-6 sm:col-span-4">
                        <x-jet-label for="tractor" value="Tractor" />
                        <x-jet-input id="tractor" type="text" class="mt-1 block w-full"/>
                    </div>

                    <!-- Usuario -->
                    <div class="col-span-6 sm:col-span-4">
                        <x-jet-label for="user" value="Usuario" />
                        <x-jet-input id="user" type="number" class="mt-1 block w-full"/>
                    </div>
                </x-slot>

                <x-slot name="actions">
                    <x-jet-button>
                        Guardar
                    </x-jet-button>
                </x-slot>
            </x-jet-form-section>
        </div>
    </div>
</x-app-layout>
    