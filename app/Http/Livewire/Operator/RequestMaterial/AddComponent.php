<?php

namespace App\Http\Livewire\Operator\RequestMaterial;

use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\Item;
use App\Models\OperatorStock;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class AddComponent extends Component
{
    public $open_componente = false;
    public $id_implemento;
    public $id_request;
    public $component_for_add = 0;
    public $quantity_component_for_add = 1;
    public $excluidos = [];

    public $measurement_unit = "UN";

    public $ordered_quantity = 0;
    public $stock = 0;

    protected $rules = [
        'component_for_add' => 'required|exists:items,id',
        'quantity_component_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'component_for_add.required' => 'Seleccione el componente',
        'component_for_add.exists' => 'El componente no existe',
        'quantity_component_for_add.required' => 'Ingrese una cantidad',
        'quantity_component_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function updatedOpenComponente(){
        if(!$this->open_componente){
            $this->resetExcept(['id_implemento','open_componente','excluidos']);
        }
    }

    /**
     * Se usar para obtener el nuevo implemento seleccionado de la solicitud de pedido
     *
     * @param object $id_implemento  Instancia del modelo Implement
     */
    public function cambioImplemento(Implement $id_implemento)
    {
        $this->id_implemento = $id_implemento->id;
        $this->excluidos = [];
    }

    public function updatedComponentForAdd(){
        if($this->component_for_add > 0){

            $this->measurement_unit = Item::find($this->component_for_add)->measurementUnit->abbreviation;

            if(OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$this->component_for_add)->exists()){
                $operator_stock = OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$this->component_for_add)->first();
                $this->ordered_quantity = floatval($operator_stock->ordered_quantity - $operator_stock->used_quantity);
            }else{
                $this->ordered_quantity = 0;
            }

            $stock = GeneralStock::where('item_id',$this->component_for_add)->where('sede_id',Auth::user()->location->sede_id);

            if($stock->exists()){
                $stock_del_item = $stock->select('general_stocks.quantity')->first();
                $this->stock = floatval($stock_del_item->quantity);
            }else{
                $this->stock = 0;
            }
        }else{
            $this->reset('ordered_quantity','stock','measurement_unit');
        }
    }

    public function store(){
        $this->validate();

        if(OrderRequest::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->exists()){
            $order_request = OrderRequest::where('implement_id',$this->id_implemento)->where('state','PENDIENTE')->first();
        }else{
            $order_dates = OrderDate::where('state','ABIERTO')->first();
            $order_request = OrderRequest::create([
                'user_id' => auth()->user()->id,
                'implement_id' => $this->id_implemento,
                'order_date_id' => $order_dates->id
            ]);
        }

        $this->id_request = $order_request->id;

        $item = Item::find($this->component_for_add);
        OrderRequestDetail::create([
            'order_request_id' => $this->id_request,
            'item_id' => $this->component_for_add,
            'quantity' => $this->quantity_component_for_add,
            'estimated_price' => $item->estimated_price,
        ]);

        $this->reset(['component_for_add','quantity_component_for_add']);
        $this->open_componente = false;
        $this->emit('render',$this->id_request);
        $this->alerta();
    }

    /**
     * Esta función se usa para mostrar el mensaje de sweetalert
     *
     * @param string $mensaje Mensaje a mostrar
     * @param string $posicion Posicion de la alerta
     * @param string $icono Icono de la alerta
     */
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'center', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->id_request)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->id_implemento)->whereNotIn('item_id',$this->excluidos)->get();

        $this->emit('estiloSelect2');

        return view('livewire.operator.request-material.add-component',compact('components'));
    }
}
