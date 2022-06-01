<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use Livewire\Component;

class TractorScheduling extends Component
{
    public $tractor;
    public $labor;
    public $implement;

    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

        $tractorSchedulings = new ModelsTractorScheduling;

        if($this->tractor > 0){
            $tractorSchedulings = $tractorSchedulings->where('tractor_id',$this->tractor);
        }

        if($this->labor > 0){
            $tractorSchedulings = $tractorSchedulings->where('labor_id',$this->labor);
        }

        if($this->implement > 0){
            $tractorSchedulings = $tractorSchedulings->where('implement_id',$this->implement);
        }

        $tractorSchedulings = $tractorSchedulings->paginate(7);



        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements'));
    }
}
