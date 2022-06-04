<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Tractor;
use App\Models\TractorScheduling;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\TractorScheduling>
 */
class TractorSchedulingFactory extends Factory
{
    protected $model = TractorScheduling::class;

    public function definition()
    {
        return [
            'user_id' => User::all()->random()->id,
            'labor_id' => Labor::all()->random()->id,
            'tractor_id' => Tractor::all()->random()->id,
            'implement_id' => Implement::all()->random()->id,
            'date' => $this->faker->date('Y-m-d','now'),
            'shift' => $this->faker->randomElement(['MAÑANA','NOCHE']),
            'location_id' => Location::all()->random()->id,
        ];
    }
}
