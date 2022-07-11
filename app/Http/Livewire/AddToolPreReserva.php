<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\PreStockpile;
use App\Models\PreStockpileDetail;
use Livewire\Component;

class AddToolPreReserva extends Component
{
    public $open_herramienta = false;
    public $id_implemento = 0;
    public $id_pre_reserva = 0;
    public $tool_for_add;
    public $quantity_tool_for_add = 1;
    public $excluidos = [];

    protected $rules = [
        'tool_for_add' => 'required|exists:items,id',
        'quantity_tool_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'tool_for_add.required' => 'Seleccione el tool',
        'tool_for_add.exists' => 'La herramienta no existe',
        'quantity_tool_for_add.required' => 'Ingrese una cantidad',
        'quantity_tool_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenMaterial(){
        $this->reset(['tool_for_add','quantity_tool_for_add']);
    }

    public function cambioImplemento(Implement $id_implemento){
        $this->id_implemento = $id_implemento->id;
        $this->excluidos = [];
    }

    public function store(){

        $this->validate();

        $pre_stockpile_id = PreStockpile::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        if(is_null($pre_stockpile_id)){
            $pre_stockpile = PreStockpile::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento
            ]);
            $this->id_pre_reserva = $pre_stockpile->id;
        }else{
            $this->id_pre_reserva = $pre_stockpile_id->id;
        }

        $item = Item::find($this->tool_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->tool_for_add,
            'quantity' => $this->quantity_tool_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['tool_for_add','quantity_tool_for_add']);
        $this->open_herramienta = false;
        $this->emit('render',$this->id_pre_reserva);
        $this->emit('alert');
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
