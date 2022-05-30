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
        Schema::create('stockpile_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stockpile_id')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->double('quantity');
            $table->double('price');
            $table->foreignId('warehouse_id')->constrained();
            $table->enum('state',['PENDIENTE','VALIDADO','RECHAZADO','ANULADO']);
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
        Schema::dropIfExists('stockpile_details');
    }
};
