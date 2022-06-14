<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\MeasurementUnit;
use App\Models\OrderRequest;
use App\Models\OrderRequestNewItem;
use Livewire\Component;
use Livewire\WithFileUploads;

class RequestNewMaterial extends Component
{
    use WithFileUploads;

    public $idRequest;
    public $idImplemento;

    public $open_new_material;
    public $material_new_item;
    public $material_new_quantity;
    public $material_new_measurement_unit;
    public $material_new_brand;
    public $material_new_datasheet;
    public $material_new_image;
    public $material_new_observation;

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function cambioImplemento(Implement $idImplemento)
    {
        $this->idImplemento = $idImplemento->id;
    }

    public function store(){

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
        if($this->material_new_image != ""){
            $image = $this->material_new_image->store('public/newMaterials');
        }

        OrderRequestNewItem::create([
            'order_request_id' => $this->idRequest,
            'new_item' => $this->material_new_item,
            'quantity' => $this->material_new_quantity,
            'measurement_unit_id' => $this->material_new_measurement_unit,
            'brand' => $this->material_new_brand,
            'datasheet' => $this->material_new_datasheet,
            'image' => $image,
            'observation' => $this->material_new_observation,
        ]);

        $this->reset('material_new_item', 'material_new_quantity', 'material_new_measurement_unit', 'material_new_brand', 'material_new_datasheet', 'material_new_image', 'material_new_observation');
        $this->emit('render',$this->idRequest);
        $this->open_new_material = false;
        $this->emit('alert');
    }

    public function render()
    {
        $measurement_units = MeasurementUnit::all();

        return view('livewire.request-new-material', compact('measurement_units'));
    }
}
