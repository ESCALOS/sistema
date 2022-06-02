<?php

namespace Database\Factories;

use App\Models\Item;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\MinStock>
 */
class MinStockFactory extends Factory
{
    protected $model = \App\Models\MinStock::class;

    public function definition()
    {
        return [
            'item_id' => Item::all()->random()->id,
            'warehouse_id' => \App\Models\Warehouse::all()->random()->id,
            'required_quantity' => $this->faker->randomNumber(2),
            'current_quantity' => 0,
            'price' => 0,
        ];
    }
}
