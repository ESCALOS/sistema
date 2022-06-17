<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorReport as ModelsTractorReport;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Livewire\WithPagination;

class TractorReport extends Component
{
    use WithPagination;

    public $idReporte=0;
    public $tractorReport;
    public $stractor;
    public $slabor;
    public $simplement;
    public $open_edit = false;

    public $location;
    public $lote;
    public $correlative;
    public $date;
    public $shift;
    public $user;
    public $tractor;
    public $labor;
    public $implement;
    public $hour_meter_start;
    public $hour_meter_end;
    public $observations;

    protected $rules = [
        'lote' => 'required|exists:lotes,id',
        'correlative' => 'required',
        'date' => 'required|date|date_format:Y-m-d',
        'shift' => 'required',
        'user' => 'required|exists:users,id',
        'tractor' => 'required|exists:tractors,id',
        'labor' => 'required|exists:labors,id',
        'implement' => 'required|exists:implements,id',
        'hour_meter_end' => "required|gt:hour_meter_start",
    ];

    protected $listeners = ['render'];

    public function seleccionar($id){
        $this->idReporte = $id;
    }
    public function anular(){
        $reporte = ModelsTractorReport::find($this->idReporte);
        $reporte->is_canceled = 1;
        $reporte->save();
        $this->idReporte = 0;
        $this->render();
    }

    public function editar(){
        $reporte = ModelsTractorReport::find($this->idReporte);
        $this->location = $reporte->lote->location->id;
        $this->lote = $reporte->lote_id;
        $this->correlative = $reporte->correlative;
        $this->date = $reporte->date;
        $this->shift = $reporte->shift;
        $this->user = $reporte->user_id;
        $this->tractor = $reporte->tractor_id;
        $this->labor = $reporte->labor_id;
        $this->implement = $reporte->implement_id;
        $this->hour_meter_start = $reporte->hour_meter_start;
        $this->hour_meter_end = $reporte->hour_meter_end;
        $this->observations = $reporte->observations;
        $this->open_edit = true;
    }

    public function actualizar(){
        $reporte = ModelsTractorReport::find($this->idReporte);
        $reporte->lote_id = $this->lote;
        $reporte->correlative = $this->correlative;
        $reporte->date = $this->date;
        $reporte->shift = $this->shift;
        $reporte->user_id = $this->user;
        $reporte->tractor_id = $this->tractor;
        $reporte->labor_id = $this->labor;
        $reporte->implement_id = $this->implement;
        $reporte->hour_meter_end = $this->hour_meter_end;
        $reporte->observations = $this->observations;
        $reporte->save();
        $this->open_edit = false;
        $this->render();
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
        $tractors = Tractor::where('location_id',$this->location)->get();
        $users = User::where('location_id',$this->location)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->get();
        $lotes = Lote::where('location_id',$this->location)->get();

        $tractorReports = ModelsTractorReport::where('is_canceled',0);

        if($this->stractor > 0){
            $tractorReports = $tractorReports->where('tractor_id',$this->stractor);
        }

        if($this->slabor > 0){
            $tractorReports = $tractorReports->where('labor_id',$this->slabor);
        }

        if($this->simplement > 0){
            $tractorReports = $tractorReports->where('implement_id',$this->simplement);
        }

        $tractorReports = $tractorReports->orderBy('id','desc')->paginate(6);



        return view('livewire.tractor-report',compact('tractorReports','tractors','labors','implements','users','locations','lotes','filtro_tractores','filtro_implementos'));
    }
}
