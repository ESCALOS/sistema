<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Lote extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function location(){
        return $this->belongsTo(Location::class);
    }
    public function tractorScheduling(){
        return $this->hasMany(TractorScheduling::class);
    }
}
