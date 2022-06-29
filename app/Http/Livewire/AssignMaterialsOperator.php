<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\Implement;
use App\Models\Location;
use App\Models\OrderDate;
use App\Models\OrderRequest;
use App\Models\OrderRequestDetail;
use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;
use Carbon\Carbon;

class AssignMaterialsOperator extends Component
{
    public $idSolicitudPedido = 0;

    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;
    public $tfecha = 0;

    public $incluidos = [];

    protected $listeners = [];

    protected function rules(){
        return [

        ];
    }

    protected function messages(){
        return [

        ];
    }
/*----------------Funciones dinámicas------------------------------------------------------*/
    public function updatedTzone(){
        $this->reset('tsede','tlocation','tfecha');
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->reset('tlocation','tfecha');
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->reset('tfecha');
        $this->incluidos = [];
    }
    public function updatedTfecha(){
        $this->reset('idSolicitudPedido');
        $this->incluidos = [];
    }
/*-------------------------------------------------------------------------------------------*/
    public function render()
    {
    /*------------------DATOS PARA LAS SOLICITUDES DE PEDIDO POR USUARIO----------------------------*/
        /*---------------------Mostrar zonas, sedes , ubicaciones y fechas de pedido--------------------*/
        $zones = Zone::all();

        $sedes = Sede::where('zone_id',$this->tzone)->get();

        $locations = Location::where('sede_id',$this->tsede)->get();

        $order_dates = OrderDate::where('state','CERRADO')->get();

        /*------Obtener las solicitudes de pedido por ubicación y fecha, y que estén validadas----------------------------*/
        $order_requests = OrderRequest::join('implements',function ($join){
            $join->on('order_requests.implement_id','=','implements.id');
        })->where('implements.location_id',$this->tlocation)->where('state','VALIDADO')->where('state','INCOMPLETO')->get();

        /*---------------------------Obtener los usuarios que tienen una solicitud cerrada----------*/
        if($order_requests != null){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->user_id);
            }
        }
        /*--------------------Mostrar a los usuarios que tienen solicitudes de pedido cerrada----------------------*/
        $users = DB::table('users')->whereIn('id',$this->incluidos)->get();

    /*----------------------DATOS DEL MODAL DE VALIDACIÓN ------------------------------------------*/


        return view('livewire.assign-materials-operator', compact('zones', 'sedes', 'locations','order_dates','users'));
    /*---------------------------------------------------------------------------------------------------*/
    }
}
