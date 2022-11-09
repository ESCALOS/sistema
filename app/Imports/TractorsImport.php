<?php
namespace App\Imports;

use App\Models\Location;
use App\Models\Sede;
use App\Models\TractorModel;
use App\Models\Tractor;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class TractorsImport implements ToCollection
{
    public function __construct() {
        $this->sedes = Sede::pluck('id','sede');
    }

    public function collection(Collection $rows)
    {
        foreach ($rows as $row)
        {
            if($row[6] != 'SEDE'){
                if(TractorModel::where('model',$row[2])->doesntExist()){
                    TractorModel::create([
                        'tractor_model' => $row[3],
                        'model' => $row[2]
                    ]);
                }

                Tractor::create([
                    'tractor_model_id' => TractorModel::where('model',$row[2])->first()->id,
                    'tractor_number' => $row[1],
                    'motor' => $row[4],
                    'serie' => $row[5],
                    'hour_meter' => 0,
                    'location_id' => Location::where('sede_id',$this->sedes[$row[6]])->first()->id,
                ]);
            }
        }
    }
}
