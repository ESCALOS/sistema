<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\Location;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\WorkOrder>
 */
class WorkOrderFactory extends Factory
{
    protected $model = \App\Models\WorkOrder::class;

    public function definition()
    {
        return [
            'implement_id' => Implement::all()->random()->id,
            'user_id' => User::all()->random()->id,
            'location_id' => Location::all()->random()->id,
            'estimated_price' => 0,
            'maintenance' => $this->faker-> randomElement([1,2,3]),
            'state' => "PENDIENTE",
        ];
    }
}
