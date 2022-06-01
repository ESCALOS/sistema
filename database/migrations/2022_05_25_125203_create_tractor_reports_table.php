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
        Schema::create('tractor_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->foreignId('tractor_id')->constrained();
            $table->foreignId('labor_id')->constrained();
            $table->string('correlative',30);
            $table->date('date');
            $table->enum('shift',['MAÑANA','NOCHE']);
            $table->foreignId('implement_id')->constrained();
            $table->decimal('hour_meter_start',8,2);
            $table->decimal('hour_meter_end',8,2);
            $table->decimal('hours',8,2);
            $table->text('observations');
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
        Schema::dropIfExists('tractor_reports');
    }
};
