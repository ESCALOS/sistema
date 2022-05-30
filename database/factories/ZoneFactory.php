<?php

namespace Database\Factories;

use App\Models\Zone;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Zone>
 */
class ZoneFactory extends Factory
{
    protected $model = Zone::class;

    public function definition()
    {
        return [
            'code' => $this->faker->unique()->numerify('######'),
            'zone' => $this->faker->word(),
        ];
    }
}
