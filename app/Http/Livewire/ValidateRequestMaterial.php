<?php

namespace App\Http\Livewire;

use App\Models\Brand;
use App\Models\CecoAllocationAmount;
use App\Models\Implement;
use App\Models\Item;
use App\Models\Location;
use App\Models\MeasurementUnit;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Carbon\Carbon;
use Illuminate\Validation\Rule;
use phpDocumentor\Reflection\Types\This;

class ValidateRequestMaterial extends Component
{
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
    public $idMaterial = 0;
    public $material = "";
    public $cantidad = 0;
    public $cantidad_pedida = 0;
    public $precio = 0;
    public $precioTotal = 0;
    public $observation = "";
    public $measurement_unit = "";
/*------------------------Datos del pedido en curso----------------------*/
    public $idFechaPedido = 0;
    public $fecha_pedido = "";
    public $fecha_pedido_llegada;
/*--------------------Datos del operador-------------*/
    public $idOperador = 0;
    public $operador = "";
/*-----------------Datos del implemento----------------*/
    public $idImplemento = 0;
    public $implemento = "";
/*---------------Id del pedido (Order Request)-------------------------*/
    public $idSolicitudPedido = 0;
/*------------------Datos para los materiales nuevos --------------------*/
    /*----------Estado del modal----------------*/
    public $open_validate_new_material = false;
    public $idMaterialNuevo = 0;
    /*----------Cantidad de materiales nuevos----*/
    public $cantidad_materiales_nuevos = 0;
    /*--------------Estado del modal del detalle de material nuevo-----*/
    public $open_detail_new_material = false;
    /*-------------Datos del material nuevo--------------*/
    public $material_nuevo_nombre = "";
    public $material_nuevo_marca = "";
    public $material_nuevo_cantidad = 0;
    public $material_nuevo_unidad_medida = "";
    public $material_nuevo_ficha_tecnica = "";
    public $material_nuevo_imagen = "";
    /*------------Datos para crear el material nuevo------------*/
    public $create_material_sku = "";
    public $create_material_item = "";
    public $create_material_brand = 0;
    public $create_material_type = "";
    public $create_material_measurement_unit = 0;
    public $create_material_estimated_price = 0;
    public $create_material_quantity = 0;
    /*--------------Crear Nueva Marca---------------*/
    public $open_add_new_brand = false;
    public $create_new_brand = "";

/*--------------Filtros para encontrar los usuarios que tienen pedidos sin validar-------*/
    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;
/*--------------Array para almacenar a los usuarios que tienen pedidos sin validar------------------*/
    public $incluidos = [];
/*-----------------------LISTENERS, RULES AND MESSAGES----------------------------------------------------*/
    protected $listeners = ['reinsertarRechazado','validarSolicitudPedido','rechazarMaterialNuevo'];

