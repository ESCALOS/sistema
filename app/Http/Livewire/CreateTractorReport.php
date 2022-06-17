<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorReport;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class CreateTractorReport extends Component
{
    public $open = false;
    public $location;
    public $lote;
    public $correlative;
    public $date;
    public $shift = "MAÑANA";
    public $user;
    public $tractor;
    public $labor;
    public $implement;
    public $horometro_inicial = 0;
    public $hour_meter_end;
    public $observations = "";

    protected $rules = [
        'lote' => 'required|exists:lotes,id',
        'correlative' => 'required',
        'date' => 'required|date|date_format:Y-m-d',
        'shift' => 'required',
        'user' => 'required|exists:users,id',
        'tractor' => 'required|exists:tractors,id',
        'labor' => 'required|exists:labors,id',
        'implement' => 'required|exists:implements,id',
        'hour_meter_end' => "required|gt:horometro_inicial",
    ];

    public function store(){
        $this->validate();

        $tractor = Tractor::find($this->tractor);
        $hour_meter_start = $tractor->hour_meter;
        TractorReport::create([
            'user_id' => $this->user,
            'tractor_id' => $this->tractor,
            'labor_id' => $this->labor,
            'correlative' => $this->correlative,
            'date' => $this->date,
            'shift' => $this->shift,
            'implement_id' => $this->implement,
            'hour_meter_start' => floatval($hour_meter_start),
            'hour_meter_end' => floatval($this->hour_meter_end),
            'hours' => floatval($this->hour_meter_end - $hour_meter_start),
            'observations' => $this->observations,
            'lote_id' => $this->lote,
        ]);
        $this->reset(['correlative','user','tractor','labor','implement','horometro_inicial','hour_meter_end','observations']);

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
        if($this->date == ""){
            $this->date = date('Y-m-d',strtotime(date('Y-m-d')."-1 days"));
        }
        $locations = Location::where('sede_id',Auth::user()->location->sede->id)->get();
        $tractors = Tractor::where('location_id',$this->location)->get();
        $users = User::where('location_id',$this->location)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->get();
        $lotes = Lote::where('location_id',$this->location)->get();

        if($this->tractor > 0){
            $tractor = Tractor::find($this->tractor);
            $this->horometro_inicial = $tractor->hour_meter;
        }else{
            $this->horometro_inicial = 0;
        }

        return view('livewire.create-tractor-report',compact('tractors','labors','implements','users','locations','lotes'));
    }
}
