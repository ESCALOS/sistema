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
        Schema::create('ceco_allocation_amounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ceco_id')->constrained();
            $table->decimal('allocation_amount',8,2);
            $table->boolean('is_allocated')->default(false);
            $table->date('date');
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
        Schema::dropIfExists('ceco_allocationamounts');
    }
};
