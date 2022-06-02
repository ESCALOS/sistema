<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WorkOrderDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function workOrder(){
        return $this->belongsTo(WorkOrder::class);
    }
    public function task(){
        return $this->belongsTo(Task::class);
    }
}
