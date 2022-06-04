<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Implement extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function cecoDetails(){
        return $this->hasMany(CecoDetails::class);
    }
    public function implementModel(){
        return $this->belongsTo(ImplementModel::class);
    }
    public function user(){
        return $this->belongsTo(User::class);
    }
    public function tractorReport(){
        return $this->hasMany(TractorReport::class);
    }
    public function workOrder(){
        return $this->hasMany(WorkOrder::class);
    }
    public function tractorScheduling(){
        return $this->hasMany(TractorScheduling::class);
    }
    public function minStockDetails(){
        return $this->hasMany(MinStockDetail::class);
    }
    public function components(){
        return $this->belongsToMany(Component::class);
    }
}
