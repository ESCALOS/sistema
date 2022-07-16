<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $id_implemento;
    public $id_request;
    public $component_for_add;
    public $quantity_component_for_add = 1;
    public $excluidos = [];

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'component_for_add.required' => 'Seleccione el componente',
        'component_for_add.exists' => 'El componente no existe',
        'quantity_component_for_add.required' => 'Ingrese una cantidad',
        'quantity_component_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenComponente(){
        $this->reset(['component_for_add','quantity_component_for_add']);
    }

    public function cambioImplemento(Implement $id_implemento)
    {
        $this->id_implemento = $id_implemento->id;
        $this->excluidos = [];
    }

    public function store(){
        $this->validate();

        if(OrderRequest::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->exists()){
            $order_request = OrderRequest::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        }else{
            $order_dates = OrderDate::where('state','ABIERTO')->first();
            $order_request = OrderRequest::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento,
                'order_date_id' => $order_dates->id
            ]);
        }

        $this->id_request = $order_request->id;

        $item = Item::find($this->component_for_add);
        OrderRequestDetail::create([
            'order_request_id' => $this->id_request,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'estimated_price' => $item->estimated_price,
            'observation' => '',
        ]);

        $this->reset(['component_for_add','quantity_component_for_add']);
        $this->open_componente = false;
        $this->emit('render',$this->id_request);
        $this->emit('alert');
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->id_request)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->id_implemento)->whereNotIn('item_id',$this->excluidos)->get();

        return view('livewire.add-component',compact('components'));
    }
}
