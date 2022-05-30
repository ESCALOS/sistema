<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Warehouse extends Model
{
    use HasFactory;

    public function operatorAssignedStock(){
        return $this->hasMany(OperatorAssignedStock::class);
    }
    public function operatorStock(){
        return $this->hasMany(OperatorStock::class);
    }
    public function operatorStockDetail(){
        return $this->hasMany(OperatorStockDetail::class);
    }
    public function releasedStock(){
        return $this->hasMany(ReleasedStock::class);
    }
    public function ReleasedStockDetail(){
        return $this->hasMany(OrderRequest::class);
    }
    public function location(){
        return $this->belongsTo(Location::class);
    }
}
