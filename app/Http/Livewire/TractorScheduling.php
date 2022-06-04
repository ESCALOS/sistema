<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use Livewire\Component;

class TractorScheduling extends Component
{
    public $idSchedule = 0;
    public $stractor;
    public $slabor;
    public $simplement;

    protected $listeners = ['render'];

    public function seleccionar($id){
        $this->idSchedule = $id;
        $this->emit('capturar',$this->idSchedule);
    }

    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

        $tractorSchedulings = ModelsTractorScheduling::where('is_canceled',0);

        if($this->stractor > 0){
            $tractorSchedulings = $tractorSchedulings->where('tractor_id',$this->stractor);
        }

        if($this->slabor > 0){
            $tractorSchedulings = $tractorSchedulings->where('labor_id',$this->slabor);
        }

        if($this->simplement > 0){
            $tractorSchedulings = $tractorSchedulings->where('implement_id',$this->simplement);
        }

        $tractorSchedulings = $tractorSchedulings->orderBy('id','desc')->paginate(7);



        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements'));
    }
}
