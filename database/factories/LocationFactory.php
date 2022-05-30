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
            'location' => $this->faker->word(),
            'sede_id' => Sede::all()->random()->id,
        ];
    }
}
