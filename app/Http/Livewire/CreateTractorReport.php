<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorReport;
use App\Models\User;
use Livewire\Component;

class CreateTractorReport extends Component
{
    public $open = false;
    public $correlative;
    public $date;
    public $shift = "MAÑANA";
    public $user;
    public $tractor;
    public $labor;
    public $implement;
    public $horometro_inicial = "";
    public $hour_meter_end;
    public $observations;

    public function store(){
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
            'hour_meter_start' => $hour_meter_start,
            'hour_meter_end' => $this->hour_meter_end,
            'hours' => $this->hour_meter_end - $hour_meter_start,
            'observations' => $this->observations,
        ]);
        $this->reset();
    }


    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();
        $users = User::all();

        if($this->tractor > 0){
            $tractor = Tractor::find($this->tractor);
            $this->horometro_inicial = $tractor->hour_meter;
        }else{
            $this->horometro_inicial = "";
        }

        return view('livewire.create-tractor-report',compact('tractors','labors','implements','users'));
    }
}
