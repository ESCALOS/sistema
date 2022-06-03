<?php

namespace Database\Factories;

use App\Models\Item;
use App\Models\MinStock;
use App\Models\Warehouse;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\MinStock>
 */
class MinStockFactory extends Factory
{
    protected $model = MinStock::class;

    public function definition()
    {
        return [
            'item_id' => Item::all()->random()->id,
            'warehouse_id' => Warehouse::all()->random()->id,
            'required_quantity' => $this->faker->randomNumber(2),
            'current_quantity' => 0,
            'price' => 0,
        ];
    }
}
