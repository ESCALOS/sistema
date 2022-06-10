<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $idImplemento;
    public $idRequest;
    public $component_for_add;
    public $quantity_component_for_add;
    public $estimated_price_component = 0;

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function cambioImplemento(Implement $idImplemento, OrderRequest $idRequest)
    {
        $this->idImplemento = $idImplemento->id;
        $this->idRequest = $idRequest->id;
    }

    public function store(){
        $this->validate();

        if($this->idRequest == 0){
            $order_request = OrderRequest::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->idImplemento
            ]);
            $this->idRequest = $order_request->id;
        }
        
        OrderRequestDetail::create([
            'order_request_id' => $this->idRequest,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'observation' => '',
        ]);

        $this->reset(['component_for_add','quantity_component_for_add','estimated_price_component']);
        $this->open_componente = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function updatedQuantityComponentForAdd(){
        if($this->quantity_component_for_add > 0){
            $item = Item::where('id',$this->component_for_add)->first();
            $componente = ModelsComponent::where('id',$item->component->id)->first();
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
