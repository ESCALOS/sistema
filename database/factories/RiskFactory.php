<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Risk>
 */
class RiskFactory extends Factory
{
    protected $model = \App\Models\Risk::class;

    public function definition()
    {
        return [
            'risk' => $this->faker->unique()->sentence(),
        ];
    }
}
