<?php

namespace App\Http\Livewire;

use App\Models\Implement;
use App\Models\Location;
use App\Models\OrderRequest;
use App\Models\Sede;
use App\Models\Zone;
use Illuminate\Support\Facades\DB;
use Livewire\Component;

class ValidateRequestMaterial extends Component
{

    public $tzone = 0;
    public $tsede = 0;
    public $tlocation = 0;

    public $incluidos = [];

    public function updatedTzone(){
        $this->reset('tsede','tlocation');
        $this->incluidos = [];
    }
    public function updatedTsede(){
        $this->reset('tlocation');
        $this->incluidos = [];
    }
    public function updatedTlocation(){
        $this->incluidos = [];
    }

    public function render()
    {

        $zones = Zone::all();

        $sedes = Sede::where('zone_id',$this->tzone)->get();

        $locations = Location::where('sede_id',$this->tsede)->get();

        $order_requests = OrderRequest::join('implements',function ($join){
            $join->on('order_requests.implement_id','=','implements.id')
                    ->where('implements.location_id',$this->tlocation);
        })->where('state','CERRADO')->get();

        if($order_requests != null){
            foreach($order_requests as $order_request){
                array_push($this->incluidos,$order_request->user_id);
            }
        }

        $users = DB::table('users')->whereIn('id',$this->incluidos)->get();

        return view('livewire.validate-request-material', compact('zones', 'sedes', 'locations','users'));
    }
}
