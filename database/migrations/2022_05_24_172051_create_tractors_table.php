<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('tractors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tractor_model_id')->constrained();
            $table->string('tractor_number',5);
            $table->decimal('hour_meter',8,2);
            $table->timestamps();
            $table->index(['tractor_model_id','tractor_number']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('tractors');
    }
};
