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
        Schema::create('component_part', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('component_implement_id');
            $table->foreign('component_implement_id')->references('id')->on('component_implement');
            $table->unsignedBigInteger('part');
            $table->foreign('part')->references('id')->on('components');
            $table->decimal('hours',8,2);
            $table->enum('state',['PENDIENTE','ORDENADO','CONCLUIDO']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('component_part');
    }
};
