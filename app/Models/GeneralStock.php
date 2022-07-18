<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class GeneralStock extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function item(){
        return $this->belongsTo(Item::class);
    }

    public function generalWarehouse(){
        return $this->belongsTo(GeneralWarehouse::class);
    }

}
