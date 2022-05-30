<?php

namespace App\Http\Controllers\Admin;

use App\Models\User;

class UserController
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