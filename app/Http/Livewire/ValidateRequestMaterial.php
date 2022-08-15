<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\Item;
use App\Models\Location;
use App\Models\MeasurementUnit;
use App\Models\OperatorStock;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use App\Models\Sede;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use Livewire\WithPagination;

class ValidateRequestMaterial extends Component
{
    use WithPagination;
/*---------------------------VARIABLES PÚBLICAS-------------------*/
    public $validacion = "";
/*------------------------Modal general--------------------------*/
    public $open_validate_resquest = false;
/*------Estado de la solicitud (PENDIENTE,CERRADO,VALIDADO,RECHAZADO)---------*/
    public $estado_solicitud = "";
/*-----------Montos disponibles y usados---------------------------*/
    public $monto_usado = 0;
    public $monto_asignado = 0;
    public $monto_real = 0;
/*--------------------Datos para el modal de materiales------------*/
    public $open_validate_material = false;
    public $id_material = 0;
    public $material = "";
    public $cantidad = 0;
    public $cantidad_pedida = 0;
    public $precio = 0;
    public $precioTotal = 0;
    public $measurement_unit = "";
    public $ordered_quantity = 0;
    public $stock = 0;
/*------------------------Datos del pedido en curso----------------------*/
    public $fecha_pedido = "";
    public $fecha_pedido_llegada;
/*--------------------Datos del operador-------------*/
        public $id_operador = 0;
        public $operador = "";
/*-----------------Datos del implemento----------------*/
        public $id_implemento = 0;
        public $implemento = "";
/*---------------Id del pedido (Order Request)-------------------------*/
        public $id_solicitud_pedido = 0;
/*------------------Datos para los materiales nuevos --------------------*/
    /*----------Estado del modal----------------*/
        public $open_validate_new_material = false;
        public $id_material_nuevo = 0;
    /*----------Cantidad de materiales nuevos----*/
        public $cantidad_materiales_nuevos = 0;
    /*--------------Estado del modal del detalle de material nuevo-----*/
        public $open_detail_new_material = false;
    /*-------------Datos del material nuevo--------------*/
        public $material_nuevo_nombre = "";
        public $material_nuevo_cantidad = 0;
        public $material_nuevo_unidad_medida = "";
        public $material_nuevo_ficha_tecnica = "";
        public $material_nuevo_imagen = "";
    /*------------Datos para crear el material nuevo------------*/
        public $create_material_sku = "";
        public $create_material_item = "";
        public $create_material_type = "";
        public $create_material_measurement_unit = 0;
        public $create_material_estimated_price = 0;
        public $create_material_quantity = 0;

/*--------------Filtros para encontrar los usuarios que tienen pedidos sin validar-------*/
    public $tsede = 0;
    public $tlocation = 0;
/*--------------Array para almacenar a los usuarios que tienen pedidos sin validar------------------*/
    public $incluidos = [];
/*-----------------------LISTENERS, RULES AND MESSAGES----------------------------------------------------*/
    protected $listeners = ['reinsertarRechazado','validarSolicitudPedido','rechazarMaterialNuevo','rechazarSolicitudPedido'];

    protected function rules(){
        switch ($this->validacion) {
            case 'MATERIAL':
                return [
                    'cantidad' => ['required','numeric','lte:cantidad_pedida','min:0'],
                    'precio' => ['required','numeric','min:0.01'],
                ];
                break;
            case 'NUEVO':
                return [
                    'create_material_sku' => ['required','numeric','unique:items,sku'],
                    'create_material_item' => ['required','unique:items,item'],
                    'create_material_type' => ['required',Rule::in(['FUNGIBLE','HERRAMIENTA'])],
                    'create_material_measurement_unit' => ['required','exists:measurement_units,id'],
                    'create_material_estimated_price' => ['required','numeric','min:0.01'],
                    'create_material_quantity' => ['required','numeric','lte:material_nuevo_cantidad','min:1']
                ];
                break;
            default:
                return [

                ];
                break;
        }
    }

