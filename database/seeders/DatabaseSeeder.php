<?php

namespace Database\Seeders;

use App\Models\Brand;
use App\Models\Ceco;
use App\Models\CecoAllocationAmount;
use App\Models\Component;
use App\Models\Crop;
use App\Models\Epp;
use App\Models\ImplementModel;
use App\Models\Item;
use App\Models\Labor;
use App\Models\Location;
use App\Models\MeasurementUnit;
use App\Models\MinStock;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Risk;
use App\Models\Sede;
use App\Models\Task;
use App\Models\TractorModel;
use App\Models\TractorReport;
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
        \App\Models\User::factory(30)->create();
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
        TractorModel::factory(5)->hasTractors(5)->create();
        TractorReport::factory(100)->create();
        Crop::factory(10)->create();
        Epp::factory(20)->create();
        OrderRequest::factory(100)->create();
        OrderRequestDetail::factory(100)->create();
        Task::factory(50)->create();
        Risk::factory(20)->create();
        Warehouse::factory(8)->create();
        WorkOrder::factory(50)->hasWorkOrderDetails(10)->create();
        MinStock::factory(20)->hasMinStockDetail(10)->create();
    }
}
