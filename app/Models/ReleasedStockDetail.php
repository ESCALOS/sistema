<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReleasedStockDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function user(){
        return $this->belongsTo(User::class);
    }
    public function item(){
        return $this->belongsTo(Item::class);
    }
    public function warehouse(){
        return $this->belongsTo(Warehouse::class);
    }
    public function operatorAssignedStock(){
        return $this->belongsTo(OperatorAssignedStock::class);
    }
}
