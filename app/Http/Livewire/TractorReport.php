<?php

namespace App\Http\Livewire;

use App\Models\TractorReport as ModelsTractorReport;
use Livewire\Component;

class TractorReport extends Component
{
    public $search;

    public function render()
    {
        if($this->search == 'MAÑANA' || $this->search == 'NOCHE'){
            $tractorReports = ModelsTractorReport::where('shift','like',$this->search)->paginate(7);
        }else{
            $tractorReports = ModelsTractorReport::paginate(7);
        }
        return view('livewire.tractor-report',compact('tractorReports'));
    }
}
