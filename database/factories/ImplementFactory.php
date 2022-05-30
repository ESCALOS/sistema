<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\ImplementModel;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Implement>
 */
class ImplementFactory extends Factory
{
    protected $model = Implement::class;

    public function definition()
    {
        return [
            'implement_model_id' => ImplementModel::all()->random()->id,
            'implement_number' => $this->faker->unique()->numerify('####'),
            'hours' => $this->faker->randomFloat($nbMaxDecimals=2,$min=8,$max=100),
            'user_id' => User::all()->random()->id,
        ];
    }
}
