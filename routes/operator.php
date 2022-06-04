<?php

use App\Http\Livewire\OrderRequestOperator;
use Illuminate\Support\Facades\Route;

Route::get('/',OrderRequestOperator::class)->name('operator.order-request-operator.index');
