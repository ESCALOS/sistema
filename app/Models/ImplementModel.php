<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ImplementModel extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function implements(){
        return $this->hasMany(Implement::class);
    }
    public function components(){
        return $this->belongsToMany(Component::class);
    }
}
