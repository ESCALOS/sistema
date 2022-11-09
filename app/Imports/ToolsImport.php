<?php
namespace App\Imports;

use App\Models\Item;
use App\Models\Location;
use App\Models\MeasurementUnit;
use App\Models\Sede;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Concerns\ToCollection;

class ToolsImport implements ToCollection
{
    public function __construct() {
        $this->locations = Location::pluck('id','location');
        //$this->sedes = Sede::pluck('id','sede');
        //$this->users = Users::pluck('id','code');
    }

    public function collection(Collection $rows)
    {
        foreach ($rows as $row)
        {
            if(strtoupper($row[2]) != 'HERRAMIENTA'){
                if(MeasurementUnit::where('abbreviation',$row[7])->doesntExist()){
                    MeasurementUnit::create([
                        'measurement_unit' =>  $row[7],
                        'abbreviation' => $row[7]
                    ]);
                }

                if(Item::where('sku',$row[1])->doesntExist()){
                    Item::create([
                        'sku' => strtoupper($row[1]),
                        'item' => $row[2],
                        'measurement_unit_id' => MeasurementUnit::where('abbreviation',$row[7])->first()->id,
                        'estimated_price' => 0,
                        'type' => 'HERRAMIENTA',
                    ]);
                }

                if(DB::table('tool_for_location')->where('item_id',Item::where('sku',$row[1]))->where('location_id',)->where('user_id',)->doesntExis()){
                    DB::table('tool_for_location')->insert([
                        'item_id' => Item::where('sku')->first()->id,
                        'location_id' => Location::where('location')->first()->id,
                        'quantity' => $row[6],
                        'measurement_unit' => MeasurementUnit::where('abbreviation',$row[7])
                    ]);
                }

            }
        }
    }
}
