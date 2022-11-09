<?php

use App\Http\Livewire\Overseer\RoutineTask\RoutineTask;
use App\Http\Livewire\Overseer\TractorScheduling\TractorScheduling;
use App\Http\Livewire\Overseer\RoutineTask\ValidateRoutineTask;
use App\Http\Livewire\Overseer\WorkOrder\ValidateWorkOrder;
use Illuminate\Support\Facades\Route;

Route::get('/Programacion-Tractores',TractorScheduling::class)->name('overseer.tractor-scheduling');
Route::get('/Orden-de-Trabajo-Pendientes',ValidateWorkOrder::class)->name('overseer.validate-work-order');
Route::get('/Registro-de-Rutinarios',RoutineTask::class)->name('overseer.routine-task');
Route::get('/Registrar-Rutinarios',ValidateRoutineTask::class)->name('overseer.validate-routine-task');
