<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TractorModel extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function tractors(){
        return $this->hasMany(Tractor::class);
    }
}
