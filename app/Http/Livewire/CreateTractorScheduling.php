<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorScheduling;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class CreateTractorScheduling extends Component
{
    public $open = false;
    public $location;
    public $lote;
    public $user;
    public $labor;
    public $tractor;
    public $implement;
    public $date;
    public $shift = "MAÑANA";

    protected function rules(){
        return [
            'location' => 'required|exists:locations,id',
            'lote' => 'required|exists:lotes,id',
            'user' => 'required|exists:users,id',
            'labor' => 'required|exists:labors,id',
            'tractor' => 'required|exists:tractors,id',
            'implement' => 'required|exists:implements,id',
            'date' => 'required|date|date_format:Y-m-d',
            'shift' => 'required|in:MAÑANA,NOCHE'
        ];
    }

    protected function messages(){
        return [
            'location.required' => 'Seleccione una ubicación',
            'lote.required' => 'Seleccione el lote',
            'user.required' => 'Seleccione al operador',
            'labor.required' => 'Seleccione la labor',
            'tractor.required' => 'Seleccione el tractor',
            'implement.required' => 'Seleccione el implemento',
            'date.required' => 'Seleccione la fecha',
            'shift.required' => 'Seleccione el turno',

            'location.exists' => 'La ubicación no existe',
            'lote.exists' => 'El lote no existe',
            'user.exists' => 'El operador no existe',
            'labor.exists' => 'La labor no existe',
            'tractor.exists' => 'El tractor no existe',
            'implement.exists' => 'El implmento no existe',
            'date.date' => 'Debe ingresar un fecha',
            'date.date_format' => 'Formato incorrecto',
            'shift.in' => 'El turno no existe',
        ];
    }

    public function store()
    {
        $this->validate();

        TractorScheduling::create([
            'lote_id' => $this->lote,
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

    public function updatedLocation(){
        $this->lote = 0;
        $this->tractor = 0;
        $this->implement = 0;
        $this->user = 0;
    }

    public function render()
    {
        $this->date = date('Y-m-d',strtotime(date('Y-m-d')."+1 days"));
        $locations = Location::where('sede_id',Auth::user()->location->sede->id)->get();
        $tractors = Tractor::where('location_id',$this->location)->get();
        $users = User::where('location_id',$this->location)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->get();
        $lotes = Lote::where('location_id',$this->location)->get();

        return view('livewire.create-tractor-scheduling', compact('tractors', 'users', 'labors', 'implements', 'locations','lotes'));
    }
}
