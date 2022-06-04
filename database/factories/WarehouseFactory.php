<?php

namespace Database\Factories;

use App\Models\Location;
use App\Models\Warehouse;
use Illuminate\Database\Eloquent\Factories\Factory;


class WarehouseFactory extends Factory
{
    protected $model = Warehouse::class;

    public function definition()
    {
        return [
            'code' => $this->faker->unique()->numerify('######'),
            'warehouse' => $this->faker->unique()->word(),
            'location_id' => Location::all()->random()->id,
        ];
    }
}