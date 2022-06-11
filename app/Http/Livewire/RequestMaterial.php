<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;

    public $idImplemento = 0;
    public $implemento;
    public $idRequest;
    public $open_edit = false;
    public $material_edit = 0;
    public $material_edit_name = '';
    public $material_nuevo_seleccionado = 0;

    public $cantidad_edit;

    protected $listeners = ['render'];

    public function seleccionar_material_nuevo($id)
    {
        $this->material_nuevo_seleccionado = $id;
    }

    public function editar($id)
    {
        $this->material_edit = $id;
        $material = OrderRequestDetail::find($id);
        $this->material_edit_name = $material->item->item;
        $this->cantidad_edit = $material->quantity;
        $this->open_edit = true;
    }

    public function actualizar(){
        $material = OrderRequestDetail::find($this->material_edit);
        $material->cantidad = $this->cantidad_edit;
        $material->save();
        $this->open_edit = false;
        $this->render();
    }

    public function updatedIdImplemento()
    {
        $this->emit('cambioImplemento', $this->idImplemento);
    }
    public function render()
    {
        $implements = Implement::where('user_id',auth()->user()->id)->get();

        if($this->idImplemento > 0){
            $orderRequest = OrderRequest::where('implement_id',$this->idImplemento)->where('state','PENDIENTE')->first();
            if($orderRequest!=null){
                $this->idRequest = $orderRequest->id;
            }else{
                $this->idRequest = 0;
            }
        }
        $orderRequestDetails = OrderRequestDetail::where('order_request_id',$this->idRequest)->orderBy('id','desc')->get();
        $orderRequestNewItems = OrderRequestNewItem::where('order_request_id',$this->idRequest)->orderBy('id','desc')->get();
        if($this->idImplemento>0){
            $implement = Implement::where('id',$this->idImplemento)->first();
            $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;
        }else{
            $this->implemento = "Seleccione un implemento";
        }

        return view('livewire.request-material',compact('implements','orderRequestDetails','orderRequestNewItems'));
    }
}
