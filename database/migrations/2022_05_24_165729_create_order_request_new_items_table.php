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
        Schema::create('order_request_new_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_request_id')->constrained();
            $table->string('new_item');
            $table->decimal('quantity',8,2);
            $table->foreignId('measurement_unit_id')->constrained();
            $table->string('brand');
            $table->text('datasheet');
            $table->string('image',2048)->nullable();
            $table->enum('state',['PENDIENTE','CREADO','RECHAZADO'])->default('PENDIENTE');
            $table->foreignId('item_id')->nullable()->constrained();
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
        Schema::dropIfExists('order_request_new_items');
    }
};
