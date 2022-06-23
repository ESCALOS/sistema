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
        Schema::create('order_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('implement_id')->constrained();
            $table->enum('state',['PENDIENTE','CERRADO','VALIDADO','RECHAZADO','CONCLUIDO'])->default('PENDIENTE');
            $table->decimal('estimated_price', 8, 2)->default(0);
            $table->unsignedBigInteger('validate_by')->nullable();
            $table->foreign('validate_by')->references('id')->on('users');
            $table->boolean('is_canceled')->default(false);
            $table->foreignId('order_date_id')->constrained();
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
        Schema::dropIfExists('order_requests');
    }
};
