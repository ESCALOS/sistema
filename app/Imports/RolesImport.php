<?php
namespace App\Imports;

use App\Models\Location;
use App\Models\Sede;
use App\Models\User;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;
use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\ToCollection;

class RolesImport implements ToCollection
{
    public function __construct() {
        $this->roles = Role::pluck('id','name');
        $this->sedes = Sede::pluck('id','sede');
    }

    public function collection(Collection $rows)
    {
        foreach ($rows as $row)
        {
            if(isset($this->roles[strtolower($row[5])])){
                if(User::where('code',$row[0])->doesntExist()){
                    $user = User::create([
                        'code' => $row[0],
                        'dni' => $row[1],
                        'name' => $row[2],
                        'lastname' => $row[3],
                        'location_id' => Location::where('sede_id',$this->sedes[$row[4]])->first()->id,
                        'email' => NULL,
                        'email_verified_at' => now(),
                        'password' => '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', // password
                        'remember_token' => Str::random(10),
                    ]);
                }else{
                    $user = User::where('code',$row[0])->first();
                }
                $role = Role::find($this->roles[strtolower($row[5])]);
                $user->assignRole($role);
            }

        }
    }
}
