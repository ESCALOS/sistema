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
        Schema::create('work_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('implement_id')->constrained();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('location_id')->constrained();
            $table->decimal('estimated_price',8,2)->default(0);
            $table->enum('maintenance',[1,2,3]);
            $table->enum('state',['PENDIENTE','VALIDADO','RECHAZADO']);
            $table->boolean('is_canceled')->default(false);
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
        Schema::dropIfExists('work_orders');
    }
};
