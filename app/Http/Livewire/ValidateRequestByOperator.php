<?php

namespace App\Http\Livewire;

use Livewire\Component;

class ValidateRequestByOperator extends Component
{
    public $open_validate_request = false;

    protected $listeners = ['render'];

    public function render()
    {
        return view('livewire.validate-request-by-operator');
    }
}
