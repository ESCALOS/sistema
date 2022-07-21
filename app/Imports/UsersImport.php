<?php

namespace App\Imports;

use App\Models\Location;
use App\Models\User;
use Maatwebsite\Excel\Concerns\ToModel;

use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class UsersImport implements ToModel, WithHeadingRow
{
    /**
    * @param array $row
    *
    * @return \Illuminate\Database\Eloquent\Model|null
    */
    public function model(array $row)
    {
        return new User([
            'code' => $row['codigo'],
            'name' => $row['nombre'],
            'lastname' => $row['apellido'],
            'location_id' => Location::where('location','like',strtoupper($row['ubicacion']))->first()->id,
            'email' => $row['correo'],
            'email_verified_at' => now(),
            'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
            'remember_token' => Str::random(10),
        ]);
    }
}
