<?php

use Illuminate\Support\Facades\Route;
use App\Http\Livewire\Asistent\TractorReport\TractorReport;

Route::get('/',TractorReport::class)->name('asistent');
