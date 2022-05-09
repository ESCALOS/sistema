<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Zone;
use App\Models\Sede;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        \App\Models\User::factory(3)->create();

        $zone = new Zone();

        $zone->code = '01';
        $zone->zone = 'SUR';

        $zone->save();

        $zone2 = new Zone();

        $zone2->code = '02';
        $zone2->zone = 'NORTE';

        $zone2->save();
/*----------------------------------------------------------------*/

        $sede = new Sede();

        $sede->code = '01';
        $sede->sede = 'ICA';
        $sede->zone_id = '1';

        $sede->save();

        $sede2 = new Sede();

        $sede2->code = '02';
        $sede2->sede = 'CHINCHA';
        $sede2->zone_id = '1';
        
        $sede2->save();

        
        $sede3 = new Sede();

        $sede3->code = '03';
        $sede3->sede = 'PARACAS';
        $sede3->zone_id = '1';
        
        $sede3->save();


        $sede4 = new Sede();

        $sede4->code = '04';
        $sede4->sede = 'TRUJILLO';
        $sede4->zone_id = '2';
        
        $sede4->save();

        $sede5 = new Sede();

        $sede5->code = '05';
        $sede5->sede = 'CHICLAYO';
        $sede5->zone_id = '2';
        
        $sede5->save();
    }
}
