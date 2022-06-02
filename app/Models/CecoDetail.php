<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CecoDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function ceco(){
        return $this->belongsTo(Ceco::class);
    }
    public function user(){
        return $this->belognsTo(User::class);
    }
    public function implement(){
        return $this->belongsTo(Implement::class);
    }
    public function item(){
        return $this->belongsTo(Item::class);
    }
}
