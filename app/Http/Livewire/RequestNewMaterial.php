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

    public $id_request;
    public $id_implemento;
    public $iteration = 0;

    public $open_new_material;

    public $material_new_item;
    public $material_new_quantity;
    public $material_new_measurement_unit;
    public $material_new_datasheet;
    public $material_new_image;

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    protected function rules(){
        return [
            'material_new_item' => 'required',
            'material_new_quantity' => 'required|gt:0',
            'material_new_measurement_unit' => 'required|exists:measurement_units,id',
            'material_new_datasheet' => 'required',
            'material_new_image' => 'required|image',
        ];
    }

    protected $messages = [
        'material_new_item.required' => 'Ingrese el nombre',
        'material_new_quantity.required' => 'Ingrese la cantidad',
        'material_new_quantity.gt' => 'Debe ser mayor de 0',
        'material_new_measurement_unit.required' => 'Seleccione una unidad de medida',
        'material_new_measurement_unit.exists' => 'La unidad de medida no existe',
        'material_new_datasheet.required' => 'Ingrese la ficha técnica',
        'material_new_image.required' => 'Ingrese una imagen',
        'material_new_image.image' => 'El archivo debe de ser una imagen'
    ];

    public function cambioImplemento(Implement $id_implemento)
    {
        $this->id_implemento = $id_implemento->id;
    }

    public function updatedMaterialNewImage(){
        $nombre_de_imagen = $this->material_new_image->getClientOriginalName();
        if(!preg_match('/.jpg$/i',$nombre_de_imagen)
        && !preg_match('/.jpeg$/i',$nombre_de_imagen)
        && !preg_match('/.png$/i',$nombre_de_imagen)
        && !preg_match('/.gif$/i',$nombre_de_imagen)
        && !preg_match('/.jfif$/i',$nombre_de_imagen)
        && !preg_match('/.svg$/i',$nombre_de_imagen)){
            $this->material_new_image = "";
            $this->iteration++;
        }
        $this->resetValidation('material_new_image');
    }

    public function updatedOpenNewMaterial(){
        $this->reset('material_new_item','material_new_quantity','material_new_measurement_unit','material_new_datasheet');
        $this->material_new_image = null;
        $this->resetValidation();
        $this->iteration++;
    }

    public function store(){
        $this->validate();
        $order_request_id = OrderRequest::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        if(is_null($order_request_id)){
            $order_request = OrderRequest::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento
            ]);
            $this->id_request = $order_request->id;
        }else{
            $this->id_request = $order_request_id->id;
        }
        if($this->material_new_image != ""){
            $image = $this->material_new_image->store('public/newMaterials');
        }

        OrderRequestNewItem::create([
            'order_request_id' => $this->id_request,
            'new_item' => $this->material_new_item,
            'quantity' => $this->material_new_quantity,
            'measurement_unit_id' => $this->material_new_measurement_unit,
            'datasheet' => $this->material_new_datasheet,
            'image' => $image,
            'observation' => '',
        ]);
        $this->emit('render',$this->id_request);
        $this->open_new_material = false;
        $this->emit('alert');
    }

    public function render()
    {
        $measurement_units = MeasurementUnit::all();

        return view('livewire.request-new-material', compact('measurement_units'));
    }
}
