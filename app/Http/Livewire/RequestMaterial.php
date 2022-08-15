<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\MeasurementUnit;
use App\Models\OperatorStock;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\WithPagination;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;

class RequestMaterial extends Component
{
    use WithPagination;
    use WithFileUploads;

    public $excluidos = [];
    public $monto_asignado = 0;
    public $monto_usado = 0;

    public $fecha_pedido_id = 0;
    public $fecha_pedido = "";
    public $fecha_pedido_abierto;
    public $fecha_pedido_cierre;
    public $fecha_pedido_llegada;

    public $id_implemento = 0;
    public $implemento;
    public $id_request = 0;

    public $open_edit = false;
    public $material_edit = 0;
    public $material_edit_name = '';
    public $quantity_edit;
    public $measurement_unit_edit;
    public $ordered_quantity = 0;
    public $stock = 0;

    public $open_edit_new = false;
    public $material_new_edit;
    public $material_new_edit_name ;
    public $material_new_edit_quantity;
    public $material_new_edit_measurement_unit;
    public $material_new_edit_datasheet;
    public $material_new_edit_image;
    public $material_new_edit_image_old;

    public $iteration = 0;

    protected $listeners = ['render','cerrarPedido'];

    protected function rules(){
        if($this->open_edit_new){
            if($this->material_new_edit_image == ""){
                return [
                    'material_new_edit_name' => 'required',
                    'material_new_edit_quantity' => 'required|gt:0',
                    'material_new_edit_measurement_unit' => 'required|exists:measurement_units,id',
                    'material_new_edit_datasheet' => 'required',
                ];
            }else{
                return [
                    'material_new_edit_name' => 'required',
                    'material_new_edit_quantity' => 'required|gt:0',
                    'material_new_edit_measurement_unit' => 'required|exists:measurement_units,id',
                    'material_new_edit_datasheet' => 'required',
                    'material_new_edit_image' => 'image',
                ];
            }

        }else{
            return [
                'quantity_edit' => 'required|gte:0',
            ];
        }

    }

    protected $messages = [
        'material_new_edit_name.required' => 'Ingrese el nombre',
        'material_new_edit_quantity.required' => 'Ingrese la cantidad',
        'material_new_edit_quantity.gt' => 'Debe ser mayor de 0',
        'material_new_edit_measurement_unit.required' => 'Seleccione una unidad de medida',
        'material_new_edit_measurement_unit.exists' => 'La unidad de medida no existe',
        'material_new_edit_datasheet.required' => 'Ingrese la ficha técnica',
        'material_new_edit_image.image' => 'El archivo debe de ser una imagen',
        'quantity_edit.required' => 'Ingrese la cantidad',
        'quantity_edit.gte' => 'Debe ser 0 para rechazar o mayor'
    ];

    /**
     * Validar formatos de la imagen para pre-visualizar
     */
    public function updatedMaterialNewEditImage(){
        $nombre_de_imagen = $this->material_new_edit_image->getClientOriginalName();
        if(!preg_match('/.jpg$/i',$nombre_de_imagen)
        && !preg_match('/.jpeg$/i',$nombre_de_imagen)
        && !preg_match('/.png$/i',$nombre_de_imagen)
        && !preg_match('/.gif$/i',$nombre_de_imagen)
        && !preg_match('/.jfif$/i',$nombre_de_imagen)
        && !preg_match('/.svg$/i',$nombre_de_imagen)){
            $this->material_new_edit_image = "";
            $this->iteration++;
        }
        $this->resetValidation('material_new_edit_image');
    }

    public function updatedOpenEditNew(){
        $this->reset('material_new_edit_name','material_new_edit_quantity','material_new_edit_measurement_unit','material_new_edit_datasheet','material_new_edit_image','material_new_edit_image_old');
        $this->iteration++;
    }
    /**
     * Obtener el id del item nuevo a solcitado por el operario
     * 
     * @param int $id ID del item nuevo
     */
    public function seleccionar($id){
        $this->material_new_edit = $id;
    }

    /**
     * Obtener los datos del item nuevo
     */
    public function editar_nuevo(){
        if($this->material_new_edit != 0){
            $material = OrderRequestNewItem::find($this->material_new_edit);
            $this->material_new_edit_name = $material->new_item;
            $this->material_new_edit_quantity = floatval($material->quantity);
            $this->material_new_edit_measurement_unit = $material->measurement_unit_id;
            $this->material_new_edit_datasheet = $material->datasheet;
            $this->material_new_edit_image_old = $material->image;
            $this->material_new_edit_observation = $material->observation;
            $this->open_edit_new = true;
        }
    }

    /**
     * Actualizar los datos del item nuevo
     */
    public function actualizar_nuevo(){
        $this->validate();
        if($this->material_new_edit_image != ""){
            $image = $this->material_new_edit_image->store('public/newMaterials');
            Storage::delete($this->material_new_edit_image_old);
        }

        $material = OrderRequestNewItem::find($this->material_new_edit);
        $material->quantity = $this->material_new_edit_quantity;
        $material->measurement_unit_id = $this->material_new_edit_measurement_unit;
        $material->datasheet = $this->material_new_edit_datasheet;
        if($this->material_new_edit_image != ""){
            $material->image = $image;
        }
        $material->save();
        $this->open_edit_new = false;
        $this->reset('material_new_edit_name','material_new_edit_quantity','material_new_edit_measurement_unit','material_new_edit_datasheet','material_new_edit_image','material_new_edit_image_old');
        $this->iteration++;
    }

