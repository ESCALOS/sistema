<?php

namespace App\Http\Livewire;

use App\Models\Item;
use App\Models\Sede;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class OrderForProccess extends Component
{
    use WithPagination;

    public $open_en_proceso = false;

    public $fecha_pedido_en_proceso = "";
    public $tsede;

    public $item_id = 0;
    public $detalle_item = "";

    public $operador_id = 0;
    public $nombre_operador = "";

    public $sede = "";

    protected $listeners = ['detalleOperador'];

    public function detalleOperador($item){
        $this->item_id = $item;
        $this->detalle_item = Item::find($item)->item;
        $this->open_en_proceso = true;
    }

    public function detalleImplemento($operador){
        $this->operador_id = $operador;
    }

    public function render()
    {
    /*-----------Nombre de la sede-------------------------------*/
        if($this->tsede > 0){
            $this->sede = Sede::find($this->tsede)->sede;
        }else{
            $this->sede = "";
        }
    /*-----------Ver si el pedido está validado y falta marca en proceso---------------*/
        $zona_usuario = Auth::user()->location->sede->zone->id;
        $en_proceso = Sede::join('zones',function($join){
            $join->on('zones.id','=','sedes.zone_id');
        })->join('locations',function($join){
            $join->on('locations.sede_id','sedes.id');
        })->join('implements',function($join){
            $join->on('implements.location_id','locations.id');
        })->join('order_requests',function($join){
            $join->on('order_requests.implement_id','=','implements.id');
        })->join('users',function($join){
            $join->on('users.id','order_requests.user_id');
        })->join('order_request_details',function($join){
            $join->on('order_request_details.order_request_id','=','order_requests.id');
        })->join('items',function($join){
            $join->on('items.id','order_request_details.item_id');
        })->join('measurement_units',function($join){
            $join->on('measurement_units.id','items.measurement_unit_id');
        })->join('order_dates',function($join){
            $join->on('order_dates.id','order_requests.order_date_id');
        })->where('zones.id',$zona_usuario)->where('order_requests.state','VALIDADO');

        if($en_proceso->exists()){
            $sedes = $en_proceso->select('sedes.id','sedes.sede')->groupBy('sedes.id')->get();
            $order_date = $en_proceso->select('order_dates.order_date')->first();
            $this->fecha_pedido_en_proceso = strtoupper(strftime("%A %d de %B de %Y", strtotime($order_date->order_date)));

            if($this->tsede > 0){
                $solicitudes_en_proceso = $en_proceso->where('order_request_details.state','VALIDADO')->where('sedes.id',$this->tsede)
                                                        ->select(DB::raw('order_request_details.item_id,items.sku,items.item,SUM(order_request_details.quantity) as quantity,measurement_units.abbreviation,order_request_details.estimated_price as unit_price'))
                                                        ->groupBy('order_request_details.item_id')
                                                        ->paginate(5);
            }else{
                $solicitudes_en_proceso = NULL;
            }

        }else{
            $this->fecha_pedido_en_proceso = "";
            $sedes = NULL;
        }

        if($this->item_id > 0){
            $items_por_operador = $en_proceso->where('order_request_details.state','VALIDADO')->where('sedes.id',$this->tsede)
                                                ->where('order_request_details.item_id',$this->item_id)
                                                ->select(DB::raw('order_requests.user_id,users.code,CONCAT(users.name," ",users.lastname) as name,SUM(order_request_details.quantity) as quantity,measurement_units.abbreviation,order_request_details.estimated_price as unit_price'))
                                                ->groupBy('order_request_details.item_id')
                                                ->groupBy('order_requests.user_id')
                                                ->paginate(5);
        }else{
            $items_por_operador = NULL;
        }

        if($this->operador_id > 0){
            $items_por_implemento = "";
        }else{
            $items_por_implemento = NULL;
        }

        return view('livewire.order-for-proccess',compact('sedes','solicitudes_en_proceso','items_por_operador'));
    }
}
