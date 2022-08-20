<?php

namespace App\Http\Livewire;

use Livewire\Component;

class RoutineTask extends Component
{
    public function render()
    {
        $routines_tasks = DB::table('routine-')->select()->get()
        
        return view('livewire.routine-task');
    }
}
