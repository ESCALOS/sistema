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
        Schema::create('pre_stockpile_dates', function (Blueprint $table) {
            $table->id();
            $table->date('open_pre_stockpile');
            $table->date('close_pre_stockpile');
            $table->enum('state',['PENDIENTE','ABIERTO','CERRADO'])->default('PENDIENTE');
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
        Schema::dropIfExists('pre_stockpile_dates');
    }
};
