<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\Implement;
use App\Models\Location;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Carbon\Carbon;

class AssignMaterialsOperator extends Component
{
/*----------ID DEL PEDIDO-----------------------------*/
    public $id_solicitud_pedido = 0;
/*------------VARIABLES PARA FILTRAR USUARIOS--------------*/
    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;
    public $tfecha = 0;
/*------------USUARIOS COPN PEDIDOS PENDIENTES A ASIGNAR----------*/
    public $incluidos = [];
/*------------DATOS DEL OPERADOR------------------------------*/
    public $id_operador = 0;
    public $operador = "";
/*-----------------DATOS DEL IMPLEMENTO----------------*/
    public $id_implemento = 0;
    public $implemento = "";
/*-----------------ESTADO DEL MODAL DE LISTAR PEDIDOS---------------*/
    public $open_request_list = false;
/*-----------------ESTADO DEL MODAL DE LISTAR PARA ASIGNAR AL OPERADOR---------------*/
    public $open_assign_material = false;
/*-----------------ID DEL DETALLE DEL PEDIDO A ASIGNAR---------------*/
    public $id_detalle_pedido = false;
/*-----------------DATOS DEL DETALLLE DEL PEDIDO A ASIGNAR-------------------------*/
    public $detalle_pedido_material = "";
    public $detalle_pedido_cantidad = 0;
    public $detalle_pedido_unidad_medida = "";
    public $detalle_pedid_precio = 0;
    public $detalle_pedido_precio_total = 0;
/*---------------------ESCUCHAR FUNCIONES-------------------*/
    protected $listeners = [];
/*------------------REGLAS DE VALIDACION----------------------*/
    protected function rules(){
        return [

        ];
    }
    /*-------------------MENSAJES DE VALIDACION---------------------*/
    protected function messages(){
        return [

        ];
    }
    /*----------------TRIGGERS DE FILTROS--------------------------------------------------*/
    public function updatedTzone(){
        $this->reset(['tsede','tlocation','tfecha']);
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->reset(['tlocation','tfecha']);
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->reset('tfecha');
        $this->incluidos = [];
    }
    public function updatedTfecha(){
        $this->reset('id_solicitud_pedido');
        $this->incluidos = [];
    }
/*-------------------RESERTEAR CAMPOS AL CERRAR EL MODAL DE LA LISTA DE PEDIDOS---------------*/
    public function updatedOpenRequestList(){
        $this->reset('id_implemento','implemento','id_solicitud_pedido');
    }
/*----------------MOSTRAR LISTA DE PEDIDOS CUANDO CAMBIE EL IMPLEMENTO-----*/
    public function updatedIdImplemento(){
        $order_request = OrderRequest::where('implement_id',$this->id_implemento)->where('state',"VALIDADO")->first();
        if(isset($order_request)){
            $this->id_solicitud_pedido = $order_request->id;
        }else{
            $this->id_solicitud_pedido = 0;
        }
    }
/*----------------MOSTRAR MODAL LISTA DE PEDIDOS-------------------------*/
    public function mostrarPedidos($id,$name,$lastname){
        $this->id_operador = $id;
        $this->operador = $name.' '.$lastname;
        $this->open_request_list = true;
    }
/*--------------MODAL PARA ASIGNAR AL OPERADOR------------------*/
    public function modalAsignarOperador($id){
        $this->id_detalle_pedido = $id;
        $detalle_pedido = OrderRequestDetail::find($id);
        $this->detalle_pedido_material = $detalle_pedido->item->item;
        $this->detalle_pedido_cantidad = floatval($detalle_pedido->quantity);
        $this->detalle_pedido_unidad_medida = $detalle_pedido->item->measurementUnit->abbreviation;
        $this->detalle_pedido_precio = floatval($detalle_pedido->estimated_price);
        if($this->detalle_pedido_cantidad > 0 && $this->detalle_pedid_precio > 0){
            $this->detalle_pedido_precio_total = $this->detalle_pedido_cantidad * $this->detalle_pedid_precio;
        }else{
            $this->detalle_pedido_precio_total = 0;
        }
        $this->detalle_pedido_precio_total = 150.50;
        $this->open_assign_material =true;

    }
/*--------------ASIGNAR MATERIAL AL OPERADOR-------------------------*/
    public function asignarMaterial(){

    }
/*-------------FUNCION RENDER-------------------------------------------*/
    public function render()
    {
    /*------------------DATOS PARA LAS SOLICITUDES DE PEDIDO POR USUARIO----------------------------*/
        /*---------------------Mostrar zonas, sedes , ubicaciones y fechas de pedido--------------------*/
        $zones = Zone::all();

        $sedes = Sede::where('zone_id',$this->tzone)->get();

        $locations = Location::where('sede_id',$this->tsede)->get();

        $order_dates = OrderDate::where('state','CERRADO')->get();

        /*------Obtener las solicitudes de pedido por ubicación y fecha, y que estén validadas----------------------------*/
        if($this->tlocation > 0 && $this->tfecha > 0){
            $order_requests = OrderRequest::join('implements',function ($join){
                $join->on('order_requests.implement_id','=','implements.id');
            })->where('implements.location_id',$this->tlocation)->where('order_date_id',$this->tfecha)->where('state','VALIDADO')->orWhere('state','INCOMPLETO')->get();
        }
        /*---------------------------Obtener los usuarios que tienen una solicitud cerrada----------*/
        if(isset($order_requests)){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->user_id);
            }
        }
        /*--------------------Mostrar a los usuarios que tienen solicitudes de pedido cerrada----------------------*/
        $users = DB::table('users')->whereIn('id',$this->incluidos)->get();

    /*----------------------DATOS DEL MODAL DE PEDIDOS PARA ASIGNAR ------------------------------------------*/
        $implements = OrderRequest::join('implements', function($join){
            $join->on('implements.id','=','order_requests.implement_id');
        })->join('implement_models', function($join){
            $join->on('implement_models.id','=','implements.implement_model_id');
        })->where('order_requests.user_id',$this->id_operador)->where('order_requests.state','VALIDADO')->select('implements.*','implement_models.implement_model')->get();
    /*------------------OBTENER PEDIDO DEL IMPLEMENTO----------------------------------------*/
        $order_request_detail = OrderRequestDetail::where('order_request_id',$this->id_solicitud_pedido)->where('quantity','>',0)->where('state','VALIDADO')->get();
    /*----------------------DATOS DEL RENDERIZADOS---------------------------------------------------------*/
        return view('livewire.assign-materials-operator', compact('zones', 'sedes', 'locations','order_dates','users','implements','order_request_detail'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
