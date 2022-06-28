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

class ValidateRequestMaterial extends Component
{

    public $open_validate_resquest = false;

    public $estado_solicitud = "";

    public $tipo_validacion = "";

    public $monto_usado = 0;
    public $monto_asignado = 0;
    public $monto_real = 0;

    public $open_validate_material = false;
    public $idMaterial = 0;
    public $material = "";
    public $cantidad = 0;
    public $cantidad_pedida = 0;
    public $precio = 0;
    public $precioTotal = 0;
    public $observation = "";

    public $idFechaPedido = 0;
    public $fecha_pedido = "";
    public $fecha_pedido_llegada;

    public $idOperador = 0;
    public $operador = "";

    public $idImplemento = 0;
    public $implemento = "";

    public $idSolicitudPedido = 0;

    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;

    public $incluidos = [];

    protected $listeners = ['reinsertarRechazado','validarSolicitudPedido'];

    protected function rules(){
        if($this->tipo_validacion == "MATERIAL"){
            return [
                'cantidad' => ['required','numeric','lte:cantidad_pedida','min:0'],
                'precio' => ['required','numeric','min:0.01'],
                'observation' => 'required'
            ];
        }
    }

    protected function messages(){
        return [
            'cantidad.required' => 'La cantidad es requerida',
            'cantidad.lte' => 'El operador solo pidió '.$this->cantidad_pedida,
            'cantidad.min' => 'La cantidad no puede ser negativa',
            'precio.required' => 'El precio es requerido',
            'precio.min' => 'La cantidad debe ser mayor que 0',
            'observation.required' => 'La observation es requerida',
            'monto_usado.min' => 'Faltan validar materiales'
        ];
    }
/*----------------Funciones dinámicas------------------------------------------------------*/
    public function updatedTzone(){
        $this->reset('tsede','tlocation','idOperador','operador','idImplemento','idSolicitudPedido','monto_asignado','monto_usado','monto_real');
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->reset('tlocation','idOperador','operador','idImplemento','idSolicitudPedido','monto_asignado','monto_usado','monto_real');
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->reset('idOperador','operador','idImplemento','idSolicitudPedido','monto_asignado','monto_usado','monto_real');
        $this->incluidos = [];
    }
    public function updatedOpenValidateResquest(){
        $this->reset('idOperador','operador','idImplemento','idSolicitudPedido','monto_asignado','monto_usado','monto_real');
    }
    public function updatedOpenValidateMaterial(){
        $this->reset('idMaterial','material','cantidad','precio','precioTotal','observation');
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
            $this->monto_asignado = 0;
            $this->monto_usado = 0;
            $this->monto_real = 0;
        }
    }
    public function updatedCantidad(){
        $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
    }
    public function updatedPrecio(){
        $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
    }
