<?php

use App\Http\Livewire\RequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/solicitar-materiales',RequestMaterial::class)->name('operator.request-materials');
