<?php

namespace Database\Factories;

use App\Models\Ceco;
use App\Models\CecoAllocationAmount;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Model>
 */
class CecoAllocationAmountFactory extends Factory
{
    protected $model = CecoAllocationAmount::class;

    public function definition()
    {
        return [
            'ceco_id' => Ceco::all()->random()->id,
            'allocation_amount' => $this->faker->randomFloat(2,2000,4000),
            'date' => $this->faker->date('Y-m-d','now'),
        ];
    }
}
