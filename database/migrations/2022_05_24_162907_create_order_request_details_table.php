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
        Schema::create('order_request_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_request_id')->constrained();
            $table->foreignId('item_id')->constrained();
            $table->decimal('quantity',8,2);
            $table->enum('state',['PENDIENTE','VALIDADO','CONFIRMADO']);
            $table->text('observation');
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
        Schema::dropIfExists('order_request_details');
    }
};
