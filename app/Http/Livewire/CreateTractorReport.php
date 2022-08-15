<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorReport;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;

class CreateTractorReport extends Component
{
    public $open = false;
    public $location;
    public $lote;
    public $correlative;
    public $date;
    public $shift = "MAÑANA";
    public $user;
    public $tractor;
    public $labor;
    public $implement;
    public $horometro_inicial = 0;
    public $hour_meter_end;
    public $observations = "";


    public $usuarios_usados = [];
    public $tractores_usados = [];
    public $implementos_usados = [];

    protected $rules = [
        'location' => 'required|exists:locations,id',
        'lote' => 'required|exists:lotes,id',
        'correlative' => 'required|unique:tractor_reports',
        'date' => 'required|date|date_format:Y-m-d',
        'shift' => 'required',
        'user' => 'required|exists:users,id',
        'tractor' => 'required|exists:tractors,id',
        'labor' => 'required|exists:labors,id',
        'implement' => 'required|exists:implements,id',
        'hour_meter_end' => "required|gt:horometro_inicial",
    ];

    protected $messages = [
        'location.required' =>'Seleccione una ubicación',
        'location.exists' => 'La ubicación no existe',
        'lote.required' => 'Seleccione el lote',
        'lote.exists' => 'El lote no existe',
        'correlative.required' => 'Ingrese el correlativo',
        'date.required' => 'Seleccione la fecha',
        'date.date' => 'Debe de ingresar una fecha',
        'shift.required' => 'Seleccione el turno',
        'user.required' => 'Seleccione al operador',
        'user.exists' => 'El operador no existe',
        'tractor.required' => 'Seleccione al tractor',
        'tractor.exists' => 'El tractor no existe',
        'labor.required' => 'Seleccione la labor',
        'labor.exists' => 'La labor no existe',
        'implement.required' => 'Seleccione el implemento',
        'implement.exists' => 'El implemento no existe',
        'hour_meter_end.required' => 'Ingrese el horometro final',
        'hour_meter_end.gt' => 'El horometro final debe ser mayor que el inicial'
    ];

    /**
     * Registra el reporte de tractores
     */
    public function store(){
        $this->validate();

        $tractor = Tractor::find($this->tractor);
        $hour_meter_start = $tractor->hour_meter;
        TractorReport::create([
            'user_id' => $this->user,
            'tractor_id' => $this->tractor,
            'labor_id' => $this->labor,
            'correlative' => $this->correlative,
            'date' => $this->date,
            'shift' => $this->shift,
            'implement_id' => $this->implement,
            'hour_meter_start' => floatval($hour_meter_start),
            'hour_meter_end' => floatval($this->hour_meter_end),
            'hours' => floatval($this->hour_meter_end - $hour_meter_start),
            'observations' => $this->observations,
            'lote_id' => $this->lote,
        ]);

        $this->resetExcept(['open','location','lote','date','shift']);

        $this->emit('render');
        $this->alerta();
    }
    
    /**
     * Esta función se usa para mostrar el mensaje de sweetalert
     * 
     * @param string $mensaje Mensaje a mostrar
     * @param string $posicion Posicion de la alerta
     * @param string $icono Icono de la alerta
     */
    public function alerta($mensaje = "Se registró correctamente", $posicion = 'middle', $icono = 'success'){
        $this->emit('alert',[$posicion,$icono,$mensaje]);
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

    public function render()
    {
        /*------------Resetar datos usados----------------------------------------------*/
            $this->reset('usuarios_usados','tractores_usados','implementos_usados');
        /*-----------Poner una fecha anterior por defecto-------------------------------*/
            if($this->date == ""){
                $this->date = date('Y-m-d',strtotime(date('Y-m-d')."-1 days"));
            }
            $locations = Location::where('sede_id',Auth::user()->location->sede->id)->get();

        /*---------------Verificar si existe programación del día y turno-------------*/
            if(TractorReport::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->exists()){
                /*--------------Obtener registros ya seleccionados-------------------------------*/
                    $addeds = TractorReport::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->get();
                    foreach($addeds as $added){
                        array_push($this->usuarios_usados,$added->user_id);
                        array_push($this->tractores_usados,$added->tractor_id);
                        array_push($this->implementos_usados,$added->implement_id);
                    }
            }

            $tractors = Tractor::where('location_id',$this->location)->whereNotIn('id',$this->tractores_usados)->get();
            $users = User::where('location_id',$this->location)->whereNotIn('id',$this->usuarios_usados)->get();
            $labors = Labor::all();
            $implements = Implement::where('location_id',$this->location)->whereNotIn('id',$this->implementos_usados)->get();
            $lotes = Lote::where('location_id',$this->location)->get();

            if($this->tractor > 0){
                $tractor = Tractor::find($this->tractor);
                $this->horometro_inicial = $tractor->hour_meter;
            }else{
                $this->horometro_inicial = 0;
            }

        return view('livewire.create-tractor-report',compact('tractors','labors','implements','users','locations','lotes'));
    }
}
