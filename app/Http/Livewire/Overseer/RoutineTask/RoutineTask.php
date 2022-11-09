<?php

namespace App\Http\Livewire\Overseer\RoutineTask;

use App\Models\RoutineTask as ModelsRoutineTask;
use Livewire\Component;
use Livewire\WithPagination;

class RoutineTask extends Component
{
    use WithPagination;

    public function render()
    {
        $routine_tasks = ModelsRoutineTask::orderBy('id','desc')->paginate(5);

        return view('livewire.overseer.routine-task.routine-task',compact('routine_tasks'));
    }
}