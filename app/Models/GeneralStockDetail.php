<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GeneralStockDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function item(){
        return $this->belongsTo(Item::class);
    }

    public function orderDate(){
        return $this->belongsTo(OrderDate::class);
    }

    public function sede(){
        return $this->belongsTo(Sede::class);
    }
}
