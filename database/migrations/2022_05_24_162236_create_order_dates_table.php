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
        Schema::create('order_dates', function (Blueprint $table) {
            $table->id();
            $table->date('open_request');#Fecha que se abre el pedido
            $table->date('close_request'); #Fecha que se cierra el pedido
            $table->date('order_date'); #Fecha que se hace el pedido
            $table->date('arrival_date'); #Fecha máxima de llegada
            $table->enum('state' ,['PENDIENTE','CERRADO'])->default('PENDIENTE');
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
        Schema::dropIfExists('order_dates');
    }
};
