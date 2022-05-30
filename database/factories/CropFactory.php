<?php

namespace Database\Factories;

use App\Models\Crop;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Crop>
 */
class CropFactory extends Factory
{
    protected $model = Crop::class;

    public function definition()
    {
        return [
            'crop' => $this->faker->unique()->word(),
        ];
    }
}
