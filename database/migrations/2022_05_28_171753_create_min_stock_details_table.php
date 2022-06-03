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
        Schema::create('min_stock_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_id')->constrained();
            $table->foreignId('warehouse_id')-> constrained();
            $table->foreignId('user_id')->constrained();
            $table->enum('movement',['INGRESO','SALIDA'])->constrained();
            $table->decimal('quantity',8,2);
            $table->decimal('price',8,2);
            $table->foreignId('implement_id')->nullable();
            $table->boolean('is_canceled')->default(0);
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
        Schema::dropIfExists('min_stock_details');
    }
};
