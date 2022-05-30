<?php

namespace Database\Factories;

use App\Models\Epp;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Epp>
 */
class EppFactory extends Factory
{
    protected $model = Epp::class;

    public function definition()
    {
        return [
            'epp' => $this->faker->unique()->word(),
        ];
    }
}
