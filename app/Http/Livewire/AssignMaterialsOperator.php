<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\Implement;
use App\Models\Location;
use App\Models\OperatorStock;
use App\Models\OperatorStockDetail;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Sede;
use App\Models\User;
use App\Models\Warehouse;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

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
/*-----------------CANTIDAD PEDIDA-------------------------------------*/
    public $detalle_pedido_cantidad_pedida = 0;
/*-----------------DATOS DEL DETALLLE DEL PEDIDO A ASIGNAR-------------------------*/
    public $detalle_pedido_material = "";
    public $detalle_pedido_cantidad = 0;
    public $detalle_pedido_unidad_medida = "";
    public $detalle_pedido_precio = 0;
    public $detalle_pedido_precio_total = 0;
/*---------------------ESCUCHAR FUNCIONES-------------------*/
    protected $listeners = ['anularAsignacionMaterial'];
/*------------------REGLAS DE VALIDACION----------------------*/
    protected function rules(){
        return [
            'detalle_pedido_cantidad' =>['required','numeric','lte:detalle_pedido_cantidad_pedida','min:0.01'],
        ];
    }
/*-------------------MENSAJES DE VALIDACION---------------------*/
    protected function messages(){
        return [
            'detalle_pedido_cantidad.required' => "Ingrese una cantidad",
            'detalle_pedido_cantidad.numeric' => 'Debe ser un número',
            'detalle_pedido_cantidad.min' => 'Asigne más cantidad',
            'detalle_pedido_cantidad.lte' => 'Falta asignar solamente '.$this->detalle_pedido_cantidad_pedida,
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
        if(!$this->open_request_list){
            $this->reset('id_implemento','implemento','id_solicitud_pedido','id_operador','operador');
        }
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
        $this->detalle_pedido_cantidad = floatval($detalle_pedido->quantity - $detalle_pedido->assigned_quantity);
        $this->detalle_pedido_cantidad_pedida = floatval($detalle_pedido->quantity - $detalle_pedido->assigned_quantity);
        $this->detalle_pedido_unidad_medida = $detalle_pedido->item->measurementUnit->abbreviation;
        $this->detalle_pedido_precio = floatval($detalle_pedido->estimated_price);
        if($this->detalle_pedido_cantidad > 0 && $this->detalle_pedido_precio > 0){
            $this->detalle_pedido_precio_total = $this->detalle_pedido_cantidad * $this->detalle_pedido_precio;
        }else{
            $this->detalle_pedido_precio_total = 0;
        }
        $this->open_assign_material =true;
    }
/*------------Actualizar precio según cantidad----------------------*/
    public function updatedDetallePedidoCantidad(){
        if($this->detalle_pedido_cantidad > 0){
            $this->detalle_pedido_precio_total = $this->detalle_pedido_cantidad * $this->detalle_pedido_precio;
        }else{
            $this->detalle_pedido_precio_total = 0;
        }
    }
/*--------------ASIGNAR MATERIAL AL OPERADOR-------------------------*/
    public function asignarMaterial(){
        $this->validate();
        if($this->detalle_pedido_cantidad > 0 && $this->detalle_pedido_cantidad <= $this->detalle_pedido_cantidad_pedida){
            /*-----------Obtener el detalle de la solicitud de pedido----------------------------*/
            $detalle_pedido = OrderRequestDetail::find($this->id_detalle_pedido);
            /*--------------------Obtener datos del operador-----------------------------*/
            $operador_data = User::find($this->id_operador);
            /*-----------Asignar cantidad al operador------------------------------------------*/
            OperatorStockDetail::create([
                'user_id' => $this->id_operador,
                'item_id' => $detalle_pedido->item_id,
                'movement' => 'INGRESO',
                'quantity' => $this->detalle_pedido_cantidad,
                'price' => $detalle_pedido->estimated_price,
                'warehouse_id' => $operador_data->location_id,
                'state' => "CONFIRMADO",
                'order_request_detail_id' => $this->id_detalle_pedido,
            ]);
            /*--------Anotar la cantidad asignada en la solicityd de pedido--------------------------------*/
            $detalle_pedido->assigned_quantity = $detalle_pedido->assigned_quantity + $this->detalle_pedido_cantidad;
            if($detalle_pedido->assigned_quantity == $detalle_pedido->quantity){
                $detalle_pedido->assigned_state = 'ASIGNADO';
            }
            $detalle_pedido->save();
            /*---------Alertar de operación exitosa----------------*/
            $this->emit('alert');
            /*--------Cerrar Modal-----------------------*/
            $this->open_assign_material = false;
        }
    }
/*------------ANULAR MATERIAL ASIGNADO-------------------------------------*/
    public function anularAsignacionMaterial($id){
        /*------------Obtener el detalle del material asignado------------*/
        $assigned_material = OperatorStockDetail::find($id);
        /*--------------Obtener el dealle de la solicitud de pedido----------*/
        $detalle_pedido = OrderRequestDetail::find($assigned_material->order_request_detail_id);
        /*--------------Actualizar la cantidad asignada----------------------*/
        $detalle_pedido->assigned_quantity = $detalle_pedido->assigned_quantity - $assigned_material->quantity;
        if($detalle_pedido->assigned_state =="ASIGNADO"){
            $detalle_pedido->assigned_state = "NO ASIGNADO";
        }
        $detalle_pedido->save();
        /*-------------------Actualizar el estado del material asignado-------*/
        $assigned_material->state = "ANULADO";
        $assigned_material->save();
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
            })->where('implements.location_id',$this->tlocation)->where('order_date_id',$this->tfecha)->where('state','VALIDADO')->get();
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
    /*-----------------------OBTENER PEDIDO DEL IMPLEMENTO--------------------------------------------*/
        $order_request_detail = OrderRequestDetail::where('order_request_id',$this->id_solicitud_pedido)->where('state','VALIDADO')->where('assigned_state','NO ASIGNADO')->get();
    /*-----------------------OBTENER ACUMULADO DE MATERIALES ASIGNADOS--------------------------------*/
    if($this->id_solicitud_pedido > 0){
        $operator_stock = OperatorStockDetail::join('order_request_details',function($join){
                $join->on('order_request_details.id','=','operator_stock_details.order_request_detail_id');
            })->join('order_requests',function($join){
                $join->on('order_requests.id','=','order_request_details.order_request_id');
            })->where('order_requests.id','=',$this->id_solicitud_pedido)->where('operator_stock_details.state','CONFIRMADO')->select('operator_stock_details.*')->get();
    }else{
        $operator_stock = NULL;
    }
    /*----------------------DATOS DEL RENDERIZADOS---------------------------------------------------------*/
        return view('livewire.assign-materials-operator', compact('zones', 'sedes', 'locations','order_dates','users','implements','order_request_detail','operator_stock'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
