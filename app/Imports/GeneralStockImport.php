<?php

namespace App\Imports;

use App\Models\GeneralStockDetail;
use App\Models\Item;
use App\Models\OrderDate;
use App\Models\Sede;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithMappedCells;

class GeneralStockImport implements ToModel,WithHeadingRow,WithMappedCells
{
    public function mapping(): array
    {
        return [
            'fecha_pedido' => 'G1'
        ];
    }
    public function model(array $row)
    {
        return new GeneralStockDetail([
            'item_id' => Item::where('sku',$row['sku'])->first()->id,
            'quantity' => $row['cantidad'],
            'price' => $row['precio'],
            'sede_id' => Sede::where('code',$row['centro'])->first()->id,
            'order_date_id' => OrderDate::where('order_date',$row['fecha_pedido'])->first()->id,
        ]);
    }
}
