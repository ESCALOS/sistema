<?php

namespace App\Http\Livewire;

use App\Http\Livewire\TractorScheduling as LivewireTractorScheduling;
use App\Models\Implement;
use App\Models\Labor;
use App\Models\Location;
use App\Models\Lote;
use App\Models\Tractor;
use App\Models\TractorScheduling;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class CreateTractorScheduling extends Component
{
    public $open = false;
    public $location;
    public $lote;
    public $user;
    public $labor;
    public $tractor;
    public $implement;
    public $date;
    public $shift = "MAÑANA";

    public $fundos = [];

    public $usuarios_usados = [];
    public $tractores_usados = [];
    public $implementos_usados = [];

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

    /**
     * Registra la programación de tractores
     */
    public function store(){
        $this->validate();

        TractorScheduling::create([
            'lote_id' => $this->lote,
            'user_id' => $this->user,
            'tractor_id' => $this->tractor,
            'labor_id' => $this->labor,
            'implement_id' => $this->implement,
            'date' => $this->date,
            'shift' => $this->shift,
            'validated_by' => Auth::user()->id
        ]);
        $this->resetExcept(['open','location','lote','date','shift']);

        $this->emit('render');
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

    public function render()
    {
        $this->reset('usuarios_usados','tractores_usados','implementos_usados');
        if($this->date == ""){
            $this->date = date('Y-m-d',strtotime(date('Y-m-d')."+1 days"));
        }

        $overseer_locations = DB::table('overseer_locations')->select('location_id')->where('user_id',Auth::user()->id)->get();
        foreach($overseer_locations as $request){
            array_push($this->fundos,$request->location_id);
        }
        $locations = Location::whereIn('id',$this->fundos)->get();

    /*---------------Verificar si existe programación del día y turno-------------*/
        if(TractorScheduling::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->exists()){
        /*--------------Obtener registros ya seleccionados-------------------------------*/
            $addeds = TractorScheduling::where('date',$this->date)->where('shift',$this->shift)->where('is_canceled',0)->get();
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

        return view('livewire.create-tractor-scheduling', compact('tractors', 'users', 'labors', 'implements', 'locations','lotes'));
    }
}
