<?php

namespace App\Http\Livewire;

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
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\DB;

class TractorScheduling extends Component
{
    use WithPagination;

    public $idSchedule = 0;
    public $stractor;
    public $slabor;
    public $simplement;
    public $open_edit = false;

    public $open_print_schedule = false;
    public $schedule_date;

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
        $this->schedule_date = date('Y-m-d');
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

    public function updatedStractor(){
        $this->resetPage();
    }

    public function updatedSimplement(){
        $this->resetPage();
    }

    public function updatedSlabor(){
        $this->resetPage();
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
        if($this->idSchedule > 0){
            $scheduling = ModelsTractorScheduling::find($this->idSchedule);
            if($scheduling->date < now()->toDateString()){
                $this->alerta('No se puede anular','center','error');
            }else{
                $scheduling->is_canceled = 1;
                $scheduling->save();
                $this->idSchedule = 0;
                $this->alerta('Se anuló correctamente','top-end');
            }
        }else{
            $this->alerta('Ningún registro seleccionado','center','error');
        }
    }

    /**
     * Obtener los datos de la programación del tractor
     */
    public function editar(){

        if($this->idSchedule > 0){
            $scheduling = ModelsTractorScheduling::find($this->idSchedule);
            if($scheduling->date < now()->toDateString()){
                $this->alerta('No se puede editar','center','error');
            }else{
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
        }else{
            $this->alerta('Ningún registro seleccionado','center','error');
        }
    }

    /**
     * Actualizar la programaciòn del tractor
     */
    public function actualizar(){
        $scheduling = ModelsTractorScheduling::find($this->idSchedule);
        $this->validate();
        if($scheduling->date < now()->toDateString()){
            $this->alerta('No se puede editar','center','error');
        }else{
            $scheduling->user_id = $this->user;
            $scheduling->tractor_id = $this->tractor;
            $scheduling->labor_id = $this->labor;
            $scheduling->implement_id = $this->implement;
            $scheduling->validated_by = Auth::user()->id;
            $scheduling->save();
            $this->open_edit = false;
            $this->alerta();
        }        
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

    public function print_schedule(){
        $title = 'Programación del '.$this->schedule_date.'.pdf';
        if(ModelsTractorScheduling::where('date',$this->schedule_date)->doesntExist()){
            $this->alerta('No hay programación para ese día','center','error');
        }else{
            return response()->streamDownload(function () {
                $fecha = $this->schedule_date;
                $schedule = ModelsTractorScheduling::where('date',$fecha)->get();
                $pdf = PDF::loadView('pdf.tractor-scheduling',compact('schedule','fecha'));
                $pdf->set_paper("A4", "landscape");
                echo $pdf->stream();
            }, $title);
        }
    }

    public function print_routines(){
        if(ModelsTractorScheduling::where('date',$this->schedule_date)->doesntExist()){
            $this->alerta('No hay programación para ese día','center','error');
        }else{
            $title = 'Programación del '.$this->schedule_date.'.pdf';
            return response()->streamDownload(function () {
    
                $date = $this->schedule_date;

                DB::select('call rutinario(?)',[$date]);

                $implements = DB::table('routine_tasks')->join('implements',function($join){
                                                        $join->on('routine_tasks.implement_id','implements.id');
                                                    })->join('implement_models',function($join){
                                                        $join->on('implement_models.id','implements.implement_model_id');
                                                    })->join('users',function($join){
                                                        $join->on('users.id','implements.user_id');
                                                    })->join('tractor_schedulings',function($join){
                                                        $join->on('tractor_schedulings.id','routine_tasks.tractor_scheduling_id');
                                                    })->where('routine_tasks.date',$date)
                                                      ->where('tractor_schedulings.validated_by',Auth::user()->id)
                                                      ->orderBy('tractor_schedulings.shift','ASC')
                                                      ->orderBy('users.name','ASC')
                                                      ->select('users.name','users.lastname','tractor_schedulings.shift','routine_tasks.id','implement_models.implement_model','implements.implement_number')
                                                      ->get();
                
                $tasks = DB::table('routine_task_details')->join('routine_tasks',function($join){
                                                                $join->on('routine_tasks.id','routine_task_details.routine_task_id');                                            
                                                            })->join('implements',function($join){
                                                                $join->on('implements.id','routine_tasks.implement_id');
                                                            })->join('tasks',function($join){
                                                                $join->on('tasks.id','routine_task_details.task_id');
                                                            })->join('components',function($join){
                                                                $join->on('components.id','tasks.component_id');
                                                            })->where('routine_tasks.date',$date)
                                                            ->select('routine_tasks.id as routine_task_id','tasks.task','components.component')
                                                            ->get();
                                                            
                $pdf = PDF::loadView('pdf.routine-task',compact('date','implements','tasks'));
                $pdf->set_paper("A4", "portrait");
                echo $pdf->stream();
            }, $title);
        }
    }

    public function render(){
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
        $users = User::where('location_id',$this->location)->whereNotIn('id',$this->usuarios_usados)->get();
        $tractors = Tractor::where('location_id',$this->location)->whereNotIn('id',$this->tractores_usados)->get();
        $labors = Labor::all();
        $implements = Implement::where('location_id',$this->location)->whereNotIn('id',$this->implementos_usados)->get();

        $tractorSchedulings = ModelsTractorScheduling::where('is_canceled',0)->where('validated_by',Auth::user()->id);

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

        return view('livewire.tractor-scheduling',compact('tractorSchedulings','tractors','labors','implements','users','filtro_tractores','filtro_implementos'));
    }
}
