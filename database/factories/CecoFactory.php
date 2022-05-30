<?php

namespace Database\Factories;

use App\Models\Ceco;
use App\Models\Location;
use Illuminate\Database\Eloquent\Factories\Factory;

class CecoFactory extends Factory
{
    protected $model = Ceco::class;

    public function definition()
    {
        return [
            'code' => $this->faker->unique()->numerify('######'),
            'description' => $this->faker->word(),
            'location_id' => Location::all()->random()->id,
            'amount' => 0,
        ];
    }
}
