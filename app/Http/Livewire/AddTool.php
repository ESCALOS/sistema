<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;

class AddTool extends Component
{
    public $open_tool = false;
    public $idImplemento;
    public $idRequest;
    public $tool_for_add;
    public $quantity_tool_for_add = 1;
    public $estimated_price_tool;
    public $excluidos = [];

    protected $rules = [
        'tool_for_add' => 'required|exists:items,id',
        'quantity_tool_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'tool_for_add.required' => 'Seleccione el material',
        'tool_for_add.exists' => 'El material no existe',
        'quantity_tool_for_add.required' => 'Ingrese una cantidad',
        'quantity_tool_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function cambioImplemento(Implement $idImplemento)
    {
        $this->idImplemento = $idImplemento->id;
        $this->excluidos = [];
    }

    public function updatedOpenTool(){
        $this->reset(['tool_for_add','quantity_tool_for_add','estimated_price_tool']);
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
        $item = Item::find($this->tool_for_add);
        OrderRequestDetail::create([
            'order_request_id' => $this->idRequest,
            'item_id' => $this->tool_for_add,
            'quantity' => $this->quantity_tool_for_add,
            'estimated_price' => $item->estimated_price,
            'observation' => '',
        ]);

        $this->reset(['tool_for_add','quantity_tool_for_add','estimated_price_tool']);
        $this->open_tool = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function updatedQuantitytoolForAdd(){

        if($this->quantity_tool_for_add > 0){
            $item = Item::where('id',$this->tool_for_add)->first();
            $precio = $item->estimated_price;
        }else{
            $precio = 0;
        }

        $this->estimated_price_tool = floatval($precio)*floatval($this->quantity_tool_for_add);
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->idRequest)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = Item::where('type','HERRAMIENTA')->whereNotIn('id',$this->excluidos)->get();
        return view('livewire.add-tool',compact('components'));
    }
}