    protected function rules(){
        switch ($this->validacion) {
            case 'MATERIAL':
                return [
                    'cantidad' => ['required','numeric','lte:cantidad_pedida','min:0'],
                    'precio' => ['required','numeric','min:0.01'],
                    'observation' => 'required'
                ];
                break;
            case 'NUEVO':
                return [
                    'create_material_sku' => ['required','numeric','unique:items,sku'],
                    'create_material_item' => ['required','unique:items,item'],
                    'create_material_brand' => ['required','exists:brands,id'],
                    'create_material_type' => ['required',Rule::in(['FUNGIBLE','HERRAMIENTA'])],
                    'create_material_measurement_unit' => ['required','exists:measurement_units,id'],
                    'create_material_estimated_price' => ['required','numeric','min:0.01'],
                    'create_material_quantity' => ['required','numeric','lte:material_nuevo_cantidad','min:1']
                ];
                break;
            case 'MARCA':
                return [
                    'create_new_brand' => ['required','unique:brands,brand']
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
            'observation.required' => 'La observation es requerida',
            'monto_usado.min' => 'Faltan validar materiales',
            'create_new_brand.required' => 'Ingrese le nombre de la marca',
            'create_new_brand.unique' => 'La marca ya existe',
            'create_material_sku.required' => 'El sku es requerido',
            'create_material_sku.numeric' => 'Debe ser un número',
            'create_material_sku.unique' => 'El sku le pertence a otro item',
            'create_material_item.required' => 'Ingrese el nombre del item',
            'create_material_item.unique' => 'El item ya existe',
            'create_material_brand.required' => 'La marca es requerida',
            'create_material_brand.exists' => 'La marca no existe, agreguela',
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
    public function updatedTzone(){
        $this->resetExcept('tzone');
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->resetExcept(['tzone','tsede']);
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->resetExcept(['tzone','tsede','tlocation']);
        $this->incluidos = [];
    }
    public function updatedOpenValidateResquest(){
        if(!$this->open_validate_resquest){
            $this->resetExcept(['tzone','tsede','tlocation','open_validate_resquest']);
        }
    }
    public function updatedOpenValidateMaterial(){
        if(!$this->open_validate_material){
            $this->reset(['idMaterial','material','cantidad','precio','precioTotal','observation']);
            $this->resetValidation();
        }
    }
    public function updatedIdImplemento(){
        $order_request = OrderRequest::where('implement_id',$this->idImplemento)->where('state',"CERRADO")->first();
        if($order_request != null){
            $this->idSolicitudPedido = $order_request->id;
            $this->cantidad_materiales_nuevos = OrderRequestNewItem::where('order_request_id',$this->idSolicitudPedido)->where('state','PENDIENTE')->count();
        }else{
            $this->idSolicitudPedido = 0;
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
        $this->cantidad_materiales_nuevos = OrderRequestNewItem::where('order_request_id',$this->idSolicitudPedido)->where('state','PENDIENTE')->count();
    }
    public function updatedOpenDetailNewMaterial(){
        if(!$this->open_detail_new_material){
            $this->reset(['idMaterialNuevo','material_nuevo_nombre','material_nuevo_marca','material_nuevo_cantidad','material_nuevo_unidad_medida','material_nuevo_ficha_tecnica','material_nuevo_imagen','create_material_sku','create_material_item','create_material_brand','create_material_type','create_material_measurement_unit','create_material_estimated_price','create_material_quantity']);
            $this->resetValidation();
        }
    }
    public function updatedOpenAddNewBrand(){
        if(!$this->open_add_new_brand){
            $this->reset('create_new_brand');
        }
    }
/*----------------VALIDAR O RECHAZAR MATERIALES---------------------------------------------*/
    /*----------Mostrar modal------------------------------------------*/
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
        if($this->precioTotal > 0 && $this->cantidad > 0){
            $this->precioTotal = floatval($this->precio) * floatval($this->cantidad);
        }else{
            $this->precioTotal = 0;
        }
        $this->observation = $material->observation;
        $this->estado_solicitud = $material->state;
        $this->measurement_unit = $material->item->measurementUnit->abbreviation;
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
        $this->validacion = "MATERIAL";
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
        $this->validacion = "";
    }
    /*-----------------Reinsertar Rechazados --------------------------------------------------------*/
    public function reinsertarRechazado($id){
        $material = OrderRequestDetail::find($id);
        $material->state = "PENDIENTE";
        $material->save();
    }
/*-------------------------VALIDAR SOLICITUD DEL OPERADOR--------------------------------------------------*/
    /*-----------Mostrar modal de solicitudes-----------------------------*/
    public function mostrarImplementos($id,$name,$lastname){
        $this->idOperador = $id;
        $this->operador = $name.' '.$lastname;
        $this->open_validate_resquest = true;
    }
    public function validarSolicitudPedido(){
        /*---------------------Verificar si no existe ningún material existente y nuevo pendiente en validar y-----*/
        if(OrderRequestDetail::where('order_request_id',$this->idSolicitudPedido)->where('quantity','>',0)->where('state','PENDIENTE')->doesntExist() &&
        OrderRequestNewItem::where('order_request_id',$this->idSolicitudPedido)->where('state','PENDIENTE')->doesntExist()){
            $order_request = OrderRequest::find($this->idSolicitudPedido);
            $order_request->state = "VALIDADO";
            $order_request->save();
            $this->resetExcept(['tzone','tsede','tlocation']);
            $this->render();
        }
    }
    public function rechazarSolcitudPedido(){
        $order_request = OrderRequest::find($this->idSolicitudPedido);
        $order_request->state = "RECHAZADO";
        $order_request->save();
        $this->resetExcept(['tzone','tsede','tlocation']);
        $this->render();
    }
/*--------------------------FORMATEAR MARCA-----------------------------------------------------------------*/
    function eliminar_acentos($cadena){

        //Reemplazamos la A y a
        $cadena = str_replace(
        array('Á', 'À', 'Â', 'Ä', 'á', 'à', 'ä', 'â', 'ª'),
        array('A', 'A', 'A', 'A', 'a', 'a', 'a', 'a', 'a'),
        $cadena
        );

        //Reemplazamos la E y e
        $cadena = str_replace(
        array('É', 'È', 'Ê', 'Ë', 'é', 'è', 'ë', 'ê'),
        array('E', 'E', 'E', 'E', 'e', 'e', 'e', 'e'),
        $cadena );

        //Reemplazamos la I y i
        $cadena = str_replace(
        array('Í', 'Ì', 'Ï', 'Î', 'í', 'ì', 'ï', 'î'),
        array('I', 'I', 'I', 'I', 'i', 'i', 'i', 'i'),
        $cadena );

        //Reemplazamos la O y o
        $cadena = str_replace(
        array('Ó', 'Ò', 'Ö', 'Ô', 'ó', 'ò', 'ö', 'ô'),
        array('O', 'O', 'O', 'O', 'o', 'o', 'o', 'o'),
        $cadena );

        //Reemplazamos la U y u
        $cadena = str_replace(
        array('Ú', 'Ù', 'Û', 'Ü', 'ú', 'ù', 'ü', 'û'),
        array('U', 'U', 'U', 'U', 'u', 'u', 'u', 'u'),
        $cadena );

        //Reemplazamos la N, n, C y c
        $cadena = str_replace(
        array('Ñ', 'ñ', 'Ç', 'ç'),
        array('N', 'n', 'C', 'c'),
        $cadena
        );

        return $cadena;
    }
/*---------------------------MATERIALES NUEVOS--------------------------------------------------------------*/
    public function addNewBrand(){
        $this->validacion = "MARCA";
        $this->validate();
        $marca_nueva = Brand::create([
            'brand' => strtolower($this->eliminar_acentos($this->create_new_brand))
        ]);
        $this->create_material_brand = $marca_nueva->id;
        $this->open_add_new_brand = false;
        $this->validacion = "";
    }
    public function detalleMaterialNuevo($id){
        $material_nuevo = OrderRequestNewItem::find($id);
        $this->idMaterialNuevo = $id;
        /*-----------Datos para la vista del pedido del operador--------------*/
        $this->material_nuevo_nombre = $material_nuevo->new_item;
        $this->material_nuevo_marca = $material_nuevo->brand;
        $this->material_nuevo_cantidad = $material_nuevo->quantity;
        $this->material_nuevo_unidad_medida = $material_nuevo->measurementUnit->abbreviation;
        $this->material_nuevo_ficha_tecnica = $material_nuevo->datasheet;
        $this->material_nuevo_imagen = $material_nuevo->image;
        /*-----------Datos para guardar el material nuevo-------------------------*/
        $this->create_material_item = $material_nuevo->new_item;
        $marca_formateada = strtolower($this->eliminar_acentos($material_nuevo->brand));
        if(Brand::where('brand','like',$marca_formateada)->exists()){
            $marca_registrada = Brand::where('brand','like',$marca_formateada)->first();
            $this->create_material_brand = $marca_registrada->id;
        }
        $this->create_material_measurement_unit = $material_nuevo->measurement_unit_id;
        $this->create_material_quantity = $material_nuevo->quantity;
        /*------Abrir modal----------------------------------------*/
        $this->open_detail_new_material = true;
        $this->validacion = "";
    }
    public function agregarMaterialNuevo(){
        $this->validacion = 'NUEVO';
        $this->validate();
        /*----------------Crear el nuevo item---------------------------------*/
        $nuevo_item = Item::create([
            'sku' => $this->create_material_sku,
            'item' => strtolower($this->eliminar_acentos($this->create_material_item)),
            'brand_id' => $this->create_material_brand,
            'measurement_unit_id' => $this->create_material_measurement_unit,
            'estimated_price' => $this->create_material_estimated_price,
            'type' => $this->create_material_type,
        ]);/*-----------------Crear espejo para verificar si se aceptó o modificó----------*/
        if($this->material_nuevo_cantidad == $this->create_material_quantity){
            $estado_material_nuevo = "ACEPTADO";
        }else{
            $estado_material_nuevo = "MODIFICADO";
        }
        OrderRequestDetail::create([
            'order_request_id' => $this->idSolicitudPedido,
            'item_id' => $nuevo_item->id,
            'quantity' => $this->material_nuevo_cantidad,
            'estimated_price' => $this->create_material_estimated_price,
            'state' => $estado_material_nuevo,
        ]);
        /*----------------Crear el detalle de solictud como validado--------------------*/
        OrderRequestDetail::create([
            'order_request_id' => $this->idSolicitudPedido,
            'item_id' => $nuevo_item->id,
            'quantity' => $this->create_material_quantity,
            'estimated_price' => $this->create_material_estimated_price,
            'state' => 'VALIDADO',
        ]);
        /*---------Actualizar la solicitud de nuevo material a creado-----------------------*/
        $item_creado = OrderRequestNewItem::find($this->idMaterialNuevo);
        $item_creado->state = 'CREADO';
        $item_creado->item_id = $nuevo_item->id;
        $item_creado->save();
        /*--------Cerrar Modal---------------*/
        $this->open_detail_new_material = false;
    }
    public function rechazarMaterialNuevo(){
        $item_no_creado = OrderRequestNewItem::find($this->idMaterialNuevo);
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
    /*--------------------DATOS PARA EL MODAL DE MATERIALES NUEVOS-----------------------------------------------------------------------------------------------------------------*/
        $order_request_new_materials = OrderRequestNewItem::where('order_request_id',$this->idSolicitudPedido)->where('state','PENDIENTE')->get();
        $measurement_units = MeasurementUnit::all();
        $brands = Brand::all();
    /*-------------------------------RENDERIZAR LA VISTA--------------------------------------------------------------*/
        return view('livewire.validate-request-material', compact('zones', 'sedes', 'locations','users','implements','order_request_detail_operator','order_request_detail_planner','order_request_detail_rechazado','order_request_new_materials','measurement_units','brands'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
