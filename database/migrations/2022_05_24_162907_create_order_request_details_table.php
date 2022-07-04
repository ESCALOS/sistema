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
        Schema::create('order_request_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_request_id')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->decimal('quantity',8,2);
            $table->decimal('estimated_price',8,2);
            $table->enum('state',['PENDIENTE','ACEPTADO','MODIFICADO','RECHAZADO','VALIDADO','INCOMPLETO','CONCLUIDO'])->default('PENDIENTE');
            $table->text('observation')->nullable();
            $table->decimal('assigned_quantity',8,2)->default(0);
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
        Schema::dropIfExists('order_request_details');
    }
};
