<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AsistentController extends Controller
{
    public function index(){
        return view('asistent.index');
    }
}
