<?php

namespace Database\Factories;

use App\Models\Risk;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Risk>
 */
class RiskFactory extends Factory
{
    protected $model = Risk::class;

    public function definition()
    {
        return [
            'risk' => $this->faker->unique()->sentence(),
        ];
    }
}
