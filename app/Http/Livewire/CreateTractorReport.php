<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\User;
use Livewire\Component;

class CreateTractorReport extends Component
{
    public $open = "false";

    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();
        $users = User::all();

        return view('livewire.create-tractor-report',compact('tractors','labors','implements','users'));
    }
}
