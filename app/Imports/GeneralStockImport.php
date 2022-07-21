<?php

namespace App\Imports;

use App\Models\GeneralStockDetail;
use App\Models\Item;
use App\Models\Sede;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class GeneralStockImport implements ToModel,WithHeadingRow
{
    /**
    * @param array $row
    *
    * @return \Illuminate\Database\Eloquent\Model|null
    */
    public function model(array $row)
    {   
        return new GeneralStockDetail([
            'item_id' => Item::where('sku',$row['sku'])->first()->id,
            'quantity' => $row['cantidad'],
            'price' => $row['precio'],
            'sede_id' => Sede::where('code',$row['centro'])->first()->id,
        ]);
    }
}
