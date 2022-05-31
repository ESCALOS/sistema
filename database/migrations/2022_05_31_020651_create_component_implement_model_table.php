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
        Schema::create('component_implement_model', function (Blueprint $table) {
            $table->id();
            $table->foreignId('component_id')->constrained();
            $table->foreignId('implement_model_id')->constrained();
            $table->timestamps();
            $table->index(['component_id','implement_model_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('component_implement_model');
    }
};
