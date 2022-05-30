<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\OrderRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\OrderRequest>
 */
class OrderRequestFactory extends Factory
{
    protected $model = OrderRequest::class;

    public function definition()
    {
        return [
            'user_id' => User::all()->random()->id,
            'implement_id' => Implement::all()->random()->id,
            'state' => $this->faker->randomElement(['PENDIENTE','CERRADO','VALIDADO','RECHAZADO']),
            'validate_by' => User::all()->random()->id,
        ];
    }
}
