<?php

namespace Database\Factories;

use App\Models\ImplementModel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\ImplementModel>
 */
class ImplementModelFactory extends Factory
{
    protected $model = ImplementModel::class;

    public function definition()
    {
        return [
            'implement_model' => $this->faker->unique()->word(),
        ];
    }
}
