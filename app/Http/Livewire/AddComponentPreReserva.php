<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\PreStockpile;
use App\Models\PreStockpileDetail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddComponentPreReserva extends Component
{
    public $open_componente = false;
    public $id_implemento = 0;
    public $id_pre_reserva = 0;
    public $component_for_add;
    public $quantity_component_for_add = 1;
    public $stock_component_for_add;
    public $excluidos = [];

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0',
        'stock_component_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'component_for_add.required' => 'Seleccione el componente',
        'component_for_add.exists' => 'El componente no existe',
        'quantity_component_for_add.required' => 'Ingrese una cantidad',
        'quantity_component_for_add.gt' => 'La cantidad debe ser mayor de 0',
        'stock_component_for_add.gt' => 'No hay material en el almacen'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenComponente(){
        $this->reset(['component_for_add','quantity_component_for_add']);
    }

    public function updatedComponentForAdd(){
        if($this->component_for_add > 0){
            $asignado = OperatorStock::where('item_id',$this->component_for_add)->where('user_id',Auth::user()->id)->first();
            if($asignado != null){
                $this->stock_component_for_add = $asignado->quantity;
            }else{
                $this->stock_component_for_add = 0;
            }
        }
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
                'implement_id' => $this->idmplemento
            ]);
            $this->id_pre_reserva = $pre_stockpile->id;
        }else{
            $this->id_pre_reserva = $pre_stockpile_id->id;
        }

        $item = Item::find($this->component_for_add);
        PreStockpileDetail::create([
            'pre_stockpile_id' => $this->id_pre_reserva,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'price' => $item->estimated_price,
            'warehouse_id' => auth()->user()->location->warehouse->id,
        ]);

        $this->reset(['component_for_add','quantity_component_for_add']);
        $this->open_componente = false;
        $this->emit('render',$this->id_pre_reserva);
        $this->emit('alert');
    }

    public function render()
    {
        $added_components = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->id_implemento)->whereNotIn('item_id',$this->excluidos)->get();

        return view('livewire.add-component-pre-reserva',compact('components'));
    }
}
