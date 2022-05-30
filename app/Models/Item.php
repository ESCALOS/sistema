<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Item extends Model
{
    use HasFactory;

    public function cecoDetails(){
        return $this->hasMany(CecoDetails::class);
    }
    public function component(){
        return $this->hasOne(Component::class);
    }
    public function brand(){
        return $this->belongsTo(Brand::class);
    }
    public function measurementUnit(){
        return $this->belongsTo(MeasurementUnit::class);
    }
    public function operatorAssignedStock(){
        return $this->hasMany(OperatorAssignedStock::class);
    }
    public function operatorStock(){
        return $this->hasMany(OperatorStock::class);
    }
    public function operatorStockDetail(){
        return $this->hasMany(OperatorStockDetail::class);
    }
    public function orderResquestDetail(){
        return $this->hasMany(OrderResquestDetail::class);
    }
    public function releasedStock(){
        return $this->hasMany(ReleasedStock::class);
    }
    public function ReleasedStockDetail(){
        return $this->hasMany(OrderRequest::class);
    }
}
