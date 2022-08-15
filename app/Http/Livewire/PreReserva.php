<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\MeasurementUnit;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class PreReserva extends Component
{
    public $excluidos = [];

    public $monto_asignado = 0;

    public $monto_usado = 0;

    public $id_pre_reserva = 0;

    public $fecha_pre_reserva = "";
    public $fecha_pre_reserva_abierto = "";

    public $id_implemento =  0;
    public $implemento = "";

    public $id_material = 0;
    public $material_edit_name = "";
    public $material_edit_quantity = 0;
    public $material_measurement_edit = "";
    public $material_stock_edit = 0;
    public $material_ordered_edit = 0;

    public $open_edit = false;

    protected $listeners = ['render','cerrarPreReserva'];

    protected $rules = [
        'material_edit_quantity' => 'required|lte:material_stock_edit|lte:material_ordered_edit'
    ];

    protected $messages = [
        'material_edit_quantity.required' => 'Ingrese una cantidad',
        'material_edit_quantity.lte' => 'No hay suficiente material'
    ];

    /**
     * Edita la cantidad para reservada por el operador
     * 
     * @param int $id ID del detalle de pre-reserva
     */
    public function editar($id){
        $this->id_material = $id;
        $material = PreStockpileDetail::find($id);
        $this->material_edit_name = $material->item->item;
        $this->material_edit_quantity = floatval($material->quantity);
        if($material->state == 'PENDIENTE') {
            $reservado = 0;
        } else{
            $reservado = floatval($material->quantity);
        }
        $this->material_measurement_edit = $material->item->measurementUnit->abbreviation;
        $prereserva = PreStockpile::find($material->pre_stockpile_id);
        $pedido = OperatorStock::where('item_id',$material->item_id)->where('user_id',$prereserva->user_id)->first(); 
        $this->material_ordered_edit = floatval($pedido->used_quantity + $reservado);
        $stock = GeneralStock::where('item_id',$material->item_id)->where('sede_id',Auth::user()->location->sede_id)->first();
        $this->material_stock_edit = floatval($stock->quantity_to_reserve + $reservado);
        $this->open_edit = true;
    }

    /**
     * Actualiza la cantidad reservada
     */
    public function actualizar(){
        $this->validate();
        $material = PreStockpileDetail::find($this->id_material);
        if(floatval($this->material_edit_quantity) <= $this->material_ordered_edit && floatval($this->material_edit_quantity) <= floatval($this->material_stock_edit)){
            //Si hay en stock
            $material->state = "RESERVADO";
            $material->quantity = $this->material_edit_quantity;
            $material->quantity_to_use = $this->material_edit_quantity;
            $material->save();
            $this->open_edit = false;
            $this->alerta('Se actualizó correctamente','top-end','success');
        }
    }

    public function updatedIdImplemento(){
        $this->emit('cambioImplemento', $this->id_implemento);
        /*--------------Obtener los datos de la cabecera de la solicitud de pedido---------------------*/
        if ($this->id_implemento > 0) {
            $pre_stockpile = PreStockpile::where('implement_id', $this->id_implemento)->where('state', 'PENDIENTE')->first();
            if ($pre_stockpile != null) {
                $this->id_pre_reserva = $pre_stockpile->id;
            } else {
                $this->id_pre_reserva = 0;
            }
        }
    }

    /**
     * Cierra la reserva siempre y cuando se hayan reservado todos los items
     */
    public function cerrarPreReserva(){
        $prereserva = PreStockpile::find($this->id_pre_reserva);
        if(PreStockpileDetail::where('state','PENDIENTE')->where('pre_stockpile_id',$this->id_pre_reserva)->doesntExist()) {
            $prereserva->state = 'CERRADO';
            $prereserva->save();
            $this->id_pre_reserva = 0;
            $this->id_implemento = 0;
            $this->alerta('Se cerró correctamente','top-end','success',);
        }else{
            $this->alerta('Aún quedan materiales no reservados','middle','error');
        }
    }
    /**
     * Esta función se usa para mostrar el mensaje de sweetalert
     * 
     * @param string $mensaje Mensaje a mostrar
     * @param string $posicion Posicion de la alerta
     * @param string $icono Icono de la alerta
     */
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'middle', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
    }

    public function render()
    {
        /*------------Obtener la fecha de la pre-reserva--------------------------------*/
        if(PreStockpileDate::where('state','ABIERTO')->exists()){
            $pre_stockpile_date = PreStockpileDate::where('state','ABIERTO')->first();
            $this->fecha_pre_reserva = $pre_stockpile_date->pre_stockpile_date;
            $this->fecha_pre_reserva_abierto = $pre_stockpile_date->open_pre_stockpile;
        }

        /*---------------Obtener pre-reservas del implemento ya cerradas-----------------------------*/
        $pre_reserva_cerradas = PreStockpile::where('user_id', auth()->user()->id)->where('state', 'CERRADO')->get();
        /*-------------------------------------Almacenar los id de las solicitudes ya cerradas------------*/
        if($pre_reserva_cerradas != null){
            foreach($pre_reserva_cerradas as $pre_reserva_cerrada){
                array_push($this->excluidos,$pre_reserva_cerrada->implement_id);
            }
        }
        /*---------------------Obtener los implementos con solicitudes abiertas-------------------------------*/
        $implements = Implement::where('user_id', auth()->user()->id)->whereNotIn('id',$this->excluidos)->get();
        /*----Obtener las unidades de medida-----------------------------------*/
        $measurement_units = MeasurementUnit::all();

        
    /*---------Obtener el detalle de los materiales pedidos---------------------------------*/
        $pre_stockpile_details = PreStockpileDetail::join('pre_stockpiles',function($join){
            $join->on('pre_stockpile_details.pre_stockpile_id','pre_stockpiles.id');
        })->join('implements',function($join){
            $join->on('implements.id','pre_stockpiles.implement_id');
        })->join('locations',function($join){
            $join->on('implements.location_id','locations.id');
        })->join('items',function($join){
            $join->on('pre_stockpile_details.item_id','=','items.id');
        })->join('measurement_units',function($join){
            $join->on('items.measurement_unit_id','=','measurement_units.id');
        })->join('operator_stocks',function($join){
            $join->on('pre_stockpiles.user_id','operator_stocks.user_id')->on('pre_stockpile_details.item_id','operator_stocks.item_id');
        })->join('general_stocks',function($join){
            $join->on('pre_stockpile_details.item_id','general_stocks.item_id')->on('locations.sede_id','general_stocks.sede_id');
        })->select('pre_stockpile_details.id','items.type','pre_stockpile_details.state','general_stocks.quantity_to_reserve','pre_stockpile_details.quantity','measurement_units.abbreviation','operator_stocks.ordered_quantity', 'operator_stocks.used_quantity','items.sku','items.item')
        ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)->get();

    /*--------------Obtener los datos del implemento y su ceco respectivo----------------------------*/
    if ($this->id_implemento > 0) {
        $implement = Implement::find($this->id_implemento);
        $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;

        /*---------------------Obtener el monto Asignado para los meses de llegada del pedido-------------*/
        $this->monto_asignado = CecoAllocationAmount::where('ceco_id',$implement->ceco_id)->whereDate('date',$this->fecha_pre_reserva)->sum('allocation_amount');

        /*-------------------Obtener el monto usado por el ceco en total-------------------------------------------*/
        $this->monto_usado = PreStockpileDetail::join('pre_stockpile_price_details', function ($join){
            $join->on('pre_stockpile_details.id','=','pre_stockpile_price_details.pre_stockpile_detail_id');
        })->join('general_stock_details',function($join){
            $join->on('general_stock_details.id','pre_stockpile_price_details.general_stock_detail_id');
        })->where('pre_stockpile_details.quantity','>',0)
          ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)
          ->selectRaw('SUM(general_stock_details.price*pre_stockpile_price_details.quantity) AS total')
          ->value('total');
        /*$this->monto_usado = PreStockpileDetail::join('pre_stockpiles', function ($join){
                                                    $join->on('pre_stockpiles.id','=','pre_stockpile_details.pre_stockpile_id');
                                                })->join('implements', function ($join){
                                                    $join->on('implements.id','=','pre_stockpiles.implement_id');
                                                })->join('pre_stockpile_price_details',function($join){
                                                    $join->on('pre_stockpile_price_details.pre_stockpile_detail_id','pre_stockpile_details.id');
                                                })->join('general_stock_details',function($join){
                                                    $join->on('general_stock_details.id','pre_stockpile_price_details.general_stock_detail_id');
                                                })->where('implements.ceco_id','=',$implement->ceco_id)
                                                  ->where('pre_stockpile_details.state','=','PENDIENTE')
                                                  ->where('pre_stockpile_details.quantity','<>',0)
                                                  ->selectRaw('SUM(general_stock_details.price*pre_stockpile_price_details.quantity) AS total')
                                                  ->value('total');*/

    } else {
        $this->monto_asignado = 0;
        $this->monto_usado = 0;
    }
    /*--------------------------------Renderizar vista--------------------------------------*/
        return view('livewire.pre-reserva',compact('implements','pre_stockpile_details'));
    }
}
