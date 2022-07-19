<?php

namespace App\Http\Livewire;

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

class AddPart extends Component
{
    public $open_parte = false;
    public $id_implemento;
    public $id_request;
    public $part_for_add= 0;
    public $quantity_part_for_add = 1;
    public $component_for_part = 0;
    public $excluidos = [];

    public $measurement_unit = "UN";

    public $ordered_quantity = 0;
    public $stock = 0;

    protected $rules = [
        'component_for_part' => 'required|exists:items,id',
        'part_for_add' => 'required|exists:items,id',
        'quantity_part_for_add' => 'required|gt:0'
    ];

    protected $messages = [
        'component_for_part.required' => 'Seleccione el componente',
        'component_for_part.exists' => 'El componente no existe',
        'part_for_add.required' => 'Seleccione la pieza',
        'part_for_add.exists' => 'La pieza no existe',
        'quantity_part_for_add.required' => 'Ingrese una cantidad',
        'quantity_part_for_add.gt' => 'La cantidad debe ser mayor de 0'
    ];

    protected $listeners = ['cambioImplemento'=>'cambioImplemento'];

    public function cambioImplemento(Implement $id_implemento)
    {
        $this->id_implemento = $id_implemento->id;
        $this->excluidos = [];
    }

    public function updatedOpenParte(){
        if(!$this->open_parte){
            $this->resetExcept(['id_implemento','open_parte','excluidos']);
        }
    }

    public function updatedComponentForPart(){
        $this->resetExcept(['id_implemento','open_parte','component_for_part','excluidos']);
    }

    public function updatedPartForAdd(){
        if($this->part_for_add > 0){

            $this->measurement_unit = Item::find($this->part_for_add)->measurementUnit->abbreviation;

            if(OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$this->part_for_add)->exists()){
                $operator_stock = OperatorStock::where('user_id',Auth::user()->id)->where('item_id',$this->part_for_add)->first();
                $this->ordered_quantity = floatval($operator_stock->ordered_quantity - $operator_stock->used_quantity);
            }else{
                $this->ordered_quantity = 0;
            }

            $stock = GeneralStock::join('general_warehouses',function($join){
                $join->on('general_warehouses.id','=','general_stocks.general_warehouse_id');
            })->where('general_stocks.item_id',$this->part_for_add)->where('general_warehouses.sede_id',Auth::user()->location->sede_id);

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
            $this->id_request = $order_request->id;
        }

        $this->id_request = $order_request->id;

        $item = Item::find($this->part_for_add);
        OrderRequestDetail::create([
            'order_request_id' => $this->id_request,
            'item_id' => $this->part_for_add,
            'quantity' => $this->quantity_part_for_add,
            'estimated_price' => $item->estimated_price,
        ]);

        $this->reset(['part_for_add','quantity_part_for_add']);
        $this->open_parte = false;
        $this->emit('render');
        $this->emit('alert');
    }

    public function render()
    {
        $added_components = OrderRequestDetail::where('order_request_id',$this->id_request)->get();
        if($added_components != null){
            foreach($added_components as $added_component){
                array_push($this->excluidos,$added_component->item_id);
            }
        }
        $components = DB::table('componentes_del_implemento')->where('implement_id','=',$this->id_implemento)->get();
        if($this->component_for_part > 0){
            $parts = DB::table('pieza_simplificada')->where('component_id',$this->component_for_part)->whereNotIn('item_id',$this->excluidos)->get();
        }else{
            $parts = [];
        }

        return view('livewire.add-part',compact('components','parts'));
    }
}
