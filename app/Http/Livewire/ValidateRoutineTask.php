<?php

namespace App\Http\Livewire;

use App\Models\Location;
use App\Models\Sede;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use phpDocumentor\Reflection\Types\This;

class ValidateRoutineTask extends Component
{
    public $tsede = 0;
    public $tlocation = 0;
    public $tdate = "";

    public $open_routine_task = false;

    public $routine_taks_id = 0;
    public $implement = "";

    public $observation = "";

    public function updatedTsede(){
        $this->resetExcept('tsede');
    }
    public function updatedTlocation(){
        $this->resetExcept('tsede','tlocation');
    }
    public function updatedTdate(){
        $this->resetExcept('tsede','tlocation','tdate');
    }
    public function updatedOpenRoutineTask(){
        $this->resetExcept('tsede','tlocation','tdate','open_routine_task');
    }
    /**
     * Obtener los datos de detalle del rutinario con el id del implemento y la fecha y abrir su modal
     * 
     * @param int $id ID del implemento
     * @param string $model Modelo del Implemento
     * @param string $number Número del implemento
     */
    public function mostrarRutinario($id,$model,$number){
        $this->routine_taks_id = DB::table('routine_tasks')->where('implement_id',$id)->where('date',$this->tdate)->first()->id;
        $this->implement = $model.' '.$number;
        $this->open_routine_task = true;
    }
    /**
     * Cambia el estado de la verificación de la tarea de verdadero a falso y viceversa
     * 
     * @param int $id ID del detalle de rutinario
     */
    public function cambiarVerificacion($id){
        $detalle_rutinario = DB::table('routine_task_details')->where('id',$id)->first()->is_checked;
        DB::table('routine_task_details')->where('id', $id)->update(['is_checked' => !$detalle_rutinario]);
    }

    public function registrarRutinario(){
        DB::table('routine_tasks')->where('id',$this->routine_taks_id)->update([    
                                                                                    'state' =>'CONCLUIDO',
                                                                                    'observation' => $this->observation,
                                                                                    'validated_by' => Auth::user()->id
                                                                                ]);
        $this->open_routine_task = false;
        $this->resetExcept('tsede','tlocation','tdate','open_routine_task');
    }

    public function render(){
        $sedes = Sede::where('zone_id',Auth::user()->location->sede->zone_id)->get();

        $locations = Location::where('sede_id',$this->tsede)->get();
        
        
        $dates = DB::table('routine_tasks')->join('implements',function($join){
                                                $join->on('implements.id','routine_tasks.implement_id');
                                            })->where('implements.location_id',$this->tlocation)
                                              ->where('routine_tasks.state','PENDIENTE')
                                              ->groupBy('routine_tasks.date')
                                              ->select('routine_tasks.date')
                                              ->get();

        $implements = DB::table('routine_tasks')->join('implements',function($join){
                                                    $join->on('implements.id','routine_tasks.implement_id');
                                                })->join('implement_models',function($join){
                                                    $join->on('implement_models.id','implements.implement_model_id');
                                                })->where('implements.location_id',$this->tlocation)
                                                  ->where('routine_tasks.state','PENDIENTE')
                                                  ->where('routine_tasks.date',$this->tdate)
                                                  ->select('implements.id','implement_models.implement_model','implements.implement_number')
                                                  ->get();
        if($this->open_routine_task){
            $tasks = DB::table('routine_task_details')->join('routine_tasks',function($join){
                                                            $join->on('routine_tasks.id','routine_task_details.routine_task_id');                                            
                                                        })->join('implements',function($join){
                                                            $join->on('implements.id','routine_tasks.implement_id');
                                                        })->join('tasks',function($join){
                                                            $join->on('tasks.id','routine_task_details.task_id');
                                                        })->join('components',function($join){
                                                            $join->on('components.id','tasks.component_id');
                                                        })->where('routine_tasks.id',$this->routine_taks_id)
                                                          ->select('routine_task_details.id','routine_task_details.is_checked','routine_tasks.id as routine_task_id','tasks.task','components.component')
                                                          ->get();
        }else{
            $tasks = [];
        }
        return view('livewire.validate-routine-task',compact('sedes','locations','dates','implements','tasks'));
    }
}
