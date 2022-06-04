<?php

namespace App\Http\Livewire;

use Livewire\Component;

class CreateTractorScheduling extends Component
{
    public $open = false;
    public $user;
    public $labor;
    public $tractor;
    public $implement;
    public $date;
    public $shift;



    public function render()
    {
        return view('livewire.create-tractor-scheduling');
    }
}
