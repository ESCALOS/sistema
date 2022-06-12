<?php

use App\Http\Livewire\OrderRequestOperator;
use App\Http\Livewire\RequestMaterial;
use Illuminate\Support\Facades\Route;

//Route::get('/',OrderRequestOperator::class)->name('operator.order-request-operator.index');
Route::get('/solicitar-materiales',RequestMaterial::class)->name('operator.request-materials');
