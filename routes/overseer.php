<?php

use App\Http\Livewire\TractorScheduling;
use Illuminate\Support\Facades\Route;


Route::get('/',TractorScheduling::class)->name('overseer.tractor-scheduling');


