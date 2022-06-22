<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Location;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use PHPUnit\Framework\Constraint\Operator;

class ValidateRequestMaterial extends Component
{

    public $open_validate_resquest = false;

    public $idFechaPedido = 0;
    public $fecha_pedido = "";

    public $idOperador = 0;
    public $operador = "";

    public $idImplemento = 0;

    public $idSolicitudPedido = 0;

    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;

    public $incluidos = [];

    public function updatedTzone(){
        $this->reset('tsede','tlocation');
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->reset('tlocation');
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->incluidos = [];
    }

    public function mostrarImplementos($id,$name,$lastname){
        $this->idOperador = $id;
        $this->operador = $name.' '.$lastname;
        $this->open_validate_resquest = true;
    }

    public function updatedIdImplemento(){
        $order_request = OrderRequest::where('implement_id',$this->idImplemento)->where('state',"CERRADO")->first();
        if($order_request != null){
            $this->idSolicitudPedido = $order_request->id;
        }else{
            $this->idSolicitudPedido = 0;
        }
    }

    public function render()
    {
        /*-----------------------Obtener la fecha de pedido--------------------------------*/
        $order_date = OrderDate::where('state','ABIERTO')->orWhere('state','CERRADO')->first();
        if($order_date != null){
            $this->fecha_pedido = "PEDIDO PARA ".strtoupper(strftime("%A %d de %B de %Y", strtotime($order_date->order_date)));
        }else{
            $this->fecha_pedido = "No existe pedido que validar";
        }

        /*---------------------Mostrar zonas, sedes y ubicaciones--------------------*/
        $zones = Zone::all();

        $sedes = Sede::where('zone_id',$this->tzone)->get();

        $locations = Location::where('sede_id',$this->tsede)->get();

        /*------Obtener las solicitudes de pedido por ubicación y que estén cerradas----------------------------*/
        $order_requests = OrderRequest::join('implements',function ($join){
            $join->on('order_requests.implement_id','=','implements.id');
        })->where('implements.location_id',$this->tlocation)->where('state','CERRADO')->get();

        /*---------------------------Obtener los usuarios que tienen una solicitud cerrada----------*/
        if($order_requests != null){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->user_id);
            }
        }
        /*--------------------Mostrar a los usuarios que tienen solicitudes de pedido cerrada----------------------*/
        $users = DB::table('users')->whereIn('id',$this->incluidos)->get();

/*----------------------DATOS DEL MODAL DE VALIDACIÓN--------------------------------------------------------------------------------------------*/
        /*-----------Implementos del usuario------------------------------------*/
        $implements = OrderRequest::join('implements', function($join){
            $join->on('implements.id','=','order_requests.implement_id');
        })->join('implement_models', function($join){
            $join->on('implement_models.id','=','implements.implement_model_id');
        })->where('order_requests.user_id',$this->idOperador)->select('implements.*','implement_models.implement_model')->get();

        $order_request_detail_operator = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('state','PENDIENTE')->orWhere('state','CERRADO')->where('quantity','>',0)->get();

        $order_request_detail_planner = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('state','VALIDADO')->where('quantity','>',0)->get();

        return view('livewire.validate-request-material', compact('zones', 'sedes', 'locations','users','implements','order_request_detail_operator','order_request_detail_planner'));
    }
}
