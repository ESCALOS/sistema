<?php

use App\Http\Livewire\TractorScheduling;
use App\Http\Livewire\ValidateWorkOrder;
use App\Models\Tractor;
use Illuminate\Support\Facades\Route;


Route::get('/Programacion-Tractores',TractorScheduling::class)->name('overseer.tractor-scheduling');
Route::get('/Orden-de-Trabajo-Pendientes',ValidateWorkOrder::class)->name('overseer.validate-work-order');


