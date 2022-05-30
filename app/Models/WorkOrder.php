<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WorkOrder extends Model
{
    use HasFactory;
    
    public function implement(){
        return $this->belongsTo(Implement::class);
    }
    public function user(){
        return $this->belongsTo(User::class);
    }
    public function location(){
        return $this->belongsTo(Location::class);
    }
    public function workOrderDetail(){
        return $this->hasMany(WorkOrderDetail::class);
    }
    public function epps(){
        return $this->belongsToMany(Epp::class);
    }
}