    protected function messages(){
        return [
            'cantidad.required' => 'La cantidad es requerida',
            'cantidad.lte' => 'El operador solo pidió '.$this->cantidad_pedida,
            'cantidad.min' => 'La cantidad no puede ser negativa',
            'precio.required' => 'El precio es requerido',
            'precio.min' => 'La cantidad debe ser mayor que 0',
            'monto_usado.min' => 'Faltan validar materiales',
            'create_material_sku.required' => 'El sku es requerido',
            'create_material_sku.numeric' => 'Debe ser un número',
            'create_material_sku.unique' => 'El sku le pertence a otro item',
            'create_material_item.required' => 'Ingrese el nombre del item',
            'create_material_item.unique' => 'El item ya existe',
            'create_material_type.required' => 'La tipo es requerido',
            'create_material_type.in' => 'El tipo no existe',
            'create_material_measurement_unit.exists' => 'La unidad de medida no existe',
            'create_material_measurement_unit.required' => 'La unidad de medida es requerida',
            'create_material_estimated_price.required' => 'El precio es requerido',
            'create_material_estimated_price.numeric' => 'El precio es debe ser un número',
            'create_material_estimated_price.min' => 'Nada es gratis en la vida',
            'create_material_quantity.required' => 'Ingresa la cantidad',
            'create_material_quantity.numeric' => 'Debe de ser un número',
            'create_material_quantity.min' => 'Si no vas a pedir, rechazalo nomás',
            'create_material_quantity.lte' => 'El operador solo pidió '.$this->material_nuevo_cantidad
        ];
    }
/*----------------FUNCIONES DIŃAMICAS (UPDATED VARIABLES)------------------------------------------------------*/
    public function updatedTsede(){
        $this->resetExcept(['tsede']);
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->resetExcept(['tsede','tlocation']);
        $this->incluidos = [];
    }
    public function updatedOpenValidateResquest(){
        if(!$this->open_validate_resquest){
            $this->resetExcept(['tsede','tlocation','open_validate_resquest']);
        }
    }
    public function updatedOpenValidateMaterial(){
        if(!$this->open_validate_material){
            $this->reset(['id_material','material','cantidad','precio','precioTotal']);
            $this->resetValidation();
        }
    }
    public function updatedIdImplemento(){
        if(OrderRequest::where('implement_id',$this->id_implemento)->where('state',"CERRADO")->exists()){
            $order_request = OrderRequest::where('implement_id',$this->id_implemento)->where('state',"CERRADO")->first();
            $this->id_solicitud_pedido = $order_request->id;
            $this->cantidad_materiales_nuevos = OrderRequestNewItem::where('order_request_id',$this->id_solicitud_pedido)->where('state','PENDIENTE')->count();
        }else{
            $this->id_solicitud_pedido = 0;
            $this->monto_asignado = 0;
            $this->monto_usado = 0;
            $this->monto_real = 0;
            $this->cantidad_materiales_nuevos = 0;
        }
    }
    public function updatedCantidad(){
        if($this->cantidad > 0){
            $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
        }else{
            $this->precioTotal = 0;
        }
    }
    public function updatedPrecio(){
        if($this->cantidad > 0){
            $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
        }else{
            $this->precioTotal = 0;
        }
    }
    public function updatedOpenValidateNewMaterial(){
        $this->cantidad_materiales_nuevos = OrderRequestNewItem::where('order_request_id',$this->id_solicitud_pedido)->where('state','PENDIENTE')->count();
    }
    public function updatedOpenDetailNewMaterial(){
        if(!$this->open_detail_new_material){
            $this->reset(['id_material_nuevo','material_nuevo_nombre','material_nuevo_cantidad','material_nuevo_unidad_medida','material_nuevo_ficha_tecnica','material_nuevo_imagen','create_material_sku','create_material_item','create_material_type','create_material_measurement_unit','create_material_estimated_price','create_material_quantity']);
            $this->resetValidation();
        }
    }
/*----------------VALIDAR O RECHAZAR MATERIALES---------------------------------------------*/
    /*----------Mostrar modal------------------------------------------*/
        /**
         * Obtener los datos del detalle de la solicitud de pedido y abrir su modal.
         * 
         * @param int $id ID del detalle de la solicitud de pedido
         */
        public function mostrarModalValidarMaterial($id){
            $this->id_material = $id;
            $material = OrderRequestDetail::find($id);
            $this->material = strtoupper($material->item->item);
            $this->measurement_unit = $material->item->measurementUnit->abbreviation;
            /*--------Obtener cantidad del usuario------------------------------------------------*/
                if($material->state == "VALIDADO"){
                    $order_validate = OrderRequestDetail::where('order_request_id',$this->id_solicitud_pedido)->where('item_id',$material->item_id)->orderBy('id','ASC')->first();
                    $this->cantidad_pedida = floatval($order_validate->quantity);
                }else{
                    $this->cantidad_pedida = floatval($material->quantity);
                }
            /*------------------------------------------------------------------------------------*/
                if(OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$material->item_id)->exists()){
                    $operator_stock = OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$material->item_id)->first();
                    $this->ordered_quantity = floatval($operator_stock->ordered_quantity - $operator_stock->used_quantity);
                }else{
                    $this->ordered_quantity = 0;
                }

                $stock = GeneralStock::where('item_id',$material->item_id)->where('sede_id',Auth::user()->location->sede_id);

                if($stock->exists()){
                    $stock_del_item = $stock->select('general_stocks.quantity')->first();
                    $this->stock = floatval($stock_del_item->quantity);
                }else{
                    $this->stock = 0;
                }
            /*------------------------------------------------------------------------------------*/
                $this->cantidad = floatval($material->quantity);
                $this->precio = floatval(Item::find($material->item_id)->estimated_price);
                if($this->precioTotal > 0 && $this->cantidad > 0){
                    $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
                }else{
                    $this->precioTotal = 0;
                }
                $this->estado_solicitud = $material->state;
                $this->measurement_unit = $material->item->measurementUnit->abbreviation;
                $this->open_validate_material = true;
        }
    /*-------------------Verificar estado del pedido--------------------------------*/
        /**
         * Verificar si el estado del pedido fue aceptado en su totalidad o fue modificado
         * 
         * @param float $solicitada Cantidad solicitada por el operador
         * @param float $validada Cantidad validada por el planner
         */
        private function estadoPedido($solicitada,$validada){
            if($solicitada == $validada){
                return "ACEPTADO";
            }else{
                return "MODIFICADO";
            }
        }
    /*---------------------Validar materiales----------------------------------------------*/
        /**
         * Validar el material y la cantidad pedida
         */
        public function validarMaterial(){
            $this->validacion = "MATERIAL";
            $this->validate();
            $material = OrderRequestDetail::find($this->id_material);
            $item = Item::find($material->item_id);
            /*-------------PEDIDOS PENDIENTES A VALIDAR--------------------*/
            if($this->estado_solicitud == "PENDIENTE"){
                /*------------Verificar si se validó el pedido ----------------------*/
                if($this->cantidad > 0){
                    OrderRequestDetail::create([
                        'order_request_id' => $this->id_solicitud_pedido,
                        'item_id' => $material->item_id,
                        'quantity' => $this->cantidad,
                        'quantity_to_use' => $this->cantidad,
                        'estimated_price' => $this->precio,
                        'state' => 'VALIDADO',
                    ]);
                $material->state = $this->estadoPedido($this->cantidad_pedida,$this->cantidad);
                $item->estimated_price = $this->precio;
                /*------------Rechazar el pedido---------------------------------------*/
                }else{
                    $material->state = 'RECHAZADO';
                }
            /*---------------PEDIDOS VALIDADOS-------------------------------------------*/
            }elseif($this->estado_solicitud == "VALIDADO"){
                /*----------Obtener solicitud del Operador---------------------------------------------------*/
                $order_validate = OrderRequestDetail::where('order_request_id',$this->id_solicitud_pedido)->where('item_id',$material->item_id)->orderBy('id','ASC')->first();
                /*----------Editar cantidad --------------------------------------*/
                if($this->cantidad > 0){
                    /*------------Editar estados----------------*/
                    $material->quantity = $this->cantidad;
                    $material->estimated_price = $this->precio;
                    $order_validate->state = $this->estadoPedido($this->cantidad_pedida,$this->cantidad);
                    $item->estimated_price = $this->precio;
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
                    $item->save();
                    $material->save();
                }
                $this->open_validate_material = false;
                $this->reset('id_material','material','cantidad','cantidad_pedida','precio','precioTotal');
            }
            $this->validacion = "";
        }
    /*-----------------Reinsertar Rechazados --------------------------------------------------------*/
        /**
         * Reinsertar el material rechazado
         */
        public function reinsertarRechazado($id){
            $material = OrderRequestDetail::find($id);
            $material->state = "PENDIENTE";
            $material->save();
        }
/*-------------------------VALIDAR SOLICITUD DEL OPERADOR--------------------------------------------------*/
    /*-----------Mostrar modal de solicitudes-----------------------------*/
    /**
     * Obtener los datos del operador y abrir el modal para validar la solicitud de pedido
     * 
     * @param int $id ID del operador
     * @param string $name Nombre del operador
     * @param string $lastname Apellido del operador
     */
    public function mostrarPedidos($id,$name,$lastname){
        $this->id_operador = $id;
        $this->operador = $name.' '.$lastname;
        $this->open_validate_resquest = true;
    }

    /**
     * Validar la solicitud de pedido
     */
    public function validarSolicitudPedido(){
        /*---------------------Verificar si no existe ningún material existente y nuevo pendiente en validar-----*/
        if(OrderRequestDetail::where('order_request_id',$this->id_solicitud_pedido)->where('quantity','>',0)->where('state','PENDIENTE')->doesntExist() &&
        OrderRequestNewItem::where('order_request_id',$this->id_solicitud_pedido)->where('state','PENDIENTE')->doesntExist()){
            $order_request = OrderRequest::find($this->id_solicitud_pedido);
            $order_request->state = "VALIDADO";
            $order_request->validated_by = Auth::user()->id;
            $order_request->save();
            $this->resetExcept(['tsede','tlocation']);
            $this->render();
        }
    }
    /**
     * Rechazar la solicitud de pedido
     */
    public function rechazarSolicitudPedido(){
        $order_request = OrderRequest::find($this->id_solicitud_pedido);
        $order_request->state = "RECHAZADO";
        $order_request->save();
        $this->resetExcept(['tsede','tlocation']);
        $this->render();
    }
/*---------------------------MATERIALES NUEVOS--------------------------------------------------------------*/
    /**
     * Obtener los datos del material nuevo solicitado y abrir el modal
     * 
     * @param int $id ID del material nuevo solicitado
     */
    public function detalleMaterialNuevo($id){
        $material_nuevo = OrderRequestNewItem::find($id);
        $this->id_material_nuevo = $id;
        /*-----------Datos para la vista del pedido del operador--------------*/
            $this->material_nuevo_nombre = $material_nuevo->new_item;
            $this->material_nuevo_cantidad = $material_nuevo->quantity;
            $this->material_nuevo_unidad_medida = $material_nuevo->measurementUnit->abbreviation;
            $this->material_nuevo_ficha_tecnica = $material_nuevo->datasheet;
            $this->material_nuevo_imagen = $material_nuevo->image;
        /*-----------Datos para guardar el material nuevo-------------------------*/
            $this->create_material_item = $material_nuevo->new_item;
            $this->create_material_measurement_unit = $material_nuevo->measurement_unit_id;
            $this->create_material_quantity = $material_nuevo->quantity;
        /*------Abrir modal----------------------------------------*/
            $this->open_detail_new_material = true;
            $this->validacion = "";
    }
    /*---------------------Agregar Material nuevo-------------------------------------*/
        /**
         * Agregar el material nuevo a la solicitud de pedido
         */
        public function agregarMaterialNuevo(){
            $this->validacion = 'NUEVO';
            $this->validate();
        /*----------------Crear el nuevo item---------------------------------*/
            $nuevo_item = Item::create([
                'sku' => $this->create_material_sku,
                'item' => strtolower($this->create_material_item),
                'measurement_unit_id' => $this->create_material_measurement_unit,
                'estimated_price' => $this->create_material_estimated_price,
                'type' => $this->create_material_type,
            ]);
        /*-----------------Crear espejo para verificar si se aceptó o modificó----------*/
            if($this->material_nuevo_cantidad == $this->create_material_quantity){
                $estado_material_nuevo = "ACEPTADO";
            }else{
                $estado_material_nuevo = "MODIFICADO";
            }
            OrderRequestDetail::create([
                'order_request_id' => $this->id_solicitud_pedido,
                'item_id' => $nuevo_item->id,
                'quantity' => $this->material_nuevo_cantidad,
                'estimated_price' => $this->create_material_estimated_price,
                'state' => $estado_material_nuevo,
            ]);
        /*----------------Crear el detalle de solictud como validado--------------------*/
            OrderRequestDetail::create([
                'order_request_id' => $this->id_solicitud_pedido,
                'item_id' => $nuevo_item->id,
                'quantity' => $this->create_material_quantity,
                'estimated_price' => $this->create_material_estimated_price,
                'state' => 'VALIDADO',
            ]);
        /*---------Actualizar la solicitud de nuevo material a creado-----------------------*/
            $item_creado = OrderRequestNewItem::find($this->id_material_nuevo);
            $item_creado->state = 'CREADO';
            $item_creado->item_id = $nuevo_item->id;
            $item_creado->save();
        /*--------Cerrar Modal---------------*/
            $this->open_detail_new_material = false;
        }
    /*--------RECHAZAR MATERIAL NUEVO-----------------------*/
        /**
         * Rechazar el material nuevo solicitado
         */
        public function rechazarMaterialNuevo(){
            $item_no_creado = OrderRequestNewItem::find($this->id_material_nuevo);
            $item_no_creado->state = 'RECHAZADO';
            $item_no_creado->save();
            /*--------Cerrar Modal---------------*/
            $this->open_detail_new_material = false;
        }
