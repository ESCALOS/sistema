<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CecoAllocationamount extends Model
{
    use HasFactory;

    public function ceco(){
        return $this->belognsTo(Ceco::class);
    }
}
