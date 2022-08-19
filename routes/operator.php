<?php

use App\Http\Livewire\OperatorIndex;
use App\Http\Livewire\PendingMaintenanceList;
use App\Http\Livewire\PreReserva;
use App\Http\Livewire\RequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/',OperatorIndex::class)->name('operator.index');
Route::get('/solicitar-materiales',RequestMaterial::class)->name('operator.request-materials');
Route::get('/Mantenimientos-Pendientes',PendingMaintenanceList::class)->name('operator.pending-maintenance-list');
Route::get('/Pre-reserva',PreReserva::class)->name('operator.pre-reserva');
