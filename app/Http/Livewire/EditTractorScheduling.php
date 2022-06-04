<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorReport;
use App\Models\User;
use Livewire\Component;

class EditTractorScheduling extends Component
{
    public $open_edit = false;
    public $idReport = 0;
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

    protected $listeners = ['capturar'];

    public function capturar($idReport){
        $this->idReport = $idReport;
    }

    public function render()
    {
        $users = User::all();
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();
        if($this->idReport > 0){
            $report = TractorReport::find($this->idReport);
        }else{
            $report = new TractorReport();
        }

        return view('livewire.edit-tractor-scheduling',compact('users','tractors','labors','implements','report'));
    }
}
