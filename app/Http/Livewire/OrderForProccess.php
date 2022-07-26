<?php

namespace App\Http\Livewire;

use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\Sede;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class OrderForProccess extends Component
{
    use WithPagination;

    public $open_en_proceso = false;

    public $open_en_proceso_implemento = false;

    public $fecha_pedido_en_proceso = "";
    public $tsede;

    public $item_id = 0;
    public $detalle_item = "";
    public $precio_item = 0;

    public $operador_id = 0;
    public $nombre_operador = "";

    public $sede = "";

    public $search = "";

    public $incluidos = [];

    protected $listeners = ['detalleOperador','procesarPedido'];

    public function updatingTsede(){
        $this->resetPage();
    }

    public function updatingSearch(){
        $this->resetPage();
    }

    public function detalleOperador($item){
        $this->item_id = $item;
        $material = Item::find($item);
        $this->detalle_item = $material->item;
        $this->precio_item = $material->estimated_price;
        $this->open_en_proceso = true;
    }

    public function detalleImplemento($operador_id){
        $this->operador_id = $operador_id;
        $operador = User::select('name','lastname')->find($operador_id);
        $this->nombre_operador = $operador->name.' '.$operador->lastname;
        $this->open_en_proceso_implemento = true;
    }

    public function procesarPedido(){
        $order_requests = OrderRequest::join('implements',function($join){
            $join->on('implements.id','order_requests.implement_id');
        })->join('locations',function($join){
            $join->on('locations.id','implements.location_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','locations.sede_id');
        })->where('sedes.id',$this->tsede)->select('order_requests.id')->get();

        if(isset($order_requests)){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->id);
            }
        }

        OrderRequest::whereIn('id',$this->incluidos)->update(['state'=>'EN PROCESO']);

        $this->resetExcept('open_en_proceso');
        $this->render();
    }

    public function updatedTsede(){
        if($this->tsede > 0){
            $this->sede = Sede::select('sede')->find($this->tsede)->sede;

        }else{
            $this->resetExcept('fecha_pedido_en_proceso','tsede');
        }
    }

    public function updatedOpenEnProceso(){
        if(!$this->open_en_proceso){
            $this->reset('item_id','detalle_item','precio_item');
        }
    }

    public function updatedOpenEnProcesoImplemento(){
        if(!$this->open_en_proceso_implemento){
            $this->reset('operador_id','nombre_operador');
        }
    }

    public function render()
    {
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
            $sedes = Sede::join('zones',function($join){
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
                    })->where('zones.id',$zona_usuario)
                        ->where('order_requests.state','VALIDADO')
                        ->select('sedes.id','sedes.sede')
                        ->groupBy('sedes.id')
                        ->get();

            $order_date = Sede::join('zones',function($join){
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
                        })->where('zones.id',$zona_usuario)
                            ->where('order_requests.state','VALIDADO')
                            ->select('order_dates.order_date')
                            ->first();

            $this->fecha_pedido_en_proceso = strtoupper(strftime("%A %d de %B de %Y", strtotime($order_date->order_date)));

            if($this->tsede > 0){
                $solicitudes_en_proceso = Sede::join('locations',function($join){
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
                                        })->where('order_requests.state','VALIDADO')->where('order_request_details.state','VALIDADO')
                                            ->where('sedes.id',$this->tsede);
                if($this->search != ""){
                    $solicitudes_en_proceso = $solicitudes_en_proceso->where('items.sku','like',$this->search.'%')->orWhere('items.item','like',$this->search.'%');
                }
                $solicitudes_en_proceso = $solicitudes_en_proceso->select(DB::raw('order_request_details.item_id,items.sku,items.type,items.item,SUM(order_request_details.quantity) as quantity,measurement_units.abbreviation,order_request_details.estimated_price as unit_price'))
                                            ->groupBy('order_request_details.item_id')
                                            ->paginate(5);
            }else{
                $solicitudes_en_proceso = NULL;
            }

        }else{
            $this->fecha_pedido_en_proceso = "";
            $sedes = NULL;
            $solicitudes_en_proceso = NULL;
        }

        if($this->item_id > 0){
            $items_por_operador = Sede::join('locations',function($join){
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
                                })->where('order_requests.state','VALIDADO')->where('order_request_details.state','VALIDADO')->where('sedes.id',$this->tsede)
                                    ->where('order_request_details.item_id',$this->item_id)
                                    ->select(DB::raw('order_requests.user_id,users.code,CONCAT(users.name," ",users.lastname) as name,SUM(order_request_details.quantity) as quantity,measurement_units.abbreviation,order_request_details.estimated_price as unit_price'))
                                    ->groupBy('items.id')
                                    ->groupBy('users.id')
                                    ->get();
        }else{
            $items_por_operador = NULL;
        }

        if($this->operador_id > 0){
            $items_por_implemento = Sede::join('locations',function($join){
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
                                    })->join('implement_models',function($join){
                                        $join->on('implements.implement_model_id','implement_models.id');
                                    })->where('order_requests.state','VALIDADO')->where('order_request_details.state','VALIDADO')->where('sedes.id',$this->tsede)
                                        ->where('items.id',$this->item_id)
                                        ->where('users.id',$this->operador_id)
                                        ->select(DB::raw('CONCAT(implement_models.implement_model," ",implements.implement_number) as implement,SUM(order_request_details.quantity) as quantity,measurement_units.abbreviation,order_request_details.estimated_price as unit_price'))
                                        ->groupBy('items.id')
                                        ->groupBy('users.id')
                                        ->groupBy('implements.id')
                                        ->get();
        }else{
            $items_por_implemento = NULL;
        }

        return view('livewire.order-for-proccess',compact('sedes','solicitudes_en_proceso','items_por_operador','items_por_implemento'));
    }
}
