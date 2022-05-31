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
        Schema::create('component_system', function (Blueprint $table) {
            $table->id();
            $table->foreignId('component_id')->constrained();
            $table->foreignId('system_id')->constrained();
            $table->timestamps();
            $table->index(['component_id','system_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('component_system');
    }
};
