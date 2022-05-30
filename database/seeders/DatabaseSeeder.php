<?php

namespace Database\Seeders;

use Database\Factories\BrandFactory;
use Database\Factories\CecoFactory;
use Database\Factories\LocationFactory;
use Database\Factories\SedeFactory;
use Database\Factories\ZoneFactory;
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
        ZoneFactory::factory(3)->create();
        SedeFactory::factory(8)->create();
        LocationFactory::factory(11)->create();
        BrandFactory::factory(30)->create();
        CecoFactory::factory(20)->create();
    }
}
