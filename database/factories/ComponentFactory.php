<?php

namespace Database\Factories;

use App\Models\Component;
use App\Models\Item;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Component>
 */
class ComponentFactory extends Factory
{
    protected $model = Component::class;
    public function definition()
    {
        return [
            'item_id' => Item::all()->random()->id,
            'component' => $this->faker->unique()->word(),
            'is_part' => $this->faker->randomElement([0,1]),
            'lifespan' => $this->faker->randomElement([50,100,150,200,300,400,500,600,700,800]),
        ];
    }
}
