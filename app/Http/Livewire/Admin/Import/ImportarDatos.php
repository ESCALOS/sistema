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
        [
            'nombre' => 'personal',
            'tabla' => 'users',
            'campos' => [
                [
                    'header' => 'Código',
                    'field' => 'code',
                ],
                [
                    'header' => 'DNI',
                    'field' => 'dni'
                ],
                [
                    'header' => 'Nombre',
                    'field' => 'name'
                ],
                [
                    'header' => 'Apellido',
                    'field' => 'lastname'
                ],
                [
                    'header' => 'Ubicación',
                    'field' => 'location_id',
                    'show' => 'location'
                ]
            ]
        ],
        [
            'nombre' => 'tractores',
            'tabla' => 'tractors',
            'campos' => [
                [
                    'header' => 'Modelo',
                    'field' => 'tractor_model_id'
                ],
                [
                    'header' => 'Número',
                    'field' => 'tractor_number'
                ],
                [
                    'header' => 'Motor',
                    'field' => 'motor'
                ],
                [
                    'header' => 'Serie',
                    'field' => 'serie'
                ],
                [
                    'header' => 'Horómetro',
                    'field' => 'hour_meter'
                ]
            ]
        ],
        [
            'nombre' => 'implementos',
            'tabla' => 'implements',
            'campos' => [
                [
                    'header' => 'Modelo',
                    'field' => 'implement_model_id',
                ],
                [
                    'header' => 'Número',
                    'field' => 'implement_number'
                ],
                [
                    'header' => 'Horas',
                    'field' => 'hours'
                ],
                [
                    'header' => 'Responsable',
                    'field' => 'user_id',
                    'show' => 'code'
                ],
                [
                    'header' => 'Ubicación',
                    'field' => 'location_id',
                    'show' => 'location'
                ],
                [
                    'header' => 'CeCo',
                    'field' => 'ceco_id',
                    'show' => 'code'
                ]
            ]
        ],
        [
            'nombre' => 'lotes',
            'tabla' => 'lotes',
            'campos' => [

            ]
        ],
        [
            'nombre' => 'items',
            'tabla' => 'items'
        ]
    ];
    public $select_import = 0;
    public $showed_fields = [];

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

    public function updatingSelectImport(){
        $this->showed_fields = [];
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
        if($this->select_import >= 0){

            $datos = DB::table($this->modelos[$this->select_import]['tabla']);

            foreach ($this->modelos[$this->select_import]['campos'] as $campo) {
                if(preg_match('/_id$/',$campo['field'])){
                    $nombre_tabla = $this->modelos[$this->select_import]['tabla'];
                    $nombre_campo = $campo['field'];
                    $datos->join(str_replace('_id','s',$campo['field']),function($join) use ($nombre_campo,$nombre_tabla){
                        $join->on(str_replace('_id','s',$nombre_campo).'.id',$nombre_tabla.'.'.$nombre_campo);
                    });
                    if(isset($campo['show'])){
                        array_push($this->showed_fields,str_replace('_id','s',$campo['field']).'.'.$campo['show']);
                    }else{
                        array_push($this->showed_fields,str_replace('_id','s',$campo['field']).'.'.str_replace('_id','',$campo['field']));
                    }
                }else{
                    array_push($this->showed_fields,$this->modelos[$this->select_import]['tabla'].'.'.$campo['field']);
                }
                //array_push($this->showed_fields,$campo['field']);
            }

            $datos = $datos->select($this->showed_fields)->paginate(8);
        }
        return view('livewire.admin.import.importar-datos',compact('datos'));
    }
}
