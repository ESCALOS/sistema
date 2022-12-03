<?php

namespace App\Http\Livewire\Admin\User;

use App\Models\Location;
use App\Models\User as ModelsUser;
use Livewire\Component;
use Livewire\WithPagination;

class User extends Component
{
    use WithPagination;

    public $idUser = 0;

    public $sCodigo = "";
    public $sDni = "";
    public $sNombre = "";
    public $sUbicacion = 0;

    public function seleccionar($id)
    {
        $this->idUser = $id;
    }

    public function render()
    {
        $users = ModelsUser::select('id','code','dni','name','lastname','location_id')
                                ->with(['location:id,location'])
                                ->orderBy('id','desc');
        
        if($this->sCodigo > 0){
            $user = $users->where('code','like',$this->sCodigo.'%');
        }

        if($this->sDni > 0){
            $user = $users->where('dni','like',$this->sDni.'%');
        }

        if($this->sNombre > 0){
            $user = $users->where('name','like','%'.$this->sNombre.'%')->orWhere('lastname','like','%'.$this->sNombre.'%');
        }
        
        if($this->sUbicacion > 0){
            $user = $users->where('location_id',$this->sUbicacion);
        }

        $users = $users->paginate(4);


        $locations = Location::select('id','location')->get();

        return view('livewire.admin.user.user',compact('users','locations'));
    }
}
