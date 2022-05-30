<?php

namespace Database\Factories;

use App\Models\Item;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\OrderRequestDetail>
 */
class OrderRequestDetailFactory extends Factory
{
    protected $model = OrderRequestDetail::class;

    public function definition()
    {
        return [
            'order_request_id' => OrderRequest::all()->random()->id,
            'item_id' => Item::all()->random()->id,
            'quantity' => $this->faker->randomFloat(4,0,300),
            'state' => $this->faker->randomElement(['PENDIENTE','VALIDADO','CONFIRMADO']),
            'observation' => $this->faker->realText($maxNbChars = 200, $indexSize = 2),
        ];
    }
}
