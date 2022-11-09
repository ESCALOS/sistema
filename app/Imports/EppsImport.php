<?php
namespace App\Imports;


use App\Models\Risk;
use App\Models\Epp;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class EppsImport implements ToCollection
{
    public function __construct() {
        
    }
    
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) 
        {
            if(strtoupper($row[0]) != 'RIESGO'){
                if(Risk::where('risk',strtoupper($row[0]))->doesntExist()){
                    $risk = Risk::create([
                        'risk' => strtoupper($row[0]),
                    ]);
                }
                
                if(Epp::where(strtoupper('epp'),$row[1])){
                    $epp = Epp::create([
                        'epp' => $row[1],
                        //'location_id' => Risk::where('risk',strtoupper($row[0]))->first()->id
                    ]);
                }
                
                
                
            }
        }
    }
}