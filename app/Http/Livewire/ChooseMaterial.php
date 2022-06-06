<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use Livewire\Component;

class ChooseMaterial extends Component
{
    public $open = false;
    public $idImplement = 0;

    protected $listerners = ['abrir_modal'];

    public function abrir_modal($id){
        $this->idImplement = $id;
        $this->open = true;
    }

    public function addItems(){

    }

    public function cerrarPedido(){

    }

    public function render()
    {
        if($this->idImplement > 0){
            $implement = Implement::find($this->implement);
            $components = ModelsComponent::whereRelation('implements','implement_id',$this->implement)->get();
        }else{
            $implement = new Implement();
            $components = new ModelsComponent();
        }

        return view('livewire.choose-material',compact('implement','components'));
    }
}
