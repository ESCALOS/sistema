<?php

use Illuminate\Support\Facades\Route;
use App\Http\Livewire\TractorReport;

Route::get('/',TractorReport::class)->name('asistent');
