<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TractorModel extends Model
{
    use HasFactory;

    public function tractors(){
        return $this->hasMany(Tractor::class);
    }
}
