<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddMaterialPreReserva extends Component
{
    public $open_material = false;
    public $id_implemento = 0;
    public $id_pre_reserva = 0;
    public $material_for_add;
    public $quantity_material_for_add = 1;
    public $stock_material_for_add = 0;
    public $excluidos = [];

    protected $rules = [
        'material_for_add' => 'required|exists:items,id',
        'quantity_material_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'material_for_add.required' => 'Seleccione el material',
        'material_for_add.exists' => 'El material no existe',
        'quantity_material_for_add.required' => 'Ingrese una cantidad',
        'quantity_material_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenMaterial(){
        $this->reset(['material_for_add','quantity_material_for_add']);
    }

    public function cambioImplemento(Implement $id_implemento){
        $this->id_implemento = $id_implemento->id;
        $this->excluidos = [];
    }

    public function updatedMaterialForAdd(){
        if($this->material_for_add > 0){
            $asignado = OperatorStock::where('item_id',$this->material_for_add)->where('user_id',Auth::user()->id)->first();
            if($asignado != null){
                $this->stock_material_for_add = $asignado->quantity;
            }else{
                $this->stock_material_for_add = 0;
            }
        }
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

        $item = Item::find($this->material_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->material_for_add,
            'quantity' => $this->quantity_material_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['material_for_add','quantity_material_for_add']);
        $this->open_material = false;
        $this->emit('render',$this->id_pre_reserva);
        $this->emit('alert');
    }

    public function render()
    {
        $added_materials = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->get();
        if($added_materials != null){
            foreach($added_materials as $added_material){
                array_push($this->excluidos,$added_material->item_id);
            }
        }

        $materials = Item::where('type','FUNGIBLE')->whereNotIn('id',$this->excluidos)->get();

        return view('livewire.add-material-pre-reserva',compact('materials'));
    }
}
