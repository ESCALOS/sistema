<?php

namespace App\Imports;

use App\Models\Location;
use App\Models\User;
use App\Models\Sede;

use Illuminate\Support\Str;
use Maatwebsite\Excel\Concerns\Importable;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithBatchInserts;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class UsersImport implements ToModel,WithHeadingRow,WithValidation,WithBatchInserts,WithChunkReading
{
    use Importable;
    private $locations;

    public function __construct() {
        $this->locations = Location::pluck('id','code');
<<<<<<< HEAD
        $this->sedes = Sede::pluck('id','sede');
=======
>>>>>>> a9be07364ea3037f0524d9f6b061ad8d4af4f440
    }

    public function model(array $row)
    {

        if(isset($row['codigo'])){
            return new User([
                'code' => $row['codigo'],
<<<<<<< HEAD
                'dni' => $row['dni'],
                'name' => $row['nombre'],
                'lastname' => $row['apellido'],
                'location_id' => Location::where('sede_id',$this->sedes[$row['sede']])->first()->id,
=======
                'name' => $row['nombre'],
                'lastname' => $row['apellido'],
                'location_id' => 14,
>>>>>>> a9be07364ea3037f0524d9f6b061ad8d4af4f440
                'email' => NULL,
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

    public function rules(): array
    {
        return [
            '*.codigo' => ['required','unique:users,code'],
            '*.nombre' => ['required'],
            '*.apellido' => ['required'],
        ];
    }

    public function customValidationMessages(){
        return[
            'codigo.exists' => 'El item no existe',
        ];
    }
}
