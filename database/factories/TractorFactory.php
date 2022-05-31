<?php

namespace Database\Factories;

use App\Models\Tractor;
use App\Models\TractorModel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Tractor>
 */
class TractorFactory extends Factory
{
    protected $model = Tractor::class;

    public function definition()
    {
        return [
            'tractor_model_id' => TractorModel::all()->random()->id,
            'tractor_number' => $this->faker->numerify('#####'),
            'hour_meter' => $this->faker->numberBetween(16,500),
        ];
    }
}
