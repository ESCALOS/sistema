<?php

namespace App\Imports;

use App\Models\GeneralStockDetail;
use App\Models\Item;
use App\Models\OrderDate;
use App\Models\Sede;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class GeneralStockImport implements ToModel,WithHeadingRow
{
    /**
     * @param array $row
     *
     */
    public function model(array $row)
    {
        if(!isset($row['item_id'])){
            return new GeneralStockDetail([
                'item_id' => Item::where('sku',$row['codigo'])->first()->id,
                'quantity' => $row['cantidad'],
                'price' => $row['precio'],
                'sede_id' => Sede::where('code',$row['centro'])->first()->id,
                'order_date_id' => OrderDate::where('order_date','2022-05-02')->first()->id,
            ]);
        }
    }
}
