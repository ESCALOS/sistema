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
use App\Models\MeasurementUnit;
use App\Models\MinStock;
use App\Models\MinStockDetail;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Risk;
use App\Models\Sede;
use App\Models\Task;
use App\Models\Tractor;
use App\Models\TractorModel;
use App\Models\TractorReport;
use App\Models\TractorScheduling;
use App\Models\Warehouse;
use App\Models\WorkOrder;
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
        /*\App\Models\User::factory(30)->create();
        Zone::factory(3)->create();
        Sede::factory(8)->create();
        Location::factory(11)->create();
        Brand::factory(30)->create();
        MeasurementUnit::factory(50)->create();
        Ceco::factory(10)->hasCecoAllocationAmount(10)->create();
        Item::factory(100)->create();
        ImplementModel::factory(3)->hasImplements(5)->create();
        Component::factory(5)->create();
        Labor::factory(6)->create();
        

        for($i=1;$i<=3;$i++){
            $implement_model = ImplementModel::find($i);
            $implement_model->components()->attach(1);
            $implement_model->components()->attach(2);
            $implement_model->components()->attach(3);
            $implement_model->components()->attach(4);
            $implement_model->components()->attach(5);
        }

        for($i=1;$i<=5;$i++){
            $implement = Implement::find($i);
            $implement->components()->attach(1);
            $implement->components()->attach(2);
            $implement->components()->attach(3);
            $implement->components()->attach(4);
            $implement->components()->attach(5);
        }*/
        TractorModel::factory(3)->create();
        Tractor::factory(10)->create();
        TractorScheduling::factory(50)->create();
        TractorReport::factory(50)->create();
        Crop::factory(10)->create();
        Epp::factory(20)->create();
        OrderRequest::factory(50)->create();
        OrderRequestDetail::factory(50)->create();
        Task::factory(50)->create();
        Risk::factory(20)->create();
        Warehouse::factory(8)->create();
        WorkOrder::factory(50)->hasWorkOrderDetails(10)->create();
        MinStockDetail::factory(10)->create();
    }
}
