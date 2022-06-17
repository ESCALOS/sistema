<?php

namespace Database\Factories;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorReport;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\TractorReport>
 */
class TractorReportFactory extends Factory
{
    protected $model = TractorReport::class;

    public function definition()
    {
        $inicio = $this->faker->randomFloat(null,120,500);
        $fin = $this->faker->randomFloat(null,600,2000);
        return [
            'lote_id' => Lote::all()->random()->id,
            'user_id' => User::all()->random()->id,
            'tractor_id' => Tractor::all()->random()->id,
            'labor_id' => Labor::all()->random()->id,
            'correlative' => $this->faker->numerify('########'),
            'date' => $this->faker->date('Y-m-d','now'),
            'shift' => $this->faker->randomElement(['MAÑANA','NOCHE']),
            'implement_id' => Implement::all()->random()->id,
            'hour_meter_start' => $inicio,
            'hour_meter_end' => $fin,
            'hours' => $fin - $inicio,
            'observations' => $this->faker->sentence(8,true),
        ];
    }
}
