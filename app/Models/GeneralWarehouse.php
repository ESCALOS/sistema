<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GeneralWarehouse extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function generalStock(){
        return $this->hasOne(GeneralStock::class);
    }

    public function generalStockDetail(){
        return $this->hasOne(GeneralStockDetail::class);
    }
}
