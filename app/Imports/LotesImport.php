<?php
namespace App\Imports;


use App\Models\Location;
use App\Models\Lote;
use App\Models\Sede;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class LotesImport implements ToCollection
{
    public function __construct() {
        $this->sedes = Sede::pluck('id','sede');
    }

    public function collection(Collection $rows)
    {
        foreach ($rows as $row)
        {
            if($row[3] != 'HAS'){
                if(Location::where('location',strtoupper($row[1]))->doesntExist()){
                    Location::create([
                        'location' => strtoupper($row[1]),
                        'sede_id' => $this->sedes[$row[0]]
                    ]);
                }

                if(Lote::where('lote',$row[2])){
                    Lote::create([
                        'lote' => $row[2],
                        'ha' => $row[3],
                        'location_id' => Location::where('location',strtoupper($row[1]))->first()->id
                    ]);
                }

            }
        }
    }
}
