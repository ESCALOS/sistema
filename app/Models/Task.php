<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    use HasFactory;

    public function risks(){
        return $this->belongsToMany(Risk::class);
    }

    public function workOrderDetail(){
        return $this->hasMany(WorkOrderDetail::class);
    }
}
