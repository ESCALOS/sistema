<?php

use App\Http\Controllers\AsistentController;
use App\Http\Controllers\OperatorController;
use Illuminate\Support\Facades\Route;


Route::get('/', function () {
    return view('welcome');
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified'
])->group(function () {
    Route::get('/dashboard', function () {
        return view('profile.show');
    })->name('dashboard');
});

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified'
])->controller(AsistentController::class)->group(function(){
    Route::get('asistent','index')->name('asistent.index');
});

Route::controller(OperatorController::class)->group(function(){
    Route::get('operator','index')
    ->middleware('auth:sanctum');
});