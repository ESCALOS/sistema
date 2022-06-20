<?php

namespace Database\Seeders;

use App\Models\OrderDate;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class OrderDateSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $may = OrderDate::create([
            'open_request' => '2020-04-25',
            'close_request' => '2020-04-28',
            'order_date' => '2020-05-02',
            'arrival_date' => '2020-07-01',
            'state' => 'PENDIENTE',
        ]);

        $july = OrderDate::create([
            'open_request' => '2020-06-27',
            'close_request' => '2020-06-30',
            'order_date' => '2020-07-04',
            'arrival_date' => '2020-09-01',
            'state' => 'PENDIENTE',
        ]);

        $september = OrderDate::create([
            'open_request' => '2020-08-29',
            'close_request' => '2020-09-01',
            'order_date' => '2020-09-05',
            'arrival_date' => '2020-11-01',
            'state' => 'PENDIENTE',
        ]);

        $november = OrderDate::create([
            'open_request' => '2020-12-26',
            'close_request' => '2020-12-29',
            'order_date' => '2020-01-02',
            'arrival_date' => '2020-02-01',
            'state' => 'PENDIENTE',
        ]);
    }
}
