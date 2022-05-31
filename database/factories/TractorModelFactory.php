<?php

namespace Database\Factories;

use App\Models\TractorModel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\TractorModel>
 */
class TractorModelFactory extends Factory
{
    protected $model = TractorModel::class;

    public function definition()
    {
        return [
            'model' => $this->faker->lexify('???????'),
        ];
    }
}
