<?php

namespace App\Http\Livewire;

use App\Models\TractorScheduling as ModelsTractorScheduling;
use Livewire\Component;

class TractorScheduling extends Component
{
    public function render()
    {
        $tractorSchedulings = ModelsTractorScheduling::paginate(6);

        return view('livewire.tractor-scheduling',compact('tractorSchedulings'));
    }
}
