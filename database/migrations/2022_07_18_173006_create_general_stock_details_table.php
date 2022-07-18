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
        Schema::create('general_stock_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_id')->constrained();
            $table->enum('movement',['INGRESO','SALIDA'])->default('INGRESO');
            $table->decimal('quantity',8,2)->default(8,2);
            $table->decimal('price',8,2)->default(8,2);
            $table->foreignId('general_warehouse_id')->constrained();
            $table->boolean('is_canceled')->default(0);
            $table->foreignId('order_date_id')->nullable()->constrained();
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
        Schema::dropIfExists('general_stock_details');
    }
};
