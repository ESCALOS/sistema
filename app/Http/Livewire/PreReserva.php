<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\MeasurementUnit;
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
    public $fecha_pre_reserva_cerrado = "";

    public $id_implemento =  0;
    public $implemento = "";

    public function stock_real($item){
        return $item;
    }

    public function render()
    {
        /*------------Obtener la fecha de la pre-reserva--------------------------------*/
        if(PreStockpileDate::where('state','ABIERTO')->exists()){
            $pre_stockpile_date = PreStockpileDate::where('state','ABIERTO')->first();

            $this->fecha_pre_reserva = $pre_stockpile_date->open_pre_stockpile;
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
        })->join('operator_assigned_stocks',function($join){
            $join->on('pre_stockpiles.user_id','operator_assigned_stocks.user_id')->on('pre_stockpile_details.item_id','operator_assigned_stocks.item_id');
    })->select('pre_stockpile_details.id','items.type','pre_stockpile_details.quantity','measurement_units.abbreviation','operator_assigned_stocks.quantity as stock','items.sku','items.item')
    ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)->get();

        return view('livewire.pre-reserva',compact('implements','pre_stockpile_details'));
    }
}
