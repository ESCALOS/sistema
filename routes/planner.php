<?php

use App\Http\Livewire\ImportarDatos;
use App\Http\Livewire\InsertMaterial;
use App\Http\Livewire\ValidatePreReserva;
use App\Http\Livewire\ValidateRequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/validar-pedidos',ValidateRequestMaterial::class)->name('planner.validate-request-materials');
Route::get('/insertar-materials',InsertMaterial::class)->name('planner.insert-materials');
Route::get('/validar-pre-reserva',ValidatePreReserva::class)->name('planner.validate-pre-reserva');
Route::get('/importar-datos',ImportarDatos::class)->name('planner.import-data');
