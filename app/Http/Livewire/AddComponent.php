<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $idImplemento;
    public $component_for_add;
    public $quantity_component_for_add;
    public $estimated_price_component = 0;

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0'
    ];

    protected $listeners = ['cambioImplemento'];

    public function cambioImplemento($id)
    {
        $this->idImplemento = $id;
    }

    public function store(){
        $this->validate();

        $order_request = OrderRequest::where('implement_id',$this->idImplemento)->where('state','PENDIENTE')->first();

        OrderRequestDetail::created([
            'order_request_id' => $order_request->id,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'observation' => '',
        ]);

        $this->reset(['component_for_add','quantity_component_for_add','estimated_price_component']);
        $this->open_componente = false;
        $this->emit('alert');
    }

    public function updatedQuantity_component_for_add(){
        if($this->quantity_component_for_add > 0){
            $componente = ModelsComponent::where('id',$this->component_for_add)->first();
            $item = Item::find($componente->item_id);
            $this->estimated_price_component = $item->estimated_price*$this->quantity_component_for_add;
        }
    }

    public function render()
    {

        $components = ModelsComponent::whereRelation('implements','implement_id',$this->idImplemento)->get();
        return view('livewire.add-component',compact('components'));
    }
}