    /**
     * Eliminar el item nuevo solicitado
     */
    public function eliminar_nuevo(){
        $material = OrderRequestNewItem::find($this->material_new_edit);
        Storage::delete($material->image);
        $material->delete();
        $this->open_edit_new = false;
        $this->material_new_edit = 0;
    }

    /**
     * Obtener los datos del detalle de la solicitud de pedido
     * 
     * @param int $id ID del detalle de la solicitud de pedido
     */
    public function editar($id){
        $this->material_edit = $id;
        $material = OrderRequestDetail::find($id);
        $this->material_edit_name = $material->item->item;
        $this->quantity_edit = floatval($material->quantity);
        $this->measurement_unit_edit = $material->item->measurementUnit->abbreviation;

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

        $this->open_edit = true;
    }

    /**
     * Actualizr los datos de la solicitud de pedido
     */
    public function actualizar(){
        $this->validate();
        $material = OrderRequestDetail::find($this->material_edit);
        $material->quantity = $this->quantity_edit;
        $material->save();
        $this->open_edit = false;
        $this->render();
    }

    public function updatedIdImplemento(){
        $this->emit('cambioImplemento', $this->id_implemento);
    }

    /**
     * Cerrar la solicitud de pedido
     */
    public function cerrarPedido(){
        $request = OrderRequest::find($this->id_request);
        $request->state = 'CERRADO';
        $request->save();
        $this->id_request = 0;
        $this->id_implemento = 0;
        $this->render();
    }

    public function render(){

        /*---------------Obtener la fecha del pedido------------------------------------------*/
            if(OrderDate::where('state','ABIERTO')->exists()){
                $order_dates = OrderDate::where('state','ABIERTO')->first();
                $this->fecha_pedido_id = $order_dates->id;
                $this->fecha_pedido = $order_dates->order_date;
                $this->fecha_pedido = date("d-m-Y", strtotime($this->fecha_pedido));
                $this->fecha_pedido_abierto = $order_dates->open_request;
                $this->fecha_pedido_cierre = $order_dates->close_request;
                $this->fecha_pedido_llegada = $order_dates->arrival_date;
            }
        /*---------------Obtener órdenes del implemento ya cerradas-----------------------------*/
            $ordenes_cerradas = OrderRequest::where('user_id', auth()->user()->id)->where('state', 'CERRADO')->orwhere('state','VALIDADO')->where('order_date_id',$this->fecha_pedido_id)->get();
        /*-------------------------------------Almacenar los id de las solicitudes ya cerradas------------*/
            if($ordenes_cerradas != null){
                foreach($ordenes_cerradas as $ordenes_cerrada){
                    array_push($this->excluidos,$ordenes_cerrada->implement_id);
                }
            }
        /*---------------------Obtener los implementos con solicitudes abiertas-------------------------------*/
            $implements = Implement::where('user_id', auth()->user()->id)->whereNotIn('id',$this->excluidos)->get();
        /*----Obtener las unidades de medida-----------------------------------*/
            $measurement_units = MeasurementUnit::all();

        /*--------------Obtener los datos de la cabecera de la solicitud de pedido---------------------*/
            if ($this->id_implemento > 0) {
                if (OrderRequest::where('implement_id', $this->id_implemento)->where('state', 'PENDIENTE')->where('order_date_id',$this->fecha_pedido_id)->exists()) {
                    $orderRequest = OrderRequest::where('implement_id', $this->id_implemento)->where('state', 'PENDIENTE')->where('order_date_id',$this->fecha_pedido_id)->first();
                    $this->id_request = $orderRequest->id;
                } else {
                    $this->id_request = 0;
                }
            }
        /*---------Obtener el detalle de los materiales pedidos---------------------------------*/
            $orderRequestDetails = DB::table('lista_de_materiales_pedidos')->where('order_request_id',$this->id_request)->where('state','PENDIENTE')->select('id','sku','item','type','quantity','abbreviation','ordered_quantity','used_quantity','stock')->get();
        /*-----------Obtener el detalle de los materiales nuevos pedidos--------------------------*/
            $orderRequestNewItems = OrderRequestNewItem::where('order_request_id', $this->id_request)->where('state','PENDIENTE')->orderBy('id', 'desc')->get();

        /*--------------Obtener los datos del implemento y su ceco respectivo----------------------------*/
            if ($this->id_implemento > 0) {
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

            } else {
                $this->monto_asignado = 0;
                $this->monto_usado = 0;
            }

            $this->emit('estiloSelect2');
            return view('livewire.request-material', compact('implements', 'orderRequestDetails', 'orderRequestNewItems', 'measurement_units'));
    }
}
