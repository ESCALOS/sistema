<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\HomeController;
use App\Http\Controllers\Admin\UserController;

Route::get('',[HomeController::class,'index']);

Route::middleware([
    'auth:sanctum',
    config('jetstream.auth_session'),
    'verified'
])->controller(UserController::class)->group(function(){
    Route::get('user','index')->name('admin.user.index');
    //Route::get('user','create')->name('admin.user.create');
});