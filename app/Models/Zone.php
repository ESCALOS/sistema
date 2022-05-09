<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Zone extends Model
{
    use HasFactory;

    //Relación de uno a muchos
    public function sedes(){
        return $this->hasMany(Sede::class);
    }
}

