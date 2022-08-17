<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class AddToolPreReserva extends Component
{
    public $open_herramienta = false;
    public $id_implemento = 0;
    public $id_pre_reserva = 0;
    public $tool_for_add;
    public $quantity_tool_for_add = 1;
    public $stock_tool_for_add = 0;
    public $excluidos = [];

    protected $rules = [
        'tool_for_add' => 'required|exists:items,id',
        'quantity_tool_for_add' => 'required|gt:0|lte:stock_tool_for_add'
    ];

    protected $messages = [
        'tool_for_add.required' => 'Seleccione el tool',
        'tool_for_add.exists' => 'La herramienta no existe',
        'quantity_tool_for_add.required' => 'Ingrese una cantidad',
        'quantity_tool_for_add.gt' => 'La cantidad debe ser mayor de 0',
        'quantity_tool_for_add.lte' => 'No hay suficiente material en el almacen'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenHerramienta(){
        $this->reset(['tool_for_add','quantity_tool_for_add','stock_tool_for_add']);
    }
    
    /**
     * Se usar para obtener el nuevo implemento seleccionado de la pre-reserva
     * 
     * @param object $implemento  Instancia del modelo Implement
     */

    public function cambioImplemento(Implement $implemento){
        $this->id_implemento = $implemento->id;
        $this->excluidos = [];
    }

    public function updatedToolForAdd(){
        if($this->tool_for_add > 0){
            if(OperatorStock::where('item_id',$this->tool_for_add)->where('user_id',Auth::user()->id)->exists()){ 
                $asignado = OperatorStock::where('item_id',$this->tool_for_add)->where('user_id',Auth::user()->id)->first();
                $this->stock_tool_for_add = $asignado->quantity;
            }else{
                $this->stock_tool_for_add = 0;
            }
        }else{
            $this->stock_tool_for_add = 0;
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
                'ceco_id' => $this->id_ceco,
                'pre_stockpile_date_id' =>  $pre_stockpile_dates->id
            ]);
        }

        $this->id_pre_reserva = $pre_stockpile->id;

        $item = Item::find($this->tool_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->tool_for_add,
            'quantity' => $this->quantity_tool_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['tool_for_add','quantity_tool_for_add','stock_tool_for_add']);
        $this->open_herramienta = false;
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

        $added_tools = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->get();
        if($added_tools != null){
            foreach($added_tools as $added_tool){
                array_push($this->excluidos,$added_tool->item_id);
            }
        }
        $tools = Item::where('type','HERRAMIENTA')->whereNotIn('id',$this->excluidos)->get();

        return view('livewire.add-tool-pre-reserva',compact('tools'));
    }
}
