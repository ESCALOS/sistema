<?php

namespace App\Http\Livewire;

use App\Models\TractorReport as ModelsTractorReport;
use Livewire\Component;

class TractorReport extends Component
{

    public function render()
    {

        $tractorReports = ModelsTractorReport::paginate(7);

        return view('livewire.tractor-report',compact('tractorReports'));
    }
}
