<?php

namespace App\Http\Livewire\Operator\PreReserva;

use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class AddMaterialPreReserva extends Component
{
    public $open_material = false;
    public $id_implemento = 0;
    public $id_ceco = 0;
    public $id_pre_reserva = 0;
    public $material_for_add;
    public $quantity_material_for_add = 1;
    public $stock_material_for_add = 0;
    public $ordered_material_for_add = 0;
    public $excluidos = [];

    protected $rules = [
        'material_for_add' => 'required|exists:items,id',
        'quantity_material_for_add' => 'required|gt:0|lte:stock_material_for_add|lte:ordered_material_for_add'
    ];

    protected $messages = [
        'material_for_add.required' => 'Seleccione el material',
        'material_for_add.exists' => 'El material no existe',
        'quantity_material_for_add.required' => 'Ingrese una cantidad',
        'quantity_material_for_add.gt' => 'La cantidad debe ser mayor de 0',
        'quantity_material_for_add.lte' => 'No hay suficiente en el almacen'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenMaterial(){
        $this->reset(['material_for_add','quantity_material_for_add','stock_material_for_add']);
    }

    /**
     * Se usar para obtener el nuevo implemento seleccionado de la pre-reserva
     *
     * @param object $implemento  Instancia del modelo Implement
     */
    public function cambioImplemento(Implement $implemento){
        $this->id_implemento = $implemento->id;
        $this->id_ceco = $implemento->ceco_id;
        $this->excluidos = [];
    }

    public function updatedMaterialForAdd(){
        if($this->material_for_add > 0){
            if(OperatorStock::where('item_id',$this->material_for_add)->where('user_id',Auth::user()->id)->exists()){
                $asignado = OperatorStock::where('item_id',$this->material_for_add)->where('user_id',Auth::user()->id)->first();
                $this->ordered_material_for_add = floatval($asignado->ordered_quantity);
                $stock = GeneralStock::where('item_id',$this->material_for_add)->where('sede_id',Auth::user()->location->sede_id)->first();
                $this->stock_material_for_add = floatval($stock->quantity_to_reserve);
            }else{
                $this->ordered_material_for_add = 0;
                $this->stock_material_for_add = 0;
            }
        }else{
            $this->ordered_material_for_add = 0;
            $this->stock_material_for_add = 0;
        }
    }

    public function store(){
        $this->validate();

        if(PreStockpile::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->exists()){
            $pre_stockpile = PreStockpile::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        }else{
            $pre_stockpile_dates = PreStockpileDate::where('state','ABIERTO')->first();
            $pre_stockpile = PreStockpile::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento,
                'pre_stockpile_date_id' =>  $pre_stockpile_dates->id
            ]);
        }

        $this->id_pre_reserva = $pre_stockpile->id;

        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->material_for_add,
            'quantity' => $this->quantity_material_for_add,
            'state' => 'RESERVADO',
            'quantity_to_use' => $this->quantity_material_for_add,
        ]);

        $this->reset(['material_for_add','quantity_material_for_add','ordered_material_for_add','stock_material_for_add']);
        $this->open_material = false;
        $this->emit('render',$this->id_pre_reserva);
        $this->alerta();
    }

    /**
     * Esta función se usa para mostrar el mensaje de sweetalert
     *
     * @param string $mensaje Mensaje a mostrar
     * @param string $posicion Posicion de la alerta
     * @param string $icono Icono de la alerta
     */
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'center', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
    }

    public function render()
    {
        $added_materials = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->get();
        if($added_materials != null){
            foreach($added_materials as $added_material){
                array_push($this->excluidos,$added_material->item_id);
            }
        }

        $materials = Item::where('type','FUNGIBLE')->join('operator_stocks',function($join){
            $join->on('items.id','operator_stocks.item_id');
        })->whereNotIn('items.id',$this->excluidos)->where('operator_stocks.user_id',Auth::user()->id)->select('items.*')->get();

        return view('livewire.operator.pre-reserva.add-material-pre-reserva',compact('materials'));
    }
}
