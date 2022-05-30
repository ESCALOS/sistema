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
            $table->foreignId('min_stock_id')->constrained();
            $table->foreignId('user_id')->constrained();
            $table->enum('movement',['INGRESO','SALIDA'])->constrained();
            $table->double('quantity')->constrained();
            $table->double('price')->constrained();
            $table->foreignId('implement_id')->constrained()->nullable();
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
