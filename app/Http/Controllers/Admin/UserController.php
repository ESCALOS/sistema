<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class UserController extends Controller
{
    public function index(){
        return view('admin.users');
    }
    public function create(){
        return "hola";
    }
    /*public function create(array $input)
    {
        return User::create([
            'code' => $input['code'],
            'name' => $input['name'],
            'lastname' => $input['lastname'],
            'email' => $input['email'],
            'password' => Hash::make($input['password']),
        ]);
    }*/
}
