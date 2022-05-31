<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Ceco;
use App\Models\CecoAllocationAmount;
use App\Models\ImplementModel;
use App\Models\Item;
use App\Models\Labor;
use App\Models\Location;
use App\Models\MeasurementUnit;
use App\Models\Sede;
use App\Models\TractorModel;
use App\Models\TractorReport;
use App\Models\Zone;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        \App\Models\User::factory(30)->create();
        Zone::factory(3)->create();
        Sede::factory(8)->create();
        Location::factory(11)->create();
        Brand::factory(30)->create();
        MeasurementUnit::factory(50)->create();
        Ceco::factory(20)->create();
        CecoAllocationAmount::factory(20)->create();
        Item::factory(100)->create();
        ImplementModel::factory(3)->hasImplements(5)->create();
        //ImplementModel::factory(2)->has(Component::factory()->count(5));
        Labor::factory(6)->create();
        TractorModel::factory(5)->hasTractors(5)->create();
        TractorReport::factory(100)->create();
    }
}
