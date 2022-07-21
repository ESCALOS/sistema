<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Fortify\TwoFactorAuthenticatable;
use Laravel\Jetstream\HasProfilePhoto;
use Laravel\Sanctum\HasApiTokens;

use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use HasProfilePhoto;
    use Notifiable;
    use TwoFactorAuthenticatable;
    use HasRoles;

    /**
     * The attributes that are mass assignable.
     *
     * @var string[]
     */
    protected $fillable = [
        'code',
        'name',
        'lastname',
        'email',
        'location_id',
        'password',
    ];
    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array
     */
    protected $hidden = [
        'is_admin',
        'password',
        'remember_token',
        'two_factor_recovery_codes',
        'two_factor_secret',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];

    /**
     * The accessors to append to the model's array form.
     *
     * @var array
     */
    protected $appends = [
        'profile_photo_url',
    ];
    public function adminlte_image(){
        return $this->profile_photo_url;
    }
    public function cecoDetails(){
        return $this->hasMany(CecoDetail::class);
    }
    public function operatorAssignedStock(){
        return $this->hasMany(OperatorAssignedStock::class);
    }
    public function operatorStock(){
        return $this->hasMany(OperatorStock::class);
    }
    public function operatorStockDetail(){
        return $this->hasMany(OperatorStockDetail::class);
    }
    public function orderRequest(){
        return $this->hasMany(OrderRequest::class);
    }
    public function ReleasedStockDetail(){
        return $this->hasMany(OrderRequest::class);
    }
    public function tractorReport(){
        return $this->hasMany(TractorReport::class);
    }
    public function workOrder(){
        return $this->hasMany(WorkOrder::class);
    }
    public function location(){
        return $this->belongsTo(Location::class);
    }
}
