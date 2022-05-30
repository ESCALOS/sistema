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
        Schema::create('risk_epps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('risk_id')->constrained();
            $table->foreignId('epp_id')->constrained();
            $table->timestamps();
            $table->index(['risk_id','epp_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('risk_epps');
    }
};