/*----------------------RENDER--------------------------------------------*/
    public function render()
    {
    /*------------------DATOS PARA LAS SOLICITUDES DE PEDIDO POR USUARIO----------------------------*/
        /*-----------------------Obtener la fecha de pedido--------------------------------*/

            if($order_date = OrderDate::where('state','ABIERTO')->exists()){
                $order_date = OrderDate::where('state','ABIERTO')->first();
                $this->fecha_pedido = strtoupper(strftime("%A %d de %B de %Y", strtotime($order_date->order_date)));
                $this->fecha_pedido_llegada = $order_date->arrival_date;


            /*---------------------Mostrar sedes y ubicaciones--------------------*/
                $sedes = Sede::where('zone_id',Auth::user()->location->sede->zone->id)->select('id','sede')->get();

                $locations = Location::where('sede_id',$this->tsede)->select('id','location')->get();
            }else{
                $this->fecha_pedido = "";
                $sedes = NULL;
                $locations = NULL;
            }


        /*------Obtener las solicitudes de pedido por ubicación y que estén cerradas----------------------------*/
        if($this->tlocation > 0){
            $order_requests = OrderRequest::join('implements',function ($join){
                $join->on('order_requests.implement_id','=','implements.id');
            })->where('implements.location_id',$this->tlocation)->where('state','CERRADO')->get();
        }
        /*---------------------------Obtener los usuarios que tienen una solicitud cerrada----------*/
        if(isset($order_requests)){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->user_id);
            }
        }
        /*--------------------Mostrar a los usuarios que tienen solicitudes de pedido cerrada----------------------*/
        $users = DB::table('users')->whereIn('id',$this->incluidos)->select('id','name','lastname')->get();

    /*----------------------DATOS DEL MODAL DE VALIDACIÓN ------------------------------------------*/
        /*--------------------------Mostrar montos del ceco-----------------------------------------------*/
        if($this->id_implemento > 0){
            $implement = Implement::find($this->id_implemento);
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
        })->where('order_requests.user_id',$this->id_operador)->select('implements.*','implement_models.implement_model')->get();

        $order_request_detail_operator = $orderRequestDetails = DB::table('lista_de_materiales_pedidos')->where('order_request_id',$this->id_solicitud_pedido)->where('state','PENDIENTE')->where('quantity','>',0)->select('id','sku','item','type','quantity','abbreviation','ordered_quantity','used_quantity','stock')->get();

        $order_request_detail_planner = DB::table('lista_de_materiales_pedidos')->where('order_request_id',$this->id_solicitud_pedido)->where('state','VALIDADO')->select('id','sku','item','type','quantity','abbreviation','ordered_quantity','used_quantity','stock')->get();

        $order_request_detail_rechazado = DB::table('lista_de_materiales_pedidos')->where('order_request_id',$this->id_solicitud_pedido)->where('state','RECHAZADO')->select('id','sku','item','type','quantity','abbreviation','ordered_quantity','used_quantity','stock')->get();
    /*--------------------DATOS PARA EL MODAL DE MATERIALES NUEVOS-----------------------------------------------------------------------------------------------------------------*/
        $order_request_new_materials = OrderRequestNewItem::where('order_request_id',$this->id_solicitud_pedido)->where('state','PENDIENTE')->get();
        $measurement_units = MeasurementUnit::all();
    /*-------------------------------RENDERIZAR LA VISTA--------------------------------------------------------------*/
        return view('livewire.validate-request-material', compact('sedes', 'locations','users','implements','order_request_detail_operator','order_request_detail_planner','order_request_detail_rechazado','order_request_new_materials','measurement_units'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
