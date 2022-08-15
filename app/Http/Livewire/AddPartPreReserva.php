<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddPartPreReserva extends Component
{
    public $open_pieza = false;
    public $id_implemento = 0;
    public $id_ceco = 0;
    public $id_pre_reserva = 0;
    public $part_for_add = 0;
    public $component_for_part = 0;
    public $quantity_part_for_add = 1;
    public $stock_part_for_add = 0;
    public $excluidos = [];

    protected $rules = [
        'part_for_add' => 'required|exists:items,id',
        'quantity_part_for_add' => 'required|gt:0|lte:stock_part_for_add'
    ];

    protected $messages = [
        'part_for_add.required' => 'Seleccione la pieza',
        'part_for_add.exists' => 'La pieza no existe',
        'quantity_part_for_add.required' => 'Ingrese una cantidad',
        'quantity_part_for_add.gt' => 'La cantidad debe ser mayor de 0',
        'quantity_part_for_add.lte' => 'No hay suficiente cantidad de en el almacén'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenPieza(){
        $this->component_for_part = 0;
        $this->part_for_add = 0;
        $this->quantity_part_for_add = 1;
        $this->stock_part_for_add = 0;
    }

    public function updatedComponentForPart(){
        $this->part_for_add = 0;
        $this->quantity_part_for_add = 1;
        $this->stock_part_for_add = 0;
    }

    public function updatedPartForAdd(){
        if($this->part_for_add > 0){
            if(OperatorStock::where('item_id',$this->part_for_add)->where('user_id',Auth::user()->id)->exists()){
                $asignado = OperatorStock::where('item_id',$this->part_for_add)->where('user_id',Auth::user()->id)->first();
                $this->stock_part_for_add = floatval($asignado->quantity);
            }else{
                $this->stock_part_for_add = 0;
            }
        }else{
            $this->stock_part_for_add = 0;
        }
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

    public function store(){
        $this->validate();
        
        if(PreStockpile::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->exists()){
            $pre_stockpile = PreStockpile::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        }else{
            $pre_stockpile_dates = PreStockpileDate::where('state','ABIERTO')->first();
            $pre_stockpile = PreStockpile::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento,
                'ceco_id' => $this->id_ceco,
                'pre_stockpile_date_id' =>  $pre_stockpile_dates->id
            ]);
        }

        $this->id_pre_reserva = $pre_stockpile->id;

        $item = Item::find($this->part_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->part_for_add,
            'quantity' => $this->quantity_part_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['part_for_add','quantity_part_for_add','stock_part_for_add']);
        $this->open_pieza = false;
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
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'middle', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
    }

    public function render()
    {
        $added_parts = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->get();
        if($added_parts != null){
            foreach($added_parts as $added_part){
                array_push($this->excluidos,$added_part->item_id);
            }
        }

        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->id_implemento)->get();
        
        if($this->component_for_part > 0){
            $parts = DB::table('pieza_simplificada')->where('component_id',$this->component_for_part)->whereNotIn('item_id',$this->excluidos)->get();
        }else{
            $parts = [];
        }

        return view('livewire.add-part-pre-reserva',compact('components','parts'));
    }
}
