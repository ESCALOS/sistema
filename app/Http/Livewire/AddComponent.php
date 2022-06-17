<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $idImplemento;
    public $idRequest;
    public $component_for_add;
    public $quantity_component_for_add = 1;
    public $excluidos = [];

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenComponente(){
        $this->reset(['component_for_add','quantity_component_for_add']);
    }

    public function cambioImplemento(Implement $idImplemento)
    {
        $this->idImplemento = $idImplemento->id;
        $this->excluidos = [];
    }

    public function store(){
        $this->validate();

        $order_request_id = OrderRequest::where('implement_id',$this->idImplemento)->where('state','PENDIENTE')->first();
        if(is_null($order_request_id)){
            $order_request = OrderRequest::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->idImplemento
            ]);
            $this->idRequest = $order_request->id;
        }else{
            $this->idRequest = $order_request_id->id;
        }
        $item = Item::find($this->component_for_add);
        OrderRequestDetail::create([
            'order_request_id' => $this->idRequest,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'estimated_price' => $item->estimated_price,
            'observation' => '',
        ]);

        $this->reset(['component_for_add','quantity_component_for_add']);
        $this->open_componente = false;
        $this->emit('render',$this->idRequest);
        $this->emit('alert');
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->idRequest)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->idImplemento)->whereNotIn('item_id',$this->excluidos)->get();

        return view('livewire.add-component',compact('components'));
    }
}