/*----------------Validar o Rechazar Materiales ---------------------------------------------*/
    public function mostrarModalValidarMaterial($id){
        $this->open_validate_material = true;
        $this->idMaterial = $id;
        $material = OrderRequestDetail::find($id);
        $this->material = strtoupper($material->item->item);
        /*--------Obtener cantidad del usuario------------------------------------------------*/
        if($material->state == "VALIDADO"){
            $order_validate = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('item_id',$material->item_id)->orderBy('id','ASC')->first();
            $this->cantidad_pedida = floatval($order_validate->quantity);
        }else{
            $this->cantidad_pedida = floatval($material->quantity);
        }
        /*------------------------------------------------------------------------------------*/
        $this->cantidad = floatval($material->quantity);
        $this->precio = floatval($material->estimated_price);
        $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
        $this->observation = $material->observation;
        $this->estado_solicitud = $material->state;
    }
    /*-------------------Verificar estado del pedido--------------------------------*/
    private function estadoPedido($solicitada,$validada){
        if($solicitada == $validada){
            return "ACEPTADO";
        }else{
            return "MODIFICADO";
        }
    }
    /*---------------------Validar materiales----------------------------------------------*/
    public function validarMaterial(){
        $this->tipo_validacion = "MATERIAL";
        $this->validate();
        $material = OrderRequestDetail::find($this->idMaterial);
        /*-------------PEDIDOS PENDIENTES A VALIDAR--------------------*/
        if($this->estado_solicitud == "PENDIENTE"){
            /*------------Verificar si se validó el pedido ----------------------*/
            if($this->cantidad > 0){
                OrderRequestDetail::create([
                    'order_request_id' => $this->idSolicitudPedido,
                    'item_id' => $material->item_id,
                    'quantity' => $this->cantidad,
                    'estimated_price' => $this->precio,
                    'state' => 'VALIDADO',
                    'observation' => $this->observation,
                ]);
            $material->state = $this->estadoPedido($this->cantidad_pedida,$this->cantidad);
            /*------------Rechazar el pedido---------------------------------------*/
            }else{
                $material->state = 'RECHAZADO';
            }
            $material->observation = $this->observation;
        /*---------------PEDIDOS VALIDADOS-------------------------------------------*/
        }elseif($this->estado_solicitud == "VALIDADO"){
            /*----------Obtener solicitud del Operador---------------------------------------------------*/
            $order_validate = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('item_id',$material->item_id)->orderBy('id','ASC')->first();
            /*----------Editar cantidad --------------------------------------*/
            if($this->cantidad > 0){
                /*------------Editar estados----------------*/
                $material->quantity = $this->cantidad;
                $material->estimated_price = $this->precio;
                $order_validate->state = $this->estadoPedido($this->cantidad_pedida,$this->cantidad);
                $material->observation = $this->observation;
            /*-------------Invalidar solicitud--------------------------------*/
            }else{
                /*-----Obtener orden ya validada------------------------------*/
                $order_validate->state = "PENDIENTE";
            }
            $order_validate->save();
        }
        if($this->estado_solicitud == "PENDIENTE" || $this->estado_solicitud == "VALIDADO"){
            /*-----------Eliminar validación en caso sea 0-------------------------*/
            if($this->estado_solicitud == "VALIDADO" && $this->cantidad <= 0){
                $material->delete();
            /*-----------Validar o editar en caso sea mayor a 0----------------*/
            }else{
                $material->save();
            }
            $this->open_validate_material = false;
            $this->reset('idMaterial','material','cantidad','precio','precioTotal','observation');
        }
    }
    /*-----------------Reinsertar Rechazados --------------------------------------------------------*/
    public function reinsertarRechazado($id){
        $material = OrderRequestDetail::find($id);
        $material->state = "PENDIENTE";
        $material->save();
    }
    /*-------------------------Validar Solicitud de Pedido--------------------------------------------------*/
    public function validarSolicitudPedido(){
        $this->tipo_validacion = "SOLICITUD";
        if(OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('quantity','>',0)->where('state','PENDIENTE')->doesntExist()){

            $this->open_validate_resquest = false;
        }

    }
    public function render()
    {
    /*------------------DATOS PARA LAS SOLICITUDES DE PEDIDO POR USUARIO----------------------------*/
        /*-----------------------Obtener la fecha de pedido--------------------------------*/
        $order_date = OrderDate::where('state','ABIERTO')->first();
        if($order_date != null){
            $this->fecha_pedido = "PEDIDO PARA ".strtoupper(strftime("%A %d de %B de %Y", strtotime($order_date->order_date)));
            $this->fecha_pedido_llegada = $order_date->arrival_date;
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

    /*----------------------DATOS DEL MODAL DE VALIDACIÓN ------------------------------------------*/
        /*--------------------------Mostrar montos del ceco-----------------------------------------------*/
        if($this->idImplemento > 0){
            $implement = Implement::find($this->idImplemento);
            $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;

            /*--------Obtener las fechas de llegada del pedido-------------------------------------*/
            $fecha_llegada1 = Carbon::parse($this->fecha_pedido_llegada);
            $fecha_llegada2 = $fecha_llegada1->addMonth();
            /*---------------------Obtener el monto Asignado para los meses de llegada del pedido-------------*/
            $this->monto_asignado = CecoAllocationAmount::where('ceco_id',$implement->ceco_id)->whereDate('date','>=',$this->fecha_pedido_llegada)->whereDate('date','<=',$fecha_llegada2)->sum('allocation_amount');

            /*-------------------Obtener el monto usado por el ceco en total-------------------------------------------*/
            $this->monto_usado = OrderRequestDetail::join('order_requests', function ($join){
                                                        $join->on('order_requests.id','=','order_request_details.order_request_id');
                                                    })->join('implements', function ($join){
                                                        $join->on('implements.id','=','order_requests.implement_id');
                                                    })->where('implements.ceco_id','=',$implement->ceco_id)
                                                      ->where('order_request_details.state','=','PENDIENTE')
                                                      ->where('order_request_details.quantity','<>',0)
                                                      ->selectRaw('SUM(order_request_details.estimated_price*order_request_details.quantity) AS total')
                                                      ->value('total');

            /*-------------------Obtener el monto real por el ceco en total-------------------------------------------*/
            $this->monto_real = OrderRequestDetail::join('order_requests', function ($join){
                                                        $join->on('order_requests.id','=','order_request_details.order_request_id');
                                                    })->join('implements', function ($join){
                                                        $join->on('implements.id','=','order_requests.implement_id');
                                                    })->where('implements.ceco_id','=',$implement->ceco_id)
                                                      ->where('order_request_details.state','=','VALIDADO')
                                                      ->where('order_request_details.quantity','<>',0)
                                                      ->selectRaw('SUM(order_request_details.estimated_price*order_request_details.quantity) AS total')
                                                      ->value('total');
        }
        /*--------------------------------------Implementos del usuario------------------------------------*/
        $implements = OrderRequest::join('implements', function($join){
            $join->on('implements.id','=','order_requests.implement_id');
        })->join('implement_models', function($join){
            $join->on('implement_models.id','=','implements.implement_model_id');
        })->where('order_requests.user_id',$this->idOperador)->select('implements.*','implement_models.implement_model')->get();

        $order_request_detail_operator = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('quantity','>',0)->where('state','PENDIENTE')->get();

        $order_request_detail_planner = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('quantity','>',0)->where(function ($query){
            $query->where('state','VALIDADO');
        })->get();

        $order_request_detail_rechazado = OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('quantity','>',0)->where('state','RECHAZADO')->get();

        return view('livewire.validate-request-material', compact('zones', 'sedes', 'locations','users','implements','order_request_detail_operator','order_request_detail_planner','order_request_detail_rechazado'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
