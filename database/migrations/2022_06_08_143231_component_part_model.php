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
        Schema::create('component_part_model', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('component');
            $table->foreign('component')->references('id')->on('components');
            $table->unsignedBigInteger('part');
            $table->foreign('part')->references('id')->on('components');
            $table->timestamps();
            $table->index(['component','part']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('component_part_model');
    }
};