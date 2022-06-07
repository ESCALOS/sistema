<?php

namespace App\Http\Livewire;

use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Livewire\Component;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;

    public $open;
    public $idImplement=0;
    public $inputs = [];

    public function updateOrderRequest($order_request, $quantity){
        $order_request = OrderRequestDetail::find($order_request);
        $order_request->quantity = $quantity;
        $order_request->save();
        $this->render();
    }

    public function abrir_modal($id){
        $this->idImplement = $id;
        foreach(OrderRequestDetail::where('order_request_id',$id)->get() as $item){
            array_push($this->inputs,[
                "id" => $item->id,
                "componente" => $item->item->item,
                "quantity"=>$item->quantity,
            ]);
        }
        $this->open = true;
    }

    public function cerrar(){
        $this->open = false;
        $this->inputs = [];
    }

    public function increase($index){
        $componente = $this->inputs[$index]['id'];
        $this->inputs[$index]['quantity']+=1;
        $this->actualizar($componente,$this->inputs[$index]['quantity']);
    }

    public function reduce($index){
        if($this->inputs[$index]['quantity'] > 0){
            $componente = $this->inputs[$index]['id'];
            $this->inputs[$index]['quantity']-=1;
            $this->actualizar($componente,$this->inputs[$index]['quantity']);
        }
    }

    public function actualizar($id,$cantidad){
        $order_request = OrderRequestDetail::find($id);
        $order_request->quantity = $cantidad;
        $order_request->save();
    }
    
    public function render()
    {   
        $implements = OrderRequest::where('user_id',auth()->user()->id)->get();
        
        return view('livewire.request-material',compact('implements'));
    }
}
