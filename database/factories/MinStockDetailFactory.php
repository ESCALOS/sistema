<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\Item;
use App\Models\MinStockDetail;
use App\Models\User;
use App\Models\Warehouse;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\MinStockDetail>
 */
class MinStockDetailFactory extends Factory
{
    protected $model = MinStockDetail::class;

    public function definition()
    {
        return [
            'item_id' => Item::all()->random()->id,
            'warehouse_id' => Warehouse::all()->random()->id,
            'user_id' => User::all()->random()->id,
            'movement' => $this->faker->randomElement(['INGRESO','SALIDA']),
            'quantity' => $this->faker->randomNumber(2),
            'price' => $this->faker->randomElement([100,200,500,1000,1500]),
            'implement_id' => Implement::all()->random()->id,
        ];
    }
}
