<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ceco extends Model
{
    use HasFactory;

    public function location(){
        return $this->belongsTo(Location::class);
    }
    public function cecoDetails(){
        return $this->hasMany(CecoDetail::class);
    }
}
