<?php

namespace Database\Factories;

use App\Models\Location;
use App\Models\Sede;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Location>
 */
class LocationFactory extends Factory
{
    protected $model = Location::class ;

    public function definition()
    {
        return [
            'code' => $this->faker->unique()->numerify('######'),
            'sede' => $this->faker->word(),
            'zone' => Sede::all()->random()->id(),
        ];
    }
}
