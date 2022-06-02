<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CecoAllocationAmount extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function ceco(){
        return $this->belognsTo(Ceco::class);
    }
}
