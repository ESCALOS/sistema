<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $idImplemento;
    public $component_for_add;
    public $quantity_component_for_add;
    public $estimated_price_component = 0;

    protected $listeners = ['cambioImplemento'];

    public function cambioImplemento($id)
    {
        $this->idImplemento = $id;
    }

    public function render()
    {
        if($this->quantity_component_for_add > 0){
            $componente = ModelsComponent::where('id',$this->component_for_add)->first();
            $this->estimated_price_component = $this->quantity_component_for_add * $componente->item->estimated_price;
        }
        $components = ModelsComponent::whereRelation('implements','implement_id',$this->idImplemento)->get();
        return view('livewire.add-component',compact('components'));
    }
}
