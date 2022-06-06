<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Tractor;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use App\Models\User;
use Livewire\Component;
use Livewire\WithPagination;

class TractorScheduling extends Component
{
    use WithPagination;

    public $idSchedule = 0;
    public $stractor;
    public $slabor;
    public $simplement;
    public $open_edit = false;

    public $location;
    public $date;
    public $shift;
    public $user;
    public $tractor;
    public $labor;
    public $implement;

    protected $listeners = ['render'];

    public function seleccionar($id){
        $this->idSchedule = $id;
        $this->emit('capturar',$this->idSchedule);
    }

    public function anular(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $scheduling->is_canceled = 1;
        $scheduling->save();
        $this->idSchedule = 0;
        $this->render();
    }

    public function editar(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $this->location = $scheduling->location_id;
        $this->date = $scheduling->date;
        $this->shift = $scheduling->shift;
        $this->user = $scheduling->user_id;
        $this->tractor = $scheduling->tractor_id;
        $this->labor = $scheduling->labor_id;
        $this->implement = $scheduling->implement_id;
        $this->open_edit = true;
    }

    public function actualizar(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $scheduling->location_id = $this->location;
        $scheduling->date = $this->date;
        $scheduling->shift = $this->shift;
        $scheduling->user_id = $this->user;
        $scheduling->tractor_id = $this->tractor;
        $scheduling->labor_id = $this->labor;
        $scheduling->implement_id = $this->implement;
        $scheduling->save();
        $this->open_edit = false;
        $this->render();
    }

    public function render()
    {
        $locations = Location::all();
        $users = User::all();
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



        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements','locations','users'));
    }
}
