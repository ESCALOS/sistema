<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Livewire\WithPagination;
use phpDocumentor\Reflection\Types\This;

class TractorScheduling extends Component
{
    use WithPagination;

    public $idSchedule = 0;
    public $stractor;
    public $slabor;
    public $simplement;
    public $open_edit = false;

    public $location;
    public $lote;
    public $date;
    public $shift;
    public $user;
    public $tractor;
    public $labor;
    public $implement;

    protected $listeners = ['render'];

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
        $this->location = $scheduling->lote->location->id;
        $this->lote = $scheduling->lote_id;
        $this->date = $scheduling->date;
        $this->shift = $scheduling->shift;
        $this->user = $scheduling->user_id;
        $this->tractor = $scheduling->tractor_id;
        $this->labor = $scheduling->labor_id;
        $this->implement = $scheduling->implement_id;
        $this->open_edit = true;
    }

    public function actualizar(){
        $this->validate();
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $scheduling->lote_id = $this->lote;
        $scheduling->date = $this->date;
        $scheduling->shift = $this->shift;
        $scheduling->user_id = $this->user;
        $scheduling->tractor_id = $this->tractor;
        $scheduling->labor_id = $this->labor;
        $scheduling->implement_id = $this->implement;
        $scheduling->save();
        $this->open_edit = false;
        $this->render();
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
        $sede_general = Auth::user()->location->sede->id;
        $filtro_tractores = Tractor::join('locations',function($join){
            $join->on('locations.id','=','tractors.location_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','=','locations.sede_id');
        })->where('sedes.id','=',$sede_general)->select('tractors.*')->get();

        $filtro_implementos = Implement::join('locations',function($join){
            $join->on('locations.id','=','implements.location_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','=','locations.sede_id');
        })->where('sedes.id','=',$sede_general)->select('implements.*')->get();

        /*----------------CRUD-------------------------------------------------------*/
        $locations = Location::where('sede_id',Auth::user()->location->sede->id)->get();
        $lotes = Lote::where('location_id',$this->location)->get();
        $users = User::where('location_id',$this->location)->get();
        $tractors = Tractor::where('location_id',$this->location)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->get();

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

        $tractorSchedulings = $tractorSchedulings->orderBy('id','desc')->paginate(6);



        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements','locations','users','lotes','filtro_tractores','filtro_implementos'));
    }
}
