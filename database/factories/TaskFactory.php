<?php

namespace Database\Factories;

use App\Models\Implement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Task>
 */
class TaskFactory extends Factory
{
    protected $model = \App\Models\Task::class;

    public function definition()
    {
        return [
            'name' => $this->faker->unique()->sentence(),
            'implement_id' => Implement::all()->random()->id,
            'estiamted_time' => $this->faker->numberBetween(30,180),
        ];
    }
}
