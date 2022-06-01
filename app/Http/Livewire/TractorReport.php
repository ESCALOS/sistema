<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Tractor;
use App\Models\TractorReport as ModelsTractorReport;
use Livewire\Component;

class TractorReport extends Component
{
    public $tractor;
    public $labor;
    public $implement;

    public function render()
    {
        $tractors = Tractor::all();
        $labors = Labor::all();
        $implements = Implement::all();

        $tractorReports = new ModelsTractorReport;

        if($this->tractor > 0){
            $tractorReports = $tractorReports->where('tractor_id',$this->tractor);
        }

        if($this->labor > 0){
            $tractorReports = $tractorReports->where('labor_id',$this->labor);
        }

        if($this->implement > 0){
            $tractorReports = $tractorReports->where('implement_id',$this->implement);
        }

        $tractorReports = $tractorReports->paginate(7);



        return view('livewire.tractor-report',compact('tractorReports','tractors','labors','implements'));
    }
}
