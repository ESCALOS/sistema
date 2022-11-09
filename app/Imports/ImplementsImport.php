<?php
namespace App\Imports;

use App\Models\Ceco;
use App\Models\Location;
use App\Models\Sede;
use App\Models\ImplementModel;
use App\Models\Implement;
use App\Models\User;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class ImplementsImport implements ToCollection
{
    public function __construct() {
        $this->sedes = Sede::pluck('id','sede');
    }
    
    public function collection(Collection $rows)
    {
        foreach ($rows as $row) 
        {
            if($row[2] != 'SEDE'){
                if(ImplementModel::where('implement_model',$row[0])->doesntExist()){
                    ImplementModel::create([
                        'implement_model' => $row[0]
                    ]);
                }

                if(Ceco::where('code',$row[5])->doesntExist()){
                    Ceco::create([
                        'code' => $row[5],
                        'location_id' => Location::where('sede_id',$this->sedes[$row[2]])->first()->id
                    ]);
                }
                
                Implement::create([
                    'implement_model_id' => ImplementModel::where('implement_model',$row[0])->first()->id,
                    'implement_number' => $row[1],
                    'hours' => 0,
                    'user_id' => User::where('code',$row[3])->first()->id,
                    'location_id' => Location::where('sede_id',$this->sedes[$row[2]])->first()->id,
                    'ceco_id' => Ceco::where('code',$row[5])->first()->id
                ]);
            }
            
        }
    }
}