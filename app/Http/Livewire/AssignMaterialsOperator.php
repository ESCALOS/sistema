<?php

namespace App\Http\Livewire;

use App\Models\OrderRequest;
use Livewire\Component;

class AssignMaterialsOperator extends Component
{
    public function render()
    {
        $pedidos = OrderRequest::where('state','VALIDADO');
        return view('livewire.assign-materials-operator',compact('pedidos'));
    }
}
