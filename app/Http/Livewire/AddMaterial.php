<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;

class AddMaterial extends Component
{
    public $open_material = false;
    public $idImplemento;
    public $idRequest;
    public $material_for_add;
    public $quantity_material_for_add = 0;
    public $estimated_price_material = 0;

    protected $rules = [
        'material_for_add' => 'required|exists:items,id',
        'quantity_material_for_add' => 'required|gt:0'
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
            'item_id' => $this->material_for_add,
            'quantity' => $this->quantity_material_for_add,
            'observation' => '',
        ]);

        $this->reset(['material_for_add','quantity_material_for_add','estimated_price_material']);
        $this->open_material = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function updatedQuantityMaterialForAdd(){
        
        if($this->quantity_material_for_add > 0){
            $item = Item::where('id',$this->material_for_add)->first();
            $precio = $item->estimated_price;
        }else{
            $precio = 0;
        }
        
        $this->estimated_price_material = floatval($precio)*floatval($this->quantity_material_for_add);
    }

    public function render()
    {

        $components = Item::where('type','FUNGIBLE')->get();
        return view('livewire.add-material',compact('components'));
    }
}
