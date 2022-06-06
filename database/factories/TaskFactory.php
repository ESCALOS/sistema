<?php

namespace Database\Factories;

use App\Models\Component;
use App\Models\Task;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Task>
 */
class TaskFactory extends Factory
{
    protected $model = Task::class;

    public function definition()
    {
        return [
            'task' => $this->faker->unique()->sentence(),
            'component_id' => Component::all()->random()->id,
            'estimated_time' => $this->faker->numberBetween(30,180),
        ];
    }
}
