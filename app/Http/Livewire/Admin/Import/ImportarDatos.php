<?php

namespace App\Http\Livewire\Admin\Import;

use App\Exports\GeneralOrderRequestExport;
use App\Exports\UsersExport;
use App\Imports\ItemsImport;
use App\Imports\ImplementsImport;
use App\Imports\LotesImport;
use App\Imports\RolesImport;
use App\Imports\DataImport;
use App\Imports\TractorsImport;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Livewire\WithFileUploads;
use Livewire\WithPagination;
use Maatwebsite\Excel\Facades\Excel;

class ImportarDatos extends Component
{
    use WithFileUploads;
    use WithPagination;

    public $modelos = [
        1 =>[
            'tabla' => 'users',
            'nombre' => 'Personal'
        ],
        2 => [
            'tabla' => 'tractors',
            'nombre' => 'Tractores'
        ],
        3 => [
            'tabla' => 'lotes',
            'nombre' => 'Lotes'
        ]
    ];
    public $select_import = 1;

    public $file_import;
    public $errores_user = NULL;
    public $errores_item;

    /**
     * Importa usuarios por Excel
     */
    public function importarUsuarios(){
        try{
            //Excel::import(new UsersImport, $this->user);
            $import = new DataImport();
            $import->onlySheets('Personal','Tractores','Implementos');
            Excel::import($import, $this->file_import);
            $this->alerta();
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_user = $e->failures();
            $this->alerta($this->errores_user,'middle','error');
        }
    }

    /**
     * Importa al personal y le asigna su rol
     */
    public function importarPersonal(){
        try {
            Excel::import(new RolesImport, $this->file_import);
            $this->emit('alert');
        } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
            $this->errores_user = $e->failures();
            $this->emit('alert_error');
        }
    }

    public function importarTractores(){
        try {
            Excel::import(new TractorsImport, $this->file_import);
            $this->emit('alert');
        } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
            $this->errores_user = $e->failures();
            $this->emit('alert_error');
        }
    }

    public function importarImplementos(){
        try {
            Excel::import(new ImplementsImport, $this->file_import);
            $this->emit('alert');
        } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
            $this->errores_user = $e->failures();
            $this->emit('alert_error');
        }
    }

    public function importarLotes(){
        try {
            Excel::import(new LotesImport, $this->file_import);
            $this->emit('alert');
        } catch (\Maatwebsite\Excel\Validators\ValidationException $e) {
            $this->errores_user = $e->failures();
            $this->emit('alert_error');
        }
    }

    /**
     * Importa los items por excel
     */
    public function importarItems(){

        try{
            Excel::import(new ItemsImport, $this->file_import);
            $this->emit('alert');
        } catch(\Maatwebsite\Excel\Validators\ValidationException $e){
            $this->errores_item = $e->failures();
            $this->emit('alert_error');
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
        return view('livewire.admin.import.importar-datos');
    }
}
