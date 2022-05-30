<?php

namespace Database\Factories;

use App\Models\MeasurementUnit;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\MeasurementUnit>
 */
class MeasurementUnitFactory extends Factory
{
    protected $model = MeasurementUnit::class;

    public function definition()
    {
        return [
            'measurement_unit' => $this->faker->unique()->word(),
            'abbrevition' => $this->faker->unique()->lexify('???')
        ];
    }
}
