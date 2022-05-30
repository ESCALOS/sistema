<?php

namespace App\Http\Controllers\Overseer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TractorScheduling extends Controller
{
    public function index(){
        return view('overseer.tractor-scheduling');
    }
}
