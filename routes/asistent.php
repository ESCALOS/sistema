<?php

use App\Http\Controllers\AsistentController;
use Illuminate\Support\Facades\Route;
use App\Http\Livewire\TractorReport;

//Route::get('/',[AsistentController::class,'index'])->name('asistent.index');
//Route::post('/',[AsistentController::class,'store']);
Route::get('/',TractorReport::class)->name('asistent.index');
