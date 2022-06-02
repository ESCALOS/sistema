<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use Livewire\Component;

use App\Models\Tractor;

class CreateTractorReport extends Component
{
    public $open = true;

    public function render()
    {
        
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

        return view('livewire.create-tractor-report',compact('tractors','labors','implements'));
    }
}
