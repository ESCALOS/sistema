<?php

namespace App\Http\Livewire;

use App\Imports\GeneralStockImport;
use App\Models\GeneralStockDetail;
use App\Models\OrderDate;
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

    public $stock;

    public $open_import_stock = false;

    public $iteration = 0;

    public $fecha_pedido = 0;

    protected function rules(){
        return [
            'stock' => ['required','mimes:xlsx'],
            'fecha_pedido' => ['required','exists:order_dates,id']
        ];
    }

    public function addSedeFilter($sede_id){
        $indice = array_search($sede_id,$this->selectedSedes,true);
        if($indice != "" && $indice >= 0){
            unset($this->selectedSedes[$indice]);
        }else{
            array_push($this->selectedSedes,$sede_id);
        }
        $this->resetPage();
    }

    public function updatedOpenImportStock(){
        if(!$this->open_import_stock){
            $this->iteration++;
        }
    }

    public function importarStock(){
        $this->validate();

        Excel::import(new GeneralStockImport, $this->stock);
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

        $general_stock_details = $general_stock_details->select('general_stock_details.id','items.item','items.type','general_stock_details.quantity','general_stock_details.price','sedes.sede','general_stock_details.order_date_id')
                                                        ->orderBy('id','DESC')
                                                        ->paginate(5);

        $order_dates = OrderDate::join('order_requests',function($join){
            $join->on('order_requests.order_date_id','order_dates.id');
        })->where('order_requests.state','EN PROCESO')
            ->select('order_dates.id','order_dates.order_date')
            ->groupBy('order_dates.id')
            ->get();

        return view('livewire.insert-material',compact('general_stock_details','sedes','order_dates'));
    }
}
