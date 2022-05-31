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
        Schema::create('epp_risk', function (Blueprint $table) {
            $table->id();
            $table->foreignId('epp_id')->constrained();
            $table->foreignId('risk_id')->constrained();
            $table->timestamps();
            $table->index(['epp_id','risk_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('epp_risk');
    }
};
