<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tractor extends Model
{
    use HasFactory;

    public function tractorModel(){
        return $this->belongsTo(TractorModel::class);
    }
    public function tractorReport(){
        return $this->hasMany(TractorReport::class);
    }
}
