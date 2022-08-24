<?php

namespace App\Http\Livewire\Admin;

use App\Models\Location;
use App\Models\User;
use Livewire\Component;
use Livewire\WithPagination;

class Users extends Component
{
    use WithPagination;

    public $id_usuario = 0;

    public $open_create = false;

    public $open_edit = false;

    /**
     * Obtener el id del usuario al clickear
     * 
     * @param int $id ID del usuario
     */
    public function seleccionar($id){
        $this->id_usuario = $id;
    }

    public function render()
    {
        $users = User::select('id','code','name','lastname','location_id')->paginate(6);
        $locations = Location::select('id','location')->get();

        return view('livewire.admin.users',compact('users','locations'));
    }
}
