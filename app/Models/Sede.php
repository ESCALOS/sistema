<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Sede extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function zone(){
        return $this->belongsTo(Zone::class);
    }

    public function locations(){
        return $this->hasMany(Location::class);
    }

}
