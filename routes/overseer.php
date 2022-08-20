<?php

use App\Http\Livewire\RoutineTask;
use App\Http\Livewire\TractorScheduling;
use App\Http\Livewire\ValidateRoutineTask;
use App\Http\Livewire\ValidateWorkOrder;
use Illuminate\Support\Facades\Route;

Route::get('/Programacion-Tractores',TractorScheduling::class)->name('overseer.tractor-scheduling');
Route::get('/Orden-de-Trabajo-Pendientes',ValidateWorkOrder::class)->name('overseer.validate-work-order');
Route::get('/Registro-de-Rutinarios',RoutineTask::class)->name('overseer.routine-task');
Route::get('/Registrar-de-Rutinarios',ValidateRoutineTask::class)->name('overseer.validate-routine-task');