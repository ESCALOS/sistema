<?php

namespace App\Imports;

use App\Models\GeneralStockDetail;
use App\Models\Item;
use App\Models\OrderRequestDetail;
use App\Models\Sede;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\SkipsOnError;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class GeneralStockImport implements ToModel,WithHeadingRow,WithValidation,WithBatchInserts,WithChunkReading,SkipsOnError
{
    private $item;
    private $sede;
    private $order_date;

    public function __construct() {
        $this->item = Item::pluck('id','sku');
        $this->sede = Sede::pluck('id','code');
        $this->order_date = DB::table('importar_stock_log')->where('importar_stock_log.user_id',Auth::user()->id)->select('order_date_id')->orderBy('id','DESC')->first()->order_date_id;
    }

    public function onError(\Throwable $e)
    {
        // Handle the exception how you'd like.
    }


    public function model(array $row)
    {
        if(isset($row['codigo'])){
            return new GeneralStockDetail([
                'item_id' => $this->item[$row['codigo']],
                'quantity' => $row['cantidad'],
                'price' => OrderRequestDetail::join('order_requests',function($join){ $join->on('order_requests.id','order_request_details.order_request_id'); })->where('order_request_details.item_id',$this->item[$row['codigo']])->where('order_requests.order_date_id',$this->order_date)->first(),
                'sede_id' => $this->sede[$row['centro']],
                'order_date_id' => $this->order_date
            ]);
        }
    }

    public function batchSize(): int
    {
        return 2000;
    }

    public function chunkSize(): int
    {
        return 2000;
    }

    public function rules(): array
    {
        return [
            '*.codigo' => ['required','exists:items,sku'],
            '*.cantidad' => ['required','min:0.01'],
            '*.precio' => ['required','min:0.01'],
            '*.centro' => ['required','exists:sedes,code'],
        ];
    }

    public function customValidationMessages(){
        return[
            'codigo.exists' => 'El item no existe',
            'cantidad.min' => 'La cantidad debe ser mayor a 0',
            'precio.min' => 'El precio debe ser mayor a 0',
            'centro.exists' => 'No existe el centro',
        ];
    }
}
