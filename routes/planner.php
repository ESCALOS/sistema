<?php
use App\Http\Livewire\Planner\Stock\InsertMaterial;
use App\Http\Livewire\Planner\PreReserva\ValidatePreReserva;
use App\Http\Livewire\Planner\RequestMaterial\ValidateRequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/validar-pedidos',ValidateRequestMaterial::class)->name('planner.validate-request-materials');
Route::get('/insertar-materials',InsertMaterial::class)->name('planner.insert-materials');
Route::get('/validar-pre-reserva',ValidatePreReserva::class)->name('planner.validate-pre-reserva');
