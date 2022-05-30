<?php

use App\Http\Controllers\Overseer\TractorScheduling;
use Illuminate\Support\Facades\Route;


Route::get('',[TractorScheduling::class,'index'])->name('overseer.tractor-scheduling.index');


