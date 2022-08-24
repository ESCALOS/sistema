<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HomeController extends Controller
{
    public function index(){
        if(Auth()->user() == NULL){
            return redirect('login');
        }else{
            $user = User::find(auth()->user()->id);
            if($user->hasRole('administrador')){
                return redirect()->route('admin');
            }else if($user->hasRole('supervisor')){
                return redirect()->route('overseer.tractor-scheduling');
            }else if($user->hasRole('asistente')){
                return redirect()->route('asistent');
            }else if($user->hasRole('operador')){
                return redirect()->route('operator.request-materials');
            }else if($user->hasRole('planner')){
                return redirect()->route('planner.validate-request-materials');
            }else{
                return view('dashboard');
            }
        }
    }
}
