<?php

use App\Http\Livewire\AssignMaterialsOperator;
use App\Http\Livewire\ValidatePreReserva;
use App\Http\Livewire\ValidateRequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/validar-pedidos',ValidateRequestMaterial::class)->name('planner.validate-request-materials');
Route::get('/asignar-materiales',AssignMaterialsOperator::class)->name('planner.assign-materials-operator');
Route::get('/validar-pre-reserva',ValidatePreReserva::class)->name('planner.validate-pre-reserva');
