<?php

namespace Database\Factories;

use App\Models\Implement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\MinStockDetail>
 */
class MinStockDetailFactory extends Factory
{
    protected $model = \App\Models\MinStockDetail::class;

    public function definition()
    {
        return [
            'min_stock_id' => \App\Models\MinStock::all()->random()->id,
            'user_id' => \App\Models\User::all()->random()->id,
            'movement' => $this->faker->randomElement(['INGRESO','SALIDA']),
            'quantity' => $this->faker->randomNumber(2),
            'price' => $this->faker->randomElement([100,200,500,1000,1500]),
            'implement' => Implement::all()->random()->id,
        ];
    }
}
