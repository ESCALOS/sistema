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
        Schema::create('affected_movement', function (Blueprint $table) {
            $table->id();
            $table->foreignId('operator_stock_id')->nullable()->constrained();
            $table->foreignId('operator_stock_detail_id')->nullable()->constrained();
            $table->foreignId('operator_assigned_stock_id')->nullable()->constrained();
            $table->foreignId('stock_id')->nullable()->constrained();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('affected_movement');
    }
};
