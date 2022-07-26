<?php

namespace App\Imports;

use App\Models\Item;
use App\Models\MeasurementUnit;
use Maatwebsite\Excel\Concerns\SkipsOnError;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class ItemsImport implements ToModel, WithHeadingRow,WithValidation,WithBatchInserts,WithChunkReading,SkipsOnError
{
    private $measurement_unit;

    public function __construct() {
        $this->measurement_unit = MeasurementUnit::pluck('id','abbreviation');
    }

    public function onError(\Throwable $e)
    {
        // Handle the exception how you'd like.
    }

    public function model(array $row)
    {
        if(isset($row['codigo'])){
            return new Item([
                'sku' => $row['codigo'],
                'item' => $row['detalle'],
                'measurement_unit_id' => $this->measurement_unit[$row['unidad_de_medida']],
                'estimated_price' => $row['precio'],
                'type' => $row['tipo']
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
            '*.codigo' => ['required','unique:items,sku'],
            '*.detalle' => ['required','unique:items,item'],
            '*.unidad_de_medida' => ['required','exists:measurement_units,abbreviation'],
            '*.tipo' => ['required', 'in:COMPONENTE,PIEZA,FUNGIBLE,HERRAMIENTA']
        ];
    }

    public function customValidationMessages(){
        return[
            'codigo.unique' => 'Código repetido',
            'detalle.unique' => 'Detalle repetido',
            'unidad_de_medida.exists' => 'No existe la unidad de medida',
            'tipo.in' => 'El tipo no existe'
        ];
    }

}
