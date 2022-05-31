<x-app-layout>
    <slot name="menu">
        @livewire('navigation')
    </slot>
    <div>
        <div class="max-w-7xl mx-auto py-10 sm:px-6 lg:px-8">
            @livewire('tractor-report')
        </div>
    </div>
</x-app-layout>
