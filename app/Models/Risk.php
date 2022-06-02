<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Risk extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function epps(){
        return $this->belongsToMany(Epp::class);
    }
    public function tasks(){
        return $this->belongsToMany(Task::class);
    }
}
