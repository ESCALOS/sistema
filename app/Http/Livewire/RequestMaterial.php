<?php

namespace App\Http\Livewire;

use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\MeasurementUnit;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;
    use WithFileUploads;

    public $idImplemento = 0;
    public $implemento;
    public $idRequest;
    public $open_edit = false;
    public $open_edit_new = false;
    public $material_edit = 0;
    public $material_edit_name = '';

    public $material_new_edit = 0;
    public $material_new_edit_name = '';
    public $material_new_edit_quantity = 0;
    public $material_new_edit_measurement_unit = 0;
    public $material_new_edit_brand = '';
    public $material_new_edit_datasheet = '';
    public $material_new_edit_image = '';
    public $material_new_edit_observation = '';

    public $quantity_edit;

    protected $listeners = ['render'];

    public function editar_nuevo($id)
    {
        $this->material_new_edit = $id;
        $material = OrderRequestNewItem::find($id);
        $this->material_new_edit_name = $material->new_item;
        $this->material_new_edit_quantity = $material->quantity;
        $this->material_new_edit_measurement_unit = $material->measurement_unit_id;
        $this->material_new_edit_brand = $material->brand;
        $this->material_new_edit_datasheet = $material->datasheet;
        $this->material_new_edit_image = $material->image;
        $this->material_new_edit_observation = $material->observation;
        $this->open_edit_new = true;
    }

    public function actualizar_nuevo()
    {
        $material = OrderRequestNewItem::find($this->material_new_edit);
        $material->quantity = $this->material_new_edit_quantity;
        $material->measurement_unit_id = $this->material_new_edit_measurement_unit;
        $material->brand = $this->material_new_edit_brand;
        $material->datasheet = $this->material_new_edit_datasheet;
        $material->image = $this->material_new_edit_image;
        $material->observation = $this->material_new_edit_observation;
        $material->save();
        $this->open_edit_new = false;
        $this->render();
    }

    public function editar($id)
    {
        $this->material_edit = $id;
        $material = OrderRequestDetail::find($id);
        $this->material_edit_name = $material->item->item;
        $this->quantity_edit = $material->quantity;
        $this->open_edit = true;
    }

    public function actualizar()
    {
        $material = OrderRequestDetail::find($this->material_edit);
        $material->quantity = $this->quantity_edit;
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
        $implements = Implement::where('user_id', auth()->user()->id)->get();
        $measurement_units = MeasurementUnit::all();

        if ($this->idImplemento > 0) {
            $orderRequest = OrderRequest::where('implement_id', $this->idImplemento)->where('state', 'PENDIENTE')->first();
            if ($orderRequest != null) {
                $this->idRequest = $orderRequest->id;
            } else {
                $this->idRequest = 0;
            }
        }
        $orderRequestDetails = OrderRequestDetail::where('order_request_id', $this->idRequest)->orderBy('id', 'desc')->get();
        $orderRequestNewItems = OrderRequestNewItem::where('order_request_id', $this->idRequest)->orderBy('id', 'desc')->get();
        if ($this->idImplemento > 0) {
            $implement = Implement::where('id', $this->idImplemento)->first();
            $this->implemento = $implement->implementModel->implement_model . ' ' . $implement->implement_number;
        } else {
            $this->implemento = "Seleccione un implemento";
        }

        return view('livewire.request-material', compact('implements', 'orderRequestDetails', 'orderRequestNewItems', 'measurement_units'));
    }
}
