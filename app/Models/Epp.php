<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Epp extends Model
{
    use HasFactory;

    public function risks(){
        return $this->belongsToMany(Risk::class);
    }
    public function workOrders(){
        return $this->belongsToMany(WorkOrder::class);
    }
}
