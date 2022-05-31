<?php

namespace Database\Factories;

use App\Models\Brand;
use App\Models\Item;
use App\Models\MeasurementUnit;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Factory>
 */
class ItemFactory extends Factory
{
    protected $model = Item::class;

    public function definition()
    {
        return [
            'sku' => $this->faker->unique()->numerify('########'),
            'item' => $this->faker->unique()->lexify('????????'),
            'brand_id' => Brand::all()->random()->id,
            'measurement_unit_id' => MeasurementUnit::all()->random()->id,
            'estimated_price' => $this->faker->randomFloat($nbMaxDecimals=2,$min=300,$max=1500),
            'type' => $this->faker->randomElement(['FUNGIBLE','COMPONENTE','PIEZA','HERRAMIENTA']),
            'is_active' => $this->faker->randomElement([0,1]),
        ];
    }
}
