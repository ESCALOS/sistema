<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddPart extends Component
{
    public $open_parte = false;
    public $idImplemento;
    public $idRequest;
    public $part_for_add= 0;
    public $quantity_part_for_add;
    public $estimated_price_part;
    public $component_for_part = 0;
    public $excluidos = [];

    protected $rules = [
        'part_for_add' => 'required|exists:items,id',
        'quantity_part_for_add' => 'required|gt:0'
    ];


    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function cambioImplemento(Implement $idImplemento)
    {
        $this->idImplemento = $idImplemento->id;;
    }

    public function updatedOpenParte(){
        $this->reset(['part_for_add','quantity_part_for_add','estimated_price_part','component_for_part']);
    }

    public function updatedComponentForPart(){
        $this->reset(['part_for_add','quantity_part_for_add','estimated_price_part']);
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

        OrderRequestDetail::create([
            'order_request_id' => $this->idRequest,
            'item_id' => $this->part_for_add,
            'quantity' => $this->quantity_part_for_add,
            'observation' => '',
        ]);

        $this->reset(['part_for_add','quantity_part_for_add','estimated_price_part']);
        $this->open_part = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function updatedQuantityPartForAdd(){

        if($this->quantity_part_for_add > 0){
            $item = Item::where('id',$this->part_for_add)->first();
            $precio = $item->estimated_price;
        }else{
            $precio = 0;
        }

        $this->estimated_price_part = floatval($precio)*floatval($this->quantity_part_for_add);
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->idRequest)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->idImplemento)->get();
        if($this->component_for_part > 0){
            $parts = DB::table('piezas_simplificada')->where('component_id',$this->component_for_part)->whereNotIn('item_id',$this->excluidos)->get();
        }else{
            $parts = [];
        }

        return view('livewire.add-part',compact('components','parts'));
    }
}
