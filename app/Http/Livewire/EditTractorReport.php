<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\User;
use Livewire\Component;

class EditTractorReport extends Component
{
    public $open = false;
    public $idReporte;
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

    public function save($idReporte){
        $this->idReporte = $idReporte;
    }

    public function render()
    {
        $users = User::all();
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

        return view('livewire.edit-tractor-report',compact('users','tractors','labors','implements'));
    }
}
