<?php

use App\Http\Livewire\ValidateRequestMaterial;
use Illuminate\Support\Facades\Route;

Route::get('/validate-request-material',ValidateRequestMaterial::class)->name('planner.validate-request-materials');
