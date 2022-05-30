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
        Schema::create('ceco_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ceco_id')->constrained();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('implement_id')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->double('price');
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
        Schema::dropIfExists('ceco_details');
    }
};
