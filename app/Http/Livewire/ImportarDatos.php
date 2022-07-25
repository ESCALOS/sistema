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

    public function importarUsuarios(){

        #$this->user->store('user');
        Excel::import(new UsersImport, $this->user);

        $this->emit('alert');
    }

    public function importarItems(){

        #$this->item->store('item');
        Excel::import(new ItemsImport, $this->item);

        $this->emit('alert');
    }

    public function render()
    {
        return view('livewire.importar-datos');
    }
}
