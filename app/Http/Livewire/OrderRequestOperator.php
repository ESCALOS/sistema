<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\OrderRequest;
use App\Models\User;
use Livewire\Component;
use Livewire\WithPagination;

class OrderRequestOperator extends Component
{
    use WithPagination;

    public $idRequestOperador = 0;
    public $suser;
    public $simplement;
    public $sstate = "PENDIENTE";

    protected $listeners = ['render'];

    public function seleccionar($id){
        $this->idRequestOperador = $id;
        $this->emit('capturar',$this->idRequestOperador);
    }

    public function anular(){
        $requestOperador = OrderRequest::find($this->idRequestOperador);
        $requestOperador->is_canceled = 1;
        $requestOperador->save();
        $this->idRequestOperador = 0;
        $this->render();
    }

    public function render()
    {
        $users = User::all();
        $implements = Implement::all();

        $orderRequests = OrderRequest::where('is_canceled',0)->where('state',$this->sstate);

        if($this->suser > 0){
            $orderRequests = $orderRequests->where('user_id',$this->suser);
        }

        if($this->simplement > 0){
            $orderRequests = $orderRequests->where('implement_id',$this->simplement);
        }

        return view('livewire.order-request-operator',compact('orderRequests','users','implements'));
    }
}
