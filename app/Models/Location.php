<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function sede(){
        return $this->belongsTo(Sede::class);
    }
    public function cecos(){
        return $this->hasMany(Ceco::class);
    }
    public function workOrder(){
        return $this->hasMany(WorkOrder::class);
    }
    public function warehouse(){
        return $this->hasMany(warehouse::class);
    }
    public function implements(){
        return $this->hasMany(Implement::class);
    }
    public function tractors(){
        return $this->hasMany(Tractor::class);
    }
    public function lotes(){
        return $this->hasMany(Lote::class);
    }
    public function users(){
        return $this->hasMany(User::class);
    }
}
