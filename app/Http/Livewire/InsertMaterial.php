<?php

namespace App\Http\Livewire;

use Livewire\Component;
USE Livewire\WithFileUploads;

class InsertMaterial extends Component
{
    use WithFileUploads;

    


    public function render()
    {
        return view('livewire.insert-material');
    }
}
