<?php

namespace App\Http\Livewire;

use Livewire\Component;

class RequestNewMaterial extends Component
{
    public $open_new_material;
    public $material_new_item;
    public $material_new_quantity;
    public $material_new_measurement_unit;
    public $material_new_brand;
    public $material_new_datasheet;
    public $material_new_image;
    public $material_new_observation;

    public function render()
    {
        return view('livewire.request-new-material');
    }
}
