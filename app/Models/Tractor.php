<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tractor extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function tractorModel(){
        return $this->belongsTo(TractorModel::class);
    }
    public function tractorReport(){
        return $this->hasMany(TractorReport::class);
    }
    public function tractorScheduling(){
        return $this->hasMany(TractorScheduling::class);
    }
    public function location(){
        return $this->belongsTo(Location::class);
    }
}
