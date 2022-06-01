<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TractorReport extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function user(){
        return $this->belongsTo(User::class);
    }
    public function tractor(){
        return $this->belongsTo(Tractor::class);
    }
    public function labor(){
        return $this->belongsTo(Labor::class);
    }
    public function implement(){
        return $this->belongsTo(Implement::class);
    }
}
