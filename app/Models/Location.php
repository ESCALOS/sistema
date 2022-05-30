<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    use HasFactory;

    public function sede(){
        return $this->belongsTo(Sede::class);
    }

    public function cecos(){
        return $this->hasMany(Ceco::class);
    }
}
