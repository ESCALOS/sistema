<?php

namespace App\Http\Livewire;

use App\Models\GeneralStockDetail;
use App\Models\Sede;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
USE Livewire\WithFileUploads;
use Livewire\WithPagination;
use Maatwebsite\Excel\Facades\Excel;

class InsertMaterial extends Component
{
    use WithFileUploads;
    use WithPagination;

    public $selectedSedes = [];

    public $id_stock = 0;

    public $open_import_stock = false;

    public $order_templates = 0;

    public function addSedeFilter($sede_id){
        $indice = array_search($sede_id,$this->selectedSedes,true);
        if($indice != "" && $indice >= 0){
            unset($this->selectedSedes[$indice]);
        }else{
            array_push($this->selectedSedes,$sede_id);
        }
    }

    public function importarStock(){
        //$this->validate();

        //Excel::import(new GeneralStockImport, $this->item);
        $this->open_import_stock = false;
        $this->emit('alert');

    }

    public function render()
    {
        $sedes = Sede::where('zone_id',Auth::user()->location->sede->zone->id)->get();

        $general_stock_details = GeneralStockDetail::join('items',function($join){
            $join->on('items.id','general_stock_details.item_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','general_stock_details.sede_id');
        })->where('general_stock_details.is_canceled',0);

        if(!empty($this->selectedSedes)){
            $general_stock_details = $general_stock_details->whereIn('sede_id',$this->selectedSedes);
        }

        $general_stock_details = $general_stock_details->select('general_stock_details.id','items.item','items.type','general_stock_details.quantity','general_stock_details.price','sedes.sede','general_stock_details.order_date_id')->orderBy('id','DESC')->paginate(5);

        return view('livewire.insert-material',compact('general_stock_details','sedes'));
    }
}
