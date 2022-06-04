<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorReport as ModelsTractorReport;
use Livewire\Component;
use Livewire\WithPagination;

class TractorReport extends Component
{
    use WithPagination;

    public $idReporte=0;
    public $stractor;
    public $slabor;
    public $simplement;

    protected $listeners = ['render'];

    public function seleccionar($id){
        $this->idReporte = $id;
        $this->emit('capturar',$this->idReporte);
    }
    public function anular(){
        $reporte = ModelsTractorReport::find($this->idReporte);
        $reporte->is_canceled = 1;
        $reporte->save();
        $this->idReporte = 0;
        $this->render();
    }

    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

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

        $tractorReports = $tractorReports->orderBy('id','desc')->paginate(7);



        return view('livewire.tractor-report',compact('tractorReports','tractors','labors','implements'));
    }
}
