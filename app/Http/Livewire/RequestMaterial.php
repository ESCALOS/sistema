<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use Livewire\Component;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;

    public $idImplemento = 0;
    public $implemento;
    public $added_components = [];
    public $comp_add;
    public $horasComponente = 0;


    public function updatingIdImplemento()
    {
        $this->horas = $this->horas+=1;
    }

    public function render()
    {
        /*-if($this->idRequest>0){
            $request = OrderRequest::where('id',$this->idRequest)->first();
            $implement = Implement::where('id',$request->implement->id)->first();
            $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;
        }else{
            $this->implemento = "Seleccione un implemento";
        }
        $requests = OrderRequest::where('user_id',auth()->user()->id)->get();
        //$components = ModelsComponent::whereRelation('implements','implement_id',$this->idImplement)->get();
        $components = OrderRequestDetail::where('order_request_id',$this->idRequest)->orderBy('id','DESC')->get();
        foreach($components as $component){
            array_push($this->added_components,$component->item->id);
        }

        $select_comps = OrderRequestDetail::where('order_request_id',$this->idRequest)->whereNotIn('item_id',$this->added_components)->get();
*/
        $implements = Implement::where('user_id',auth()->user()->id)->get();
        $components = ModelsComponent::whereRelation('implements','implement_id',$this->idImplemento)->get();
        $items = Item::all();
        if($this->idImplemento>0){
            $implement = Implement::where('id',$this->idImplemento)->first();
            $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;
        }else{
            $this->implemento = "Seleccione un implemento";
        }

        return view('livewire.request-material',compact('implements','components'));
    }
}
