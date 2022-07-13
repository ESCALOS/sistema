<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\WorkOrder;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class PendingMaintenanceList extends Component
{
    public $dia = "";

    public $nombre_implemento = "";

    public $orden_trabajo = 0;

    public $open_prereserva_materiales = false;

    public $ubicacion = 0;

    public function mostrarTareas($id){
        $this->orden_trabajo = $id;
        $work_order = WorkOrder::find($id);
        $this->ubicacion = $work_order->location_id;
        $implement = Implement::find($work_order->implement_id);
        $this->nombre_implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;

        $this->open_prereserva_materiales = true;
    }

    public function render()
    {
        $implementos = NULL;
        $tareas = NULL;
        $materiales = NULL;

        $fechas = WorkOrder::where('state','NO VALIDADO')
                            ->where('user_id',Auth::user()->id)
                            ->select('date')
                            ->groupBy('date')
                            ->get();

        if($this->dia != ""){
            $implementos = WorkOrder::join('implements',function($join){
                $join->on('implements.id','=','work_orders.implement_id');
            })->join('implement_models',function($join){
                $join->on('implement_models.id','implements.implement_model_id');
            })->where('work_orders.state','PENDIENTE')
                ->where('work_orders.user_id',Auth::user()->id)
                ->where('date',$this->dia)
                ->select('implements.*','work_orders.id as work_order','implement_models.implement_model')
                ->get();

            if($this->orden_trabajo > 0){
                $materiales = DB::table('work_order_required_materials as w')->join('items',function($join){
                    $join->on('w.item_id','=','items.id');
                })->where('w.work_order_id',$this->orden_trabajo)
                    ->select('w.item_id as id','items.item','items.sku','items.brand_id','w.quantity')
                    ->get();

                $tareas = DB::table('lista_mantenimiento')->where('work_order_id',$this->orden_trabajo)->get();
            }
        }

        return view('livewire.pending-maintenance-list',compact('fechas','implementos','tareas','materiales'));
    }
}
