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
        Schema::create('operator_stock_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->enum('movement',['INGRESO','SALIDA']);
            $table->decimal('quantity',8,2);
            $table->decimal('price',8,2);
            $table->foreignId('warehouse')->constrained();
            $table->enum('state',['CONFIRMADO','ANULADO','LIBERADO']);
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
        Schema::dropIfExists('operator_stock_details');
    }
};
