<?php

namespace App\Imports;

use App\Models\Item;
use App\Models\MeasurementUnit;
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
        return new Item([
            'sku' => $row['codigo'],
            'item' => $row['detalle'],
            'measurement_unit_id' => MeasurementUnit::where('abbreviation','like',$row['unidad_de_medida'])->first()->id,
            'estimated_price' => $row['precio'],
            'type' => $row['tipo']
        ]);
    }

}
