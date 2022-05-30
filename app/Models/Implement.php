<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Implement extends Model
{
    use HasFactory;

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
}