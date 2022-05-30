<?php

namespace Database\Factories;

use App\Models\Admin\Labor;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Labor>
 */
class LaborFactory extends Factory
{
    protected $model = Labor::class;

    public function definition()
    {
        return [
            'labor' => $this->faker->unique()->word(),
        ];
    }
}
