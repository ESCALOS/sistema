<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\Implement;
use App\Models\MeasurementUnit;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;

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

    public $open_edit = false;

    protected $listeners = ['render','cerrarPreReserva'];

    protected $rules = [
        'material_edit_quantity' => 'required|lte:material_stock_edit'
    ];

    protected $messages = [
        'material_edit_quantity.required' => 'Ingrese una cantidad',
        'material_edit_quantity.lte' => 'No hay suficiente en el almacen'
    ];

    public function editar($id){
        $this->id_material = $id;
        $material = PreStockpileDetail::find($id);
        $this->material_edit_name = $material->item->item;
        $this->material_edit_quantity = floatval($material->quantity);
        $this->material_measurement_edit = $material->item->measurementUnit->abbreviation;
        $prereserva = PreStockpile::find($material->pre_stockpile_id);
        $stock = OperatorStock::where('item_id',$material->item_id)->where('user_id',$prereserva->user_id)->first();
        $this->material_stock_edit = floatval($stock->quantity);
        $this->open_edit = true;
    }

    public function actualizar(){
        $this->validate();
        $material = PreStockpileDetail::find($this->id_material);
        $material->quantity = $this->material_edit_quantity;
        $material->save();
        $this->open_edit = false;
        $this->render();
    }

    public function updatedIdImplemento(){
        $this->emit('cambioImplemento', $this->id_implemento);
    }

    public function cerrarPreReserva(){
        $prereserva = PreStockpile::find($this->id_pre_reserva);
        $prereserva->state = 'CERRADO';
        $prereserva->save();
        $this->id_pre_reserva = 0;
        $this->id_implemento = 0;
        $this->render();
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

        /*--------------Obtener los datos de la cabecera de la solicitud de pedido---------------------*/
        if ($this->id_implemento > 0) {
            $pre_stockpile = PreStockpile::where('implement_id', $this->id_implemento)->where('state', 'PENDIENTE')->first();
            if ($pre_stockpile != null) {
                $this->id_pre_reserva = $pre_stockpile->id;
            } else {
                $this->id_pre_reserva = 0;
            }
        }
    /*---------Obtener el detalle de los materiales pedidos---------------------------------*/
        $pre_stockpile_details = PreStockpileDetail::join('pre_stockpiles',function($join){
            $join->on('pre_stockpile_details.pre_stockpile_id','=','pre_stockpiles.id');
        })->join('items',function($join){
            $join->on('pre_stockpile_details.item_id','=','items.id');
        })->join('measurement_units',function($join){
            $join->on('items.measurement_unit_id','=','measurement_units.id');
        })->join('operator_stocks',function($join){
            $join->on('pre_stockpiles.user_id','operator_stocks.user_id')->on('pre_stockpile_details.item_id','operator_stocks.item_id');
        })->select('pre_stockpile_details.id','items.type','pre_stockpile_details.quantity','measurement_units.abbreviation','operator_stocks.ordered_quantity', 'operator_stocks.used_quantity','items.sku','items.item')
        ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)->get();

    /*--------------Obtener los datos del implemento y su ceco respectivo----------------------------*/
    if ($this->id_implemento > 0) {
        $implement = Implement::find($this->id_implemento);
        $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;

        /*---------------------Obtener el monto Asignado para los meses de llegada del pedido-------------*/
        $this->monto_asignado = CecoAllocationAmount::where('ceco_id',$implement->ceco_id)->whereDate('date',$this->fecha_pre_reserva)->sum('allocation_amount');

        /*-------------------Obtener el monto usado por el ceco en total-------------------------------------------*/
        $this->monto_usado = PreStockpileDetail::join('pre_stockpiles', function ($join){
                                                    $join->on('pre_stockpiles.id','=','pre_stockpile_details.pre_stockpile_id');
                                                })->join('implements', function ($join){
                                                    $join->on('implements.id','=','pre_stockpiles.implement_id');
                                                })->where('implements.ceco_id','=',$implement->ceco_id)
                                                  ->where('pre_stockpile_details.state','=','PENDIENTE')
                                                  ->where('pre_stockpile_details.quantity','<>',0)
                                                  ->selectRaw('SUM(pre_stockpile_details.price*pre_stockpile_details.quantity) AS total')
                                                  ->value('total');

    } else {
        $this->monto_asignado = 0;
        $this->monto_usado = 0;
    }
    /*--------------------------------Renderizar vista--------------------------------------*/
        return view('livewire.pre-reserva',compact('implements','pre_stockpile_details'));
    }
}
