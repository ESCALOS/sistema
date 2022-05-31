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
        Schema::create('risk_task_order', function (Blueprint $table) {
            $table->id();
            $table->foreignId('risk_id')->constrained();
            $table->foreignId('task_id')->constrained();
            $table->timestamps();
            $table->index(['risk_id','task_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('risk_task_order');
    }
};
