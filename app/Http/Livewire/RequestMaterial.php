<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\Component as ModelsComponent;
use App\Models\Implement;
use App\Models\Item;
use App\Models\MeasurementUnit;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\OrderRequestNewItem;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\WithPagination;

class RequestMaterial extends Component
{
    use WithPagination;
    use WithFileUploads;

    public $excluidos = [];
    public $monto_asignado = 0;
    public $monto_usado = 0;

    public $idImplemento = 0;
    public $implemento;
    public $idRequest;
    public $open_edit = false;
    public $open_edit_new = false;
    public $material_edit = 0;
    public $material_edit_name = '';

    public $material_new_edit;
    public $material_new_edit_name ;
    public $material_new_edit_quantity;
    public $material_new_edit_measurement_unit;
    public $material_new_edit_brand ;
    public $material_new_edit_datasheet;
    public $material_new_edit_image;
    public $material_new_edit_image_old;
    public $material_new_edit_observation;

    public $quantity_edit;

    protected $listeners = ['render'];

    public function updatedOpenEditNew(){
        $this->reset('material_new_edit_name','material_new_edit_quantity','material_new_edit_measurement_unit','material_new_edit_brand','material_new_edit_datasheet','material_new_edit_image','material_new_edit_observation');
    }

    public function seleccionar($id){
        $this->material_new_edit = $id;
    }

    public function editar_nuevo()
    {
        if($this->material_new_edit != 0){
            $material = OrderRequestNewItem::find($this->material_new_edit);
            $this->material_new_edit_name = $material->new_item;
            $this->material_new_edit_quantity = $material->quantity;
            $this->material_new_edit_measurement_unit = $material->measurement_unit_id;
            $this->material_new_edit_brand = $material->brand;
            $this->material_new_edit_datasheet = $material->datasheet;
            $this->material_new_edit_image_old = $material->image;
            $this->material_new_edit_observation = $material->observation;
            $this->open_edit_new = true;
        }
    }

    public function actualizar_nuevo()
    {
        if($this->material_new_edit_image != ""){
            $image = $this->material_new_edit_image->store('public/newMaterials');
            Storage::delete($this->material_new_edit_image_old);
        }

        $material = OrderRequestNewItem::find($this->material_new_edit);
        $material->quantity = $this->material_new_edit_quantity;
        $material->measurement_unit_id = $this->material_new_edit_measurement_unit;
        $material->brand = $this->material_new_edit_brand;
        $material->datasheet = $this->material_new_edit_datasheet;
        if($this->material_new_edit_image != ""){
            $material->image = $image;
        }
        $material->observation = $this->material_new_edit_observation;
        $material->save();
        $this->open_edit_new = false;
        $this->render();
    }

    public function eliminar_nuevo(){
        $material = OrderRequestNewItem::find($this->material_new_edit);
        Storage::delete($material->image);
        $material->delete();
        $this->open_edit_new = false;
        $this->material_new_edit = 0;
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

    public function cerrarPedido(){
        $request = OrderRequest::find($this->idRequest);
        $request->state = 'CERRADO';
        $request->save();
        $this->idRequest = 0;
        $this->render();
    }

    public function render()
    {
        $ordenes_cerradas = OrderRequest::where('user_id', auth()->user()->id)->where('state', 'CERRADO')->get();

        if($ordenes_cerradas != null){
            foreach($ordenes_cerradas as $ordenes_cerrada){
                array_push($this->excluidos,$ordenes_cerrada->implement_id);
            }
        }

        $implements = Implement::where('user_id', auth()->user()->id)->whereNotIn('id',$this->excluidos)->get();

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
            $this->monto_asignado = $implement->ceco->amount;
            $acumulado = DB::table('monto_usado_pedido')->where('order_request_id', $this->idRequest)->get();
            $this->monto_usado = $acumulado->total;
        } else {
            $this->implemento = "Seleccione un implemento";
            $this->monto_usado = 0;
        }

        return view('livewire.request-material', compact('implements', 'orderRequestDetails', 'orderRequestNewItems', 'measurement_units'));
    }
}
