<?php

namespace App\Http\Livewire;

use App\Exports\TractorScheduleExport;
use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorScheduling as ModelsTractorScheduling;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use Livewire\WithPagination;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use phpDocumentor\Reflection\Types\This;

class TractorScheduling extends Component
{
    use WithPagination;

    public $idSchedule = 0;
    public $stractor;
    public $slabor;
    public $simplement;
    public $open_edit = false;

    public $open_print_schedule = false;
    public $start_date;
    public $end_date;
    public $location;
    public $location_name;
    public $lote;
    public $lote_name;
    public $date;
    public $shift;
    public $user;
    public $tractor;
    public $labor;
    public $implement;

    public $usuarios_usados = [];
    public $tractores_usados = [];
    public $implementos_usados = [];

    protected $listeners = ['render'];

    public function mount(){
        $this->start_date = date('Y-m-d');
        $this->end_date = date('Y-m-d');
    }

    protected function rules(){
        return [
            'location' => 'required|exists:locations,id',
            'lote' => 'required|exists:lotes,id',
            'user' => 'required|exists:users,id',
            'labor' => 'required|exists:labors,id',
            'tractor' => 'required|exists:tractors,id',
            'implement' => 'required|exists:implements,id',
            'date' => 'required|date|date_format:Y-m-d',
            'shift' => 'required|in:MAÑANA,NOCHE'
        ];
    }

    protected function messages(){
        return [
            'location.required' => 'Seleccione una ubicación',
            'lote.required' => 'Seleccione el lote',
            'user.required' => 'Seleccione al operador',
            'labor.required' => 'Seleccione la labor',
            'tractor.required' => 'Seleccione el tractor',
            'implement.required' => 'Seleccione el implemento',
            'date.required' => 'Seleccione la fecha',
            'shift.required' => 'Seleccione el turno',

            'location.exists' => 'La ubicación no existe',
            'lote.exists' => 'El lote no existe',
            'user.exists' => 'El operador no existe',
            'labor.exists' => 'La labor no existe',
            'tractor.exists' => 'El tractor no existe',
            'implement.exists' => 'El implmento no existe',
            'date.date' => 'Debe ingresar un fecha',
            'date.date_format' => 'Formato incorrecto',
            'shift.in' => 'El turno no existe',
        ];
    }

    public function updatedStartDate(){
        if($this->end_date < $this->start_date){
            $this->end_date = $this->start_date;
        }
    }

    public function updatedEndDate(){
        if($this->start_date > $this->end_date){
            $this->start_date = $this->end_date;
        }
    }

    /**
     * Obtener el id de la programación de tractores al clickear
     * 
     * @param int $id ID de la programación del tractor
     */
    public function seleccionar($id){
        $this->idSchedule = $id;
        $this->emit('capturar',$this->idSchedule);
    }

    /**
     * Anula la programación del tractor
     */
    public function anular(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $scheduling->is_canceled = 1;
        $scheduling->save();
        $this->idSchedule = 0;
        $this->render();
    }

    /**
     * Obtener los datos de la programación del tractor
     */
    public function editar(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $this->location = $scheduling->lote->location->id;
        $this->location_name = $scheduling->lote->location->location;
        $this->lote = $scheduling->lote_id;
        $this->lote_name = $scheduling->lote->lote;
        $this->date = $scheduling->date;
        $this->shift = $scheduling->shift;
        $this->user = $scheduling->user_id;
        $this->tractor = $scheduling->tractor_id;
        $this->labor = $scheduling->labor_id;
        $this->implement = $scheduling->implement_id;
        $this->open_edit = true;
    }

    /**
     * Actualizar la programaciòn del tractor
     */
    public function actualizar(){
        $this->validate();
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        //$scheduling->lote_id = $this->lote;
        //$scheduling->date = $this->date;
        //$scheduling->shift = $this->shift;
        $scheduling->user_id = $this->user;
        $scheduling->tractor_id = $this->tractor;
        $scheduling->labor_id = $this->labor;
        $scheduling->implement_id = $this->implement;
        $scheduling->save();
        $this->open_edit = false;
        $this->render();
        $this->alerta();
    }

    public function updatedLocation(){
        $this->lote = 0;
        $this->tractor = 0;
        $this->implement = 0;
        $this->user = 0;
    }

    public function updatedOpen(){
        $this->resetExcept('open','location','lote');
        if(!$this->open){
            $this->reset('usuarios_usados','tractores_usados','implementos_usados');
        }
    }

    public function updatedDate(){
        $this->reset('usuarios_usados','tractores_usados','implementos_usados');

    }

    public function updatedShift(){
        $this->reset('usuarios_usados','tractores_usados','implementos_usados');
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

    public function print_pdf(){
        $title = 'Programación del '.$this->start_date;
        if($this->start_date != $this->end_date){
            $title = $title.' al '.$this->end_date;
        }
        $title = $title.'.xlsx';
        //return Excel::download(new TractorScheduleExport($this->start_date,$this->end_date), $title);
        return response()->streamDownload(function () {
            $schedule = ModelsTractorScheduling::all();
            $pdf = PDF::loadView('pdf.tractor-scheduling',compact('schedule'));
            echo $pdf->stream();
        }, 'test.pdf');

    }

    public function render()
    {
        $this->reset('usuarios_usados','tractores_usados','implementos_usados');
        $sede_general = Auth::user()->location->sede->id;
        $filtro_tractores = Tractor::join('locations',function($join){
            $join->on('locations.id','=','tractors.location_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','=','locations.sede_id');
        })->where('sedes.id','=',$sede_general)->select('tractors.*')->get();

        $filtro_implementos = Implement::join('locations',function($join){
            $join->on('locations.id','=','implements.location_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','=','locations.sede_id');
        })->where('sedes.id','=',$sede_general)->select('implements.*')->get();


        /*---------------Verificar si existe programación del día y turno-------------*/
        if(ModelsTractorScheduling::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->whereNotIn('id',[$this->idSchedule])->exists()){
            /*--------------Obtener registros ya seleccionados-------------------------------*/
            $addeds = ModelsTractorScheduling::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->whereNotIn('id',[$this->idSchedule])->get();
            foreach($addeds as $added){
                array_push($this->usuarios_usados,$added->user_id);
                array_push($this->tractores_usados,$added->tractor_id);
                array_push($this->implementos_usados,$added->implement_id);
            }
        }

        /*----------------CRUD-------------------------------------------------------*/
        $locations = Location::where('sede_id',Auth::user()->location->sede->id)->get();
        $lotes = Lote::where('location_id',$this->location)->get();
        $users = User::where('location_id',$this->location)->whereNotIn('id',$this->usuarios_usados)->get();
        $tractors = Tractor::where('location_id',$this->location)->whereNotIn('id',$this->tractores_usados)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->whereNotIn('id',$this->implementos_usados)->get();

        $tractorSchedulings = ModelsTractorScheduling::where('is_canceled',0);

        if($this->stractor > 0){
            $tractorSchedulings = $tractorSchedulings->where('tractor_id',$this->stractor);
        }

        if($this->slabor > 0){
            $tractorSchedulings = $tractorSchedulings->where('labor_id',$this->slabor);
        }

        if($this->simplement > 0){
            $tractorSchedulings = $tractorSchedulings->where('implement_id',$this->simplement);
        }

        $tractorSchedulings = $tractorSchedulings->orderBy('id','desc')->paginate(6);

        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements','locations','users','lotes','filtro_tractores','filtro_implementos'));
    }
}
