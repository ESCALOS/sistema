<?php

use App\Http\Livewire\PendingMaintenanceList;
use App\Http\Livewire\RequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/solicitar-materiales',RequestMaterial::class)->name('operator.request-materials');
Route::get('/Mantenimientos-Pendientes',PendingMaintenanceList::class)->name('operator.pending-maintenance-list');
