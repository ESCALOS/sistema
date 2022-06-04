<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Component extends Model
{
    use HasFactory;

    protected $guarded = [];

    public function item(){
        return $this->hasOne(Item::class);
    }
    public function parts(){
        return $this->belongsToMany(Component::class,'component_parts','component_id','part_id');
    }
    public function systems(){
        return $this->belongsToMany(System::class);
    }
    public function implementModels(){
        return $this->belongsToMany(ImplementModel::class);
    }
    public function implements(){
        return $this->belongsToMany(Implement::class);
    }
}
