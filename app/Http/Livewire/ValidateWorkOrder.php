<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\User;
use App\Models\WorkOrder;
use App\Models\WorkOrderDetail;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class ValidateWorkOrder extends Component
{
    public $open_validate_work_order = false;

    public $orden_trabajo = 0;

    public $dia;

    public $nombre_implemento = "";
    public $nombre_operador = "";

    protected $listeners = ['validarRecambio','rechazarRecambio'];

    public function updatedOpenValidateWorkOrder(){
        if(!$this->open_validate_work_order){
            $this->reset('orden_trabajo');
        }
    }

    public function mostrarComponentesRecambio($id){
        $this->orden_trabajo = $id;
        $work_order = WorkOrder::find($id);

        $implemento = Implement::find($work_order->implement_id);
        $this->nombre_implemento = $implemento->implementModel->implement_model.' '.$implemento->implement_number;

        $user = User::find($work_order->user_id);
        $this->nombre_operador = $user->name. ' '.$user->lastname;

        $this->open_validate_work_order = true;
    }

    public function validarRecambio(){
        WorkOrderDetail::where('work_order_id',$this->orden_trabajo)
                        ->where('state','RECOMENDADO')
                        ->update(['state' => 'ACEPTADO']);

        $work_order = WorkOrder::find($this->orden_trabajo);
        
        $work_order->state = "PENDIENTE";
        $work_order->save();

        $this->render();
        $this->open_validate_work_order = false;
    }

    public function rechazarRecambio(){
        WorkOrderDetail::where('work_order_id',$this->orden_trabajo)
                        ->where('state','RECOMENDADO')
                        ->update(['state' => 'NO ACEPTADO']);

        $work_order = WorkOrder::find($this->orden_trabajo);
        $work_order->state = "PENDIENTE";
        $work_order->save();

        $this->render();
        $this->open_validate_work_order = false;
    }

    public function render()
    {
        /*-------------------DECLARAR VARIABLES------------------------*/
        $implementos_para_recambio = NULL;
        $componentes = NULL;
        $piezas = NULL;
        $tareas = NULL;
        /*-------------------Fechas de pedido pendientes en validar----*/
        $fechas = WorkOrder::where('state','NO VALIDADO')
                            ->where('location_id',Auth::user()->location_id)
                            ->select('work_orders.date')
                            ->groupBy('work_orders.date')
                            ->get();

        if($this->dia != ""){
            $implementos_para_recambio = WorkOrder::join('implements',function($join){
                $join->on('implements.id','=','work_orders.implement_id');
            })->join('implement_models',function($join){
                $join->on('implement_models.id','implements.implement_model_id');
            })->where('work_orders.state','NO VALIDADO')
                ->where('date',$this->dia)
                ->select('implements.*','work_orders.id as work_order','implement_models.implement_model')
                ->get();
            if($this->orden_trabajo > 0){

                $componentes = WorkOrderDetail::join('component_implement',function($join){
                    $join->on('component_implement.id','=','work_order_details.component_implement_id');
                })->join('components',function($join){
                    $join->on('components.id','=','component_implement.component_id');
                })->where('work_order_details.work_order_id',$this->orden_trabajo)
                    ->where('work_order_details.state','RECOMENDADO')
                    ->whereNotNull('work_order_details.component_implement_id')
                    ->select('work_order_details.task_id','component_implement.component_id as componente_id','components.component as componente')
                    ->get();

                $piezas = WorkOrderDetail::join('component_part',function($join){
                    $join->on('component_part.id','=','work_order_details.component_part_id');
                })->join('components as p',function($join){
                    $join->on('p.id','=','component_part.part');
                })->join('component_implement',function($join){
                    $join->on('component_implement.id','=','component_part.component_implement_id');
                })->join('components as c',function($join){
                    $join->on('c.id','=','component_implement.component_id');
                })->where('work_order_details.work_order_id',$this->orden_trabajo)
                    ->where('work_order_details.state','RECOMENDADO')
                    ->whereNotNull('work_order_details.component_part_id')
                    ->select('work_order_details.task_id','component_part.part as pieza_id','p.component as pieza','c.component as componente')
                    ->get();
            }
        }

        return view('livewire.validate-work-order',compact('fechas','implementos_para_recambio','componentes','piezas','tareas'));
    }
}
