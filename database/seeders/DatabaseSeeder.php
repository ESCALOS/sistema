<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Ceco;
use App\Models\CecoAllocationAmount;
use App\Models\Component;
use App\Models\Crop;
use App\Models\Epp;
use App\Models\Implement;
use App\Models\ImplementModel;
use App\Models\Item;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\MeasurementUnit;
use App\Models\MinStock;
use App\Models\MinStockDetail;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Risk;
use App\Models\Sede;
use App\Models\Task;
use App\Models\Tractor;
use App\Models\TractorModel;
use App\Models\TractorReport;
use App\Models\TractorScheduling;
use App\Models\User;
use App\Models\Warehouse;
use App\Models\WorkOrder;
use App\Models\Zone;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $faker = Faker::create();

        Zone::factory(2)->has(Sede::factory()->count(2)->has(Location::factory()->count(2)->has(Lote::factory()->count(2))->has(User::factory()->count(2))->has(Ceco::factory()->count(2))))->create();
        Brand::factory(30)->create();
        MeasurementUnit::factory(50)->create();
        Crop::factory(10)->create();
        Warehouse::factory(8)->create();
        Epp::factory(20)->create();
        Risk::factory(20)->create();

        for($j = 7; $j <= 12; $j++){
            $fecha = "2022-".$j."-01";
            for($i = 1; $i <=10;$i++){
                CecoAllocationAmount::factory(1)->create([
                    'ceco_id' => $i,
                    'allocation_amount' => $faker->numberBetween(1000,3000),
                    'date' => $fecha
                ]);
            }
        }

        Item::factory(60)->create();
        ImplementModel::factory(4)->hasImplements(4)->create();
        Task::factory(40)->create();
        Labor::factory(6)->create();
        TractorModel::factory(4)->hasTractors(4)->create();

        $componentes = Component::where('is_part', 0)->get();
        $partes = Component::where('is_part',1)->get();
        for($i=1;$i<=4;$i++){
            $implement_model = ImplementModel::find($i);
            $implement_model->components()->attach($componentes->random()->id);
            $implement_model->components()->attach($componentes->random()->id);
            $implement_model->components()->attach($componentes->random()->id);
        }

        foreach($componentes as $componente){
            for($i=0;$i<3;$i++){
                $componente->parts()->attach($partes->random()->id);
            }
        }

        $this->call(RoleSeeder::class);
        $this->call(OrderDateSeeder::class);

        /*TractorScheduling::factory(50)->create();
        TractorReport::factory(50)->create();
        OrderRequest::factory(50)->create();
        OrderRequestDetail::factory(50)->create();
        WorkOrder::factory(50)->hasWorkOrderDetails(10)->create();
        MinStockDetail::factory(10)->create();*/
    }
}
