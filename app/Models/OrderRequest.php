<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderRequest extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function user(){
        return $this->belongsTo(User::class);
    }
    public function implement(){
        return $this->belongsTo(Implement::class);
    }
    public function validated_by(){
        return $this->belongsTo(User::class);
    }
    public function orderRequestDetails(){
        return $this->hasMany(OrderRequestDetails::class);
    }
    public function orderRequesNewItem(){
        return $this->hasMnay(OrderRequesNewItem::class);
    }
}
