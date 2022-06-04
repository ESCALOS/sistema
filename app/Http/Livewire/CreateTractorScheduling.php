<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Tractor;
use App\Models\TractorScheduling;
use App\Models\User;
use Livewire\Component;

class CreateTractorScheduling extends Component
{
    public $open = false;
    public $location;
    public $user;
    public $labor;
    public $tractor;
    public $implement;
    public $date;
    public $shift;

    protected $rules = [
        'location' => 'required|exists:locations,id',
        'user' => 'required|exists:users,id',
        'labor' => 'required|exists:labors,id',
        'tractor' => 'required|exists:tractors,id',
        'implement' => 'required|exists:implements,id',
        'date' => 'required|date|date_format:Y-m-d',
        'shift' => 'required'
    ];

    public function store()
    {
        $this->validate();

        TractorScheduling::create([
            'location_id' => $this->location,
            'user_id' => $this->user,
            'tractor_id' => $this->tractor,
            'labor_id' => $this->labor,
            'implement_id' => $this->implement,
            'date' => $this->date,
            'shift' => $this->shift,
        ]);
        $this->reset(['user','labor','tractor','implement']);

        $this->emit('render');
        $this->emit('alert');
    }

    public function render()
    {
        $tractors = Tractor::all();
        $users = User::all();
        $labors = Labor::all();
        $implements = Implement::all();
        $locations = Location::all();

        return view('livewire.create-tractor-scheduling', compact('tractors', 'users', 'labors', 'implements', 'locations'));
    }
}
