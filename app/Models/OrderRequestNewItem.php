<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderRequestNewItem extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function orderRequest(){
        return $this->belongs(OrderRequest::class);
    }
}
