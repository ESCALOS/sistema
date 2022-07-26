<?php

namespace App\Http\Livewire;

use App\Imports\ItemsImport;
use App\Imports\UsersImport;
use Livewire\Component;
use Livewire\WithFileUploads;
use Maatwebsite\Excel\Facades\Excel;

class ImportarDatos extends Component
{
    use WithFileUploads;

    public $user;
    public $item;
    public $errores_user;
    public $errores_item;

    public function importarUsuarios(){
        try{
            Excel::import(new UsersImport, $this->user);
            $this->emit('alert');
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_user = $e->failures();
            $this->emit('alert_error');
        }
    }

    public function importarItems(){

        try{
            Excel::import(new ItemsImport, $this->item);
            $this->emit('alert');
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_item = $e->failures();
            $this->emit('alert_error');
        }

    }

    public function render()
    {
        return view('livewire.importar-datos');
    }
}
