<?php

namespace App\Imports;

use App\Models\Location;
use App\Models\User;
use Maatwebsite\Excel\Concerns\ToModel;

use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class UsersImport implements ToModel, WithHeadingRow,WithBatchInserts,WithChunkReading
{
    private $locations;
    
    public function __construct() {
        $this->locations = Location::pluck('id','code');
    }

    public function model(array $row)
    {
        
        if(isset($row['codigo'])){    
            return new User([
                'code' => $row['codigo'],
                'name' => $row['nombre'],
                'lastname' => $row['apellido'],
                'location_id' => $this->locations[$row['ubicacion']],
                'email' => "",
                'email_verified_at' => now(),
                'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
                'remember_token' => Str::random(10),
            ]);
        }
    }

    public function batchSize(): int
    {
        return 2000;
    }

    public function chunkSize(): int
    {
        return 2000;
    }
}
