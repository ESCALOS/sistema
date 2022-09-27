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
    public $errores_user = NULL;
    public $errores_item;

    /**
     * Importa usuarios por Excel
     */
    public function importarUsuarios(){
        try{
            Excel::import(new UsersImport, $this->user);
            $this->alerta();
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_user = $e->failures();
            $this->alerta($this->errores_user,'middle','error');
        }
    }

    /**
     * Exporta un excel con los datos de los usuarios
     */
    public function exportarUsuarios()
    {
        return Excel::download(new UsersExport, 'users.xlsx');
    }

    /**
     * Importa los items por excel
     */
    public function importarItems(){

        try{
            Excel::import(new ItemsImport, $this->item);
            $this->emit('alert');
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_item = $e->failures();
            $this->emit('alert_error');
        }

    }
    /**
     * Exporta el formato para registrar el stock
     */
    public function exportarFormatoStock()
    {
        return Excel::download(new GeneralOrderRequestExport(1), 'formato-stock.xlsx');
    }

    /**
     * Esta función se usa para mostrar el mensaje de sweetalert
     *
     * @param string $mensaje Mensaje a mostrar
     * @param string $posicion Posicion de la alerta
     * @param string $icono Icono de la alerta
     */
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'center', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
    }

    public function render()
    {
        return view('livewire.importar-datos');
    }
}
