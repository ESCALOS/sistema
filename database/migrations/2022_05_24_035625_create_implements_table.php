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
        Schema::create('implements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('implement_model_id')->constrained();
            $table->string('implement_number',5);
            $table->double('hours');
            $table->foreignId('user_id')->constrained();
            $table->timestamps();
            $table->index(['implement_model_id','implement_number']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('implements');
    }
};
