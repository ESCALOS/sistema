<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use Livewire\Component;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;

    public $open = false;
    public $idImplement = 1;
    public $pedidos = [];

    public function abrir_modal($id){
        $this->idImplement = $id;
        $this->open = true;
    }

    public function render()
    {   $implements = Implement::where('user_id',auth()->user()->id)->get();
        if($this->idImplement > 0){
            $componentes = ModelsComponent::whereRelation('implements','implement_id',$this->idImplement)->get();
        }else{
            $componentes = ModelsComponent::class;
        }

        return view('livewire.request-material',compact('implements','componentes'));
    }
}
