<?php

use App\Http\Livewire\Operator\OperatorIndex;
use App\Http\Livewire\Operator\WorkOrder\PendingMaintenanceList;
use App\Http\Livewire\Operator\PreReserva\PreReserva;
use App\Http\Livewire\Operator\RequestMaterial\RequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/',OperatorIndex::class)->name('operator.index');
Route::get('/solicitar-materiales',RequestMaterial::class)->name('operator.request-materials');
Route::get('/Mantenimientos-Pendientes',PendingMaintenanceList::class)->name('operator.pending-maintenance-list');
Route::get('/Pre-reserva',PreReserva::class)->name('operator.pre-reserva');
