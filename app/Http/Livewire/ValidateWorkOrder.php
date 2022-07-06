<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\WorkOrder;
use App\Models\WorkOrderDetail;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class ValidateWorkOrder extends Component
{
    public $open_validate_work_order = false;

    public $orden_trabajo = 0;

    public $modelo_implemento = 0;

    public $implemento = 0;

    public $nombre_modelo = "";
    public $numero_implemento = "";
    public $nombre_operador = "";
    public $id_operador = "";

    public function updatedOpenValidateWorkOrder(){
        if(!$this->open_validate_work_order){
            $this->reset('orden_trabajo','nombre_modelo','numero_implemento','nombre_operador');
        }
    }

    public function mostrarOrdenTrabajo($id,$modelo,$numero,$nombre,$apellido){
        $this->orden_trabajo = $id;
        $this->nombre_modelo = $modelo;
        $this->numero_implemento = $numero;
        $this->nombre_operador = $nombre.' '.$apellido;
        $this->open_validate_work_order = true;
    }

    public function render()
    {
        $implement_models = WorkOrder::join('implements',function($join){
            $join->on('work_orders.implement_id','=','implements.id');
        })->join('implement_models',function($join){
            $join->on('implement_models.id','=','implements.implement_model_id');
        })->select('implement_models.id','implement_models.implement_model',)
            ->where('work_orders.location_id',Auth::user()->location_id)
            ->groupBy('implement_models.id')
            ->get();

        if($this->modelo_implemento > 0){
            $implements =  WorkOrder::join('implements',function($join){
                $join->on('work_orders.implement_id','=','implements.id');
            })->join('implement_models',function($join){
                $join->on('implement_models.id','=','implements.implement_model_id');
            })->join('users',function($join){
                $join->on('users.id','=','work_orders.user_id');
            })->select('work_orders.id','implement_models.implement_model','implements.implement_number','users.name','users.lastname')
            ->where('work_orders.location_id',Auth::user()->location_id)
            ->where('implement_models.id',$this->modelo_implemento)
            ->get();
        }else{
            $implements = NULL;
        }



        if($this->orden_trabajo > 0){
            $tareas = WorkOrderDetail::where('work_order_id',$this->orden_trabajo)->where('state','RECOMENDADO')->get();
            $tareas_rechazadas = WorkOrderDetail::where('work_order_id',$this->orden_trabajo)->where('state','RECHAZADO')->get();
        }else{
            $tareas = NULL;
            $tareas_rechazadas = NULL;
        }

        return view('livewire.validate-work-order',compact('implement_models','implements','tareas','tareas_rechazadas'));
    }
}
