<?php

namespace App\Imports;

use App\Models\GeneralStockDetail;
use App\Models\Item;
use App\Models\OrderDate;
use App\Models\Sede;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class GeneralStockImport implements ToModel,WithHeadingRow,WithValidation,WithBatchInserts,WithChunkReading
{
    use Importable;

    private $item;
    private $sede;

    public function __construct() {
        $this->item = Item::pluck('id','sku');
        $this->sede = Sede::pluck('id','code');
        $this->order_date = OrderDate::pluck('id','order_date');
    }

    public function model(array $row)
    {

        if(!isset($row['cantidad']) || $row['cantidad'] == 0){
            return null;
        }

        return new GeneralStockDetail([
            'item_id' => $this->item[$row['codigo']],
            'quantity' => $row['cantidad'],
            'price' => $row['precio'],
            'sede_id' => $this->sede[$row['centro']],
            'order_date_id' => $this->order_date[$row['pedido']],
        ]);
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
            '*.cantidad' => ['exclude_if:*.cantidad,,null|lte:*.pendiente'],
            '*.precio' => ['numeric','min:0.01'],
            '*.centro' => ['required','exists:sedes,code'],
        ];
    }

    public function customValidationMessages(){
        return[
            'codigo.exists' => 'El item no existe',
            'cantidad.required' => 'Ingrese 0 en la cantidad',
            'cantidad.min' => 'Elimine la fila si no hay cantidad',
            'precio.min' => 'El precio debe ser mayor a 0',
            'centro.exists' => 'No existe el centro',
        ];
    }
}
