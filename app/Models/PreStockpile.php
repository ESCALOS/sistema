<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use phpDocumentor\Reflection\Types\This;

class PreStockpile extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function implement(){
        return $this->belongsTo(Implement::class);
    }
    public function user(){
        return $this->belongsTo(User::class);
    }
    public function ceco(){
        return $this->belongsTo(Ceco::class);
    }
}
