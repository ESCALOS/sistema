<?php

namespace App\Http\Livewire;

use App\Exports\GeneralOrderRequestExport;
use App\Exports\UsersExport;
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

    public function exportarUsuarios()
    {
        return Excel::download(new UsersExport, 'users.xlsx');
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

    public function exportarFormatoStock()
    {
        return Excel::download(new GeneralOrderRequestExport(1), 'formato-stock.xlsx');
    }

    public function render()
    {
        return view('livewire.importar-datos');
    }
}
