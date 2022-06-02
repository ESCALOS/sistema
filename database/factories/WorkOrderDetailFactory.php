<?php

namespace Database\Factories;

use App\Models\Task;
use App\Models\WorkOrder;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\WorkOrderDetail>
 */
class WorkOrderDetailFactory extends Factory
{
    protected $model = \App\Models\WorkOrderDetail::class;

    public function definition()
    {
        return [
            'work_order_id' => WorkOrder::all()->random()->id,
            'task_id' => Task::all()->random()->id,
            'observation' => $this->faker->sentence,
        ];
    }
}
