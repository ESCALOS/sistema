<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PreStockpileDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function preStockpile(){
        return $this->belongsTo(PreStockpile::class);
    }
    public function item(){
        return $this->belongsTo(Item::class);
    }
    public function warehouse(){
        return $this->belongsTo(Warehouse::class);
    }
}
