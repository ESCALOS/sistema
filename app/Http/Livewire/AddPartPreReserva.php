<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\PreStockpile;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddPartPreReserva extends Component
{
    public $open_pieza = false;
    public $id_implemento = 0;
    public $id_pre_reserva = 0;
    public $part_for_add;
    public $component_for_part;
    public $quantity_part_for_add = 1;
    public $excluidos = [];

    protected $rules = [
        'part_for_add' => 'required|exists:items,id',
        'quantity_part_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'part_for_add.required' => 'Seleccione el componente',
        'part_for_add.exists' => 'La pieza no existe',
        'quantity_part_for_add.required' => 'Ingrese una cantidad',
        'quantity_part_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenComponente(){
        $this->reset(['part_for_add','quantity_component_for_add']);
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

        $item = Item::find($this->part_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->part_for_add,
            'quantity' => $this->quantity_part_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['part_for_add','quantity_part_for_add']);
        $this->open_pieza = false;
        $this->emit('render',$this->id_pre_reserva);
        $this->emit('alert');
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
