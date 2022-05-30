<?php

namespace Database\Factories;

use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Sede>
 */
class SedeFactory extends Factory
{
    protected $model = Sede::class;

    public function definition()
    {
        return [
            'code' => $this->faker->unique()->numerify('######'),
            'sede' => $this->faker->word(),
            'zone' => Zone::all()->random()->id(),
        ];
    }
}
