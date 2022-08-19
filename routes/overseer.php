<?php

use App\Http\Livewire\TractorScheduling;
use App\Http\Livewire\ValidateWorkOrder;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use Illuminate\Support\Facades\Route;



Route::get('/Programacion-Tractores',TractorScheduling::class)->name('overseer.tractor-scheduling');
Route::get('/Orden-de-Trabajo-Pendientes',ValidateWorkOrder::class)->name('overseer.validate-work-order');
Route::get('/Formato-programacion',function(){
    $fecha = "2022-08-18";
    $schedule = ModelsTractorScheduling::where('date',$fecha)->get();
    return view('pdf.tractor-scheduling',compact('schedule','fecha'));
});


