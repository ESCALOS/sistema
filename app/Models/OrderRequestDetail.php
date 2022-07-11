<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderRequestDetail extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function orderRequest(){
        return $this->belongsTo(OrderRequest::class);
    }
    public function item(){
        return $this->belongsTo(Item::class);
    }
    public function implement(){
        return $this->belongsTo(Implement::class);
    }
}
