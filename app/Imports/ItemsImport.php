<?php

namespace App\Imports;

use App\Models\Item;
use App\Models\MeasurementUnit;
use Illuminate\Validation\Rule;
use Maatwebsite\Excel\Concerns\ToModel;

use Maatwebsite\Excel\Concerns\WithHeadingRow;

class ItemsImport implements ToModel, WithHeadingRow
{
    /**
    * @param array $row
    *
    * @return \Illuminate\Database\Eloquent\Model|null
    */
    public function model(array $row)
    {
        if(isset($row['codigo'])){
            return new Item([
                'sku' => $row['codigo'],
                'item' => $row['detalle'],
                'measurement_unit_id' => MeasurementUnit::where('abbreviation','like','UN')->first()->id,
                'estimated_price' => $row['precio'],
                'type' => $row['tipo']
            ]);
        }
    }

}
