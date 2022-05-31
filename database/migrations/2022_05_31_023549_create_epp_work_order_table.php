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
        Schema::create('epp_work_order', function (Blueprint $table) {
            $table->id();
            $table->foreignId('epp_id')->constrained();
            $table->foreignId('work_order')->constrained();
            $table->timestamps();
            $table->index(['epp_id','work_order']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('epp_work_order');
    }
};
