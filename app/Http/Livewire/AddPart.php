<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;

class AddPart extends Component
{
    public $open_parte = false;
    public $idImplemento;
    public $idRequest;
    public $part_for_add;
    public $quantity_part_for_add;
    public $estimated_price_part = 0;

    protected $rules = [
        'part_for_add' => 'required|exists:items,id',
        'quantity_parte_for_add' => 'required|gt:0'
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
            'item_id' => $this->part_for_add,
            'quantity' => $this->quantity_part_for_add,
            'observation' => '',
        ]);

        $this->reset(['part_for_add','quantity_part_for_add','estimated_price_part']);
        $this->open_parte = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function updatedQuantityPartForAdd(){
        if($this->quantity_part_for_add > 0){
            $item = Item::where('id',$this->part_for_add)->first();
            $parte = ModelsComponent::where('id',$item->component->id)->first();
            $item = Item::find($parte->item_id);
            $this->estimated_price_part = $item->estimated_price*$this->quantity_part_for_add;
        }
    }


    public function render()
    {
        
        $components = ModelsComponent::whereRelation('implements','implement_id',$this->idImplemento)->get();
        
        return view('livewire.add-part',compact('components'));
    }
}
