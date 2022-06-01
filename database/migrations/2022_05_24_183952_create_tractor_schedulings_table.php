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
        Schema::create('tractor_schedulings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('labor_id')->constrained();
            $table->foreignId('tractor_id')->constrained();
            $table->foreignId('implement_id')->constrained();
            $table->date('date');
            $table->enum('shift',['MAÑANA','NOCHE']);
            $table->foreignId('location_id')->constrained();
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
        Schema::dropIfExists('tractor_schedulings');
    }
};
