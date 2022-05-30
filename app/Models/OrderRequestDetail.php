<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderRequestDetail extends Model
{
    use HasFactory;

    public function orderRequest(){
        return $this->belongsTo(OrderRequest::class);
    }
    public function item(){
        return $this->belongsTo(Item::class);
    }
}
