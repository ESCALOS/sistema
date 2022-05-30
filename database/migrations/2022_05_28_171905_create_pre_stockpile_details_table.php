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
        Schema::create('pre_stockpile_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pre_stockpile')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->double('quantity');
            $table->double('precio');
            $table->foreignId('warehouse_id')->constrained();
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
        Schema::dropIfExists('pre_stockpile_details');
    }
};
