<?php

namespace App\Http\Livewire;

use App\Models\CecoAllocationAmount;
use App\Models\GeneralStock;
use App\Models\Implement;
use App\Models\Location;
use App\Models\PreStockpile;
use App\Models\PreStockpileDate;
use App\Models\PreStockpileDetail;
use App\Models\Sede;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Livewire\Component;
use phpDocumentor\Reflection\Types\This;

class ValidatePreReserva extends Component
{
    /*------------VARIABLES PÚBLICAS---------------------------------*/
        /*------------Modal General------------------------*/
            public $open_validate_pre_reserva = false;
        /*------------Estado de la solicitud (PENDIENTE,CERRADO,VALIDADO,RECHAZADO)-----*/
            public $estado_pre_reserva = "";
        /*------------Montos disponibles usados----------------------*/
            public $monto_usado = 0;
            public $monto_asignado = 0;
            public $monto_real = 0;
            public $monto_pre_reservado = 0;
        /*------------Datos para el modal de materiales------------------*/
            public $open_validate_material = false;
            public $id_material = 0;
            public $material = "";
            public $cantidad = 0;
            public $cantidad_pedida = 0;
            public $cantidad_stock = 0;
            public $measurement_unit = "";
        /*------------Datos para la pre-reserva en curso-------------------*/
            public $fecha_pre_reserva = "";
        /*------------Datos del operador-------------*/
            public $id_operador = 0;
            public $operador = "";
        /*------------Datos del implemento----------------*/
            public $id_implemento = 0;
            public $implemento = "";
        /*------------Id de la pre-reserva (Pre-Stockpile)---------*/
            public $id_pre_reserva = 0;
        /*------------Filtros para encontrar los usuarios que tiene pre-reservas sin validar----------*/
            public $tsede = 0;
            public $tlocation = 0;
        /*------------Array para almacenar los usuarios que tiene pre-reservas-------------------*/
            public $incluidos = [];
    /*------------DEFINIR FUNCIONES ESCUCHADAS DE OTROS COMPONENTES---------------------------------------------*/
        protected $listeners = ['reinsertarRechazado','validarPreReserva','rechazarPreReserva'];
    /*------------DEFINIR REGLAS DE VALIDACIÓN-----------------------------------*/
        protected function rules(){
            return [
                'cantidad' => ['required','numeric','lte:cantidad_pedida','lte:cantidad_stock','min:0'],
            ];
        }
    /*------------DEFINIR MENSAJES DE VALIDACIÓN--------------------------------------------------*/
        protected function messages(){
            return [
                'cantidad.required' => 'La cantidad es requerida',
                'cantidad.lte' => 'No hay suficiente cantidad',
                'cantidad.min' => 'La cantidad no puede ser negativa',
            ];
        }
    /*----------------FUNCIONES AL ACTUALIZAR VARIABLES PÚBLICAS-------------------------*/
        /*-------Actualizar todas las variables menos la zona y sede----------------------*/
            public function updatedTsede(){
                $this->resetExcept(['tsede']);
                $this->incluidos = [];
            }
        /*-------Actualizar todas las variables menos la zona, sede y ubicación-----------*/
            public function updatedTlocation(){
                $this->resetExcept(['tsede','tlocation']);
                $this->incluidos = [];
            }
        /*------Actualizar todas las variables menos la zona, sede, ubicación y el estado del modal de validación de la pre-reserva-------*/
            public function updatedOpenValidatePreReserva(){
                if(!$this->open_validate_pre_reserva){
                    $this->resetExcept(['tsede','location','open_validate_pre_reserva']);
                    $this->resetValidation();
                }
            }
        /*-------Obtener el id de la solicitud y los montos al cambiar de implemento-----------------*/
            public function updatedIdImplemento(){
                if(PreStockpile::where('implement_id',$this->id_implemento)->where('state','CERRADO')->exists()){
                    $pre_stockpile = PreStockpile::where('implement_id',$this->id_implemento)->where('state','CERRADO')->first();
                    $this->id_pre_reserva = $pre_stockpile->id;
                }else{
                    $this->reset('id_pre_reserva','monto_asignado','monto_usado','monto_real');
                }
            }
    /*---------MODAL PARA LA VALIDACIÓN O RECHAZO DE MATERIALES--------------------------*/
        /**
         * Obtener datos del detalle de la pre-reserva y abrir el modal.
         * 
         * @param int $id ID del detalle de la pre-reserva
         */
        public function mostrarModalValidarMaterial($id){
            /*--------------Almacenar el id del detalle de la pre-reserva-------------*/
                $this->id_material = $id;
            /*--------------Buscar el detalle de la pre-reserva-----------------------*/
                $material = PreStockpileDetail::find($id);
            /*--------------Obtener el nombre del material----------------------------*/
                $this->material = strtoupper($material->item->item);
            /*--------------Obtener la cantidad pedida del usuario en caso ya esté validado con otra cantidad---------------------------*/
                if($material->state == 'VALIDADO'){
                    $pre_stockpile_validate = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)
                                                                ->where('item_id',$material->item_id)
                                                                ->orderBy('id','ASC')->first();
                    $this->cantidad_pedida = floatval($pre_stockpile_validate->quantity);
                }else{
                    $this->cantidad_pedida = floatval($material->quantity);
                }

                $stock = GeneralStock::where('item_id',$material->item_id)
                                        ->where('sede_id',Auth::user()->location->sede_id)
                                        ->first();

                $this->cantidad_stock = floatval($stock->quantity_to_reserve + $this->cantidad_pedida);

            /*-------------Obtener cantidad del planner---------------------------------*/
                $this->cantidad = floatval($material->quantity);

            /*-----------Obtener demás datos del detalle de la pre-reserva--------------------------*/
                $this->estado_pre_reserva = $material->state;
                $this->measurement_unit = $material->item->measurementUnit->abbreviation;
                $this->open_validate_material = true;
        }
    /*---------CALCULAR ESTADO DE LA PRE-RESERVA ENTRE LA CANTIDAD SOLICITADA Y VALIDADA--------------------------------------------------------------------*/
        public function estadoPreReserva($solicitada,$validada){
            if($solicitada == $validada){
                return "ACEPTADO";
            }else{
                return "MODIFICADO";
            }
        }
    /*-------------------VALIDAR MATERIAL ------------------------------------*/
        public function validarMaterial(){
            $this->validate();
            /*---------Detalle de Pre-reserva pedido por el operador-----------*/
                $material = PreStockpileDetail::find($this->id_material);
            /*-------------Pedidos pendientes en validar----------------------*/
                if($this->estado_pre_reserva == "RESERVADO"){
                    /*-----------Verificar si se validó la pre-reserva-------*/
                        if($this->cantidad > 0){
                            /*------Crear el detalle de la pre-reserva validado por el planner---------------*/
                                PreStockpileDetail::create([
                                    'pre_stockpile_id' => $this->id_pre_reserva,
                                    'item_id' => $material->item_id,
                                    'quantity' => $this->cantidad,
                                    'state' => 'VALIDADO',
                                    'quantity_to_use' => $this->cantidad,
                                ]);
                            /*------Poner estado en Aceptado o Modificado según la cantidad-------------------*/
                                $material->state = $this->estadoPreReserva($this->cantidad_pedida,$this->cantidad);
                        }else{
                            /*------Rechazar la pre-reserva----------------------------------------------------*/
                                $material->state = 'RECHAZADO';
                        }
            /*---------------------Pedidos Validados-------------------------------------------------------------*/
                }elseif($this->estado_pre_reserva == "VALIDADO"){
                    /*-----------Obtener pre-reserva del operador--------------*/
                        $pre_stockpile_validate = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->where('item_id',$material->item_id)->orderBy('id','ASC')->first();
                    /*-----------Editar cantidad-------------------------------------------------------------------------------*/
                    if($this->cantidad > 0){
                        $material->quantity = $this->cantidad;
                        $material->quantity_to_use = $this->cantidad;
                        $pre_stockpile_validate->state = $this->estadoPreReserva($this->cantidad_pedida,$this->cantidad);
                    }else{
                        /*---------------------Poner pre-reserva ya validada como pendiente en validar----------------------*/
                            $pre_stockpile_validate->state = "RESERVADO";
                    }
                    $pre_stockpile_validate->save();
                }
            /*------Hacer en caso la pre-reserva este pendiente o validada----------*/
                if($this->estado_pre_reserva == "RESERVADO" || $this->estado_pre_reserva == "VALIDADO"){
                    /*------Eliminar validación en caso sea 0---------------------*/
                        if($this->estado_pre_reserva == "VALIDADO" && $this->cantidad <= 0){
                            $material->delete();
                    /*------Guardar cambios en caso no rechace el pedido-----------*/
                        }else{
                            $material->save();
                        }
                    /*-------Cerrar el modal de materiales--------------------*/
                        $this->open_validate_material = false;
                    /*-------Resetear campos----------------------------------*/
                    $this->reset('id_material','material','cantidad','cantidad_pedida');
                }
                $this->alerta();
        }
    /*--------------REINSERTAR RECHAZADOS------------------------*/
        public function reinsertarRechazado($id){
            $material = PreStockpileDetail::find($id);
            $material->state = "RESERVADO";
            $material->save();
        }
    /*------------VALIDAR PRE-RESERVA DEL OPERADOR----------------------------------------*/
        /*----------Mostrar modal de las pre-reservas------------*/
            public function mostrarPreReserva($id,$name,$lastname){
                $this->id_operador = $id;
                $this->operador = $name.' '.$lastname;
                $this->open_validate_pre_reserva = true;
            }
        /*----------Validar Pre-Reserva-------------------*/
            public function validarPreReserva(){
                /*--------------Verificar si no existe ningún material pendiente en validar--*/
                    if(PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->where('quantity','>',0)->where('state','PENDIENTE')->doesntExist()){
                        $pre_stockpile = PreStockpile::find($this->id_pre_reserva);
                        $pre_stockpile->state = "VALIDADO";
                        $pre_stockpile->validated_by = Auth::user()->id;
                        $pre_stockpile->save();
                        $this->resetExcept(['tsede','tlocation']);
                        $this->render();
                    }
            }
        /*----------Rechazar Pre-reserva-------------------------*/
            public function rechazarPreReserva(){
                $pre_stockpile = PreStockpile::find($this->id_pre_reserva);
                $pre_stockpile->state = "RECHAZADO";
                $pre_stockpile->save();
                $this->resetExcept(['tsede','tlocation']);
                $this->render();
            }
    /*---------------Alerta---------------------------------------------------------------*/
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
    /*------------RENDERIZAR VISTA------------------------------------------------------------------------*/
        public function render()
        {
            /*---------DATOS PARA LAS PRE-RESERVAS DEL OPERADOR--------------------------*/
                /*-----------Obtener la fecha de pre-reserva---------------------*/
                    if($pre_stockpile_date = PreStockpileDate::where('state','ABIERTO')->exists()){
                        $pre_stockpile_date = PreStockpileDate::where('state','ABIERTO')->first();
                        $this->fecha_pre_reserva = $pre_stockpile_date->pre_stockpile_date;
                    }else{
                        $this->fecha_pre_reserva = "";
                    }
                /*----------Mostrar sedes y ubicaciones-----------------------------------------*/
                    $sedes = Sede::where('zone_id',Auth::user()->location->sede->zone_id)->get();
                    $locations = Location::where('sede_id',$this->tsede)->get();
                /*-------------------------------------------------------------------------------------*/
                    if ($this->id_pre_reserva > 0) {
                        
                    /*-----------Obtener el implemento-----------------------*/
                    $implement = Implement::find($this->id_implemento);
                    /*-----------Obtener el modelo del implemento con su número------------------------*/
                        $this->implemento = $implement->implementModel->implement_model.' '.$implement->implement_number;
                    /*---------------------Obtener el monto Asignado para los meses de llegada del pedido-------------*/
                        $this->monto_asignado = CecoAllocationAmount::where('ceco_id',$implement->ceco_id)->whereDate('date',$this->fecha_pre_reserva)->sum('allocation_amount');
                    /*-------------------Obtener el monto usado por el ceco en total-------------------------------------------*/
                        $this->monto_usado = PreStockpileDetail::join('pre_stockpile_details as psd',function($join){
                                                                    $join->on('psd.pre_stockpile_id','pre_stockpile_details.pre_stockpile_id')->on('psd.item_id','pre_stockpile_details.item_id');                                        
                                                                })->join('pre_stockpiles',function($join){
                                                                    $join->on('pre_stockpiles.id','pre_stockpile_details.pre_stockpile_id');
                                                                })->join('pre_stockpile_price_details',function($join){
                                                                    $join->on('pre_stockpile_price_details.pre_stockpile_detail_id','psd.id');
                                                                })->join('general_stock_details',function($join){
                                                                    $join->on('general_stock_details.id','pre_stockpile_price_details.general_stock_detail_id');
                                                                })->join('implements',function($join){
                                                                    $join->on('implements.id','pre_stockpiles.implement_id');
                                                                })->where('pre_stockpile_details.state','VALIDADO')
                                                                ->where('psd.state','ACEPTADO')
                                                                ->orWhere('psd.state','MODIFICADO')
                                                                ->where('implements.ceco_id',$implement->ceco_id)
                                                                ->selectRaw('SUM(general_stock_details.price*pre_stockpile_price_details.quantity) AS total')
                                                                ->value('total');
                    /*-------------------Obtener el monto pre_reservado en total-------------------------------------------*/
                        $this->monto_pre_reservado = PreStockpileDetail::join('pre_stockpile_price_details',function($join){
                                                $join->on('pre_stockpile_price_details.pre_stockpile_detail_id','pre_stockpile_details.id');
                                            })->join('general_stock_details',function($join){
                                                $join->on('general_stock_details.id','pre_stockpile_price_details.general_stock_detail_id');
                                            })->where('pre_stockpile_details.state','RESERVADO')
                                              ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)
                                              ->selectRaw('SUM(general_stock_details.price*pre_stockpile_price_details.quantity) AS total')
                                              ->value('total');

                    /*-------------------Obtener el monto real por de la pre_reserva en total-------------------------------------------*/
                        $this->monto_real = PreStockpileDetail::join('pre_stockpile_price_details',function($join){
                                                $join->on('pre_stockpile_price_details.pre_stockpile_detail_id','pre_stockpile_details.id');
                                            })->join('general_stock_details',function($join){
                                                $join->on('general_stock_details.id','pre_stockpile_price_details.general_stock_detail_id');
                                            })->where('pre_stockpile_details.state','ACEPTADO')
                                              ->orWhere('pre_stockpile_details.state','MODIFICADO')
                                              ->where('pre_stockpile_details.pre_stockpile_id',$this->id_pre_reserva)
                                              ->selectRaw('SUM(general_stock_details.price*pre_stockpile_price_details.quantity) AS total')
                                              ->value('total');
                    }
                /*-------------------------------------------------------------------------------------*/
                /*---------Obtener las pre-reservas por ubicación y que estén cerradas-----------------*/
                if($this->tlocation > 0){
                    $pre_stockpiles = PreStockpile::join('implements',function($join){
                        $join->on('pre_stockpiles.implement_id','=','implements.id');
                    })->where('implements.location_id',$this->tlocation)->where('state','CERRADO')->get();
                }
                /*-----------------Obtener a los usuarios que tienen pre-reservas cerradas-------------*/
                    if(isset($pre_stockpiles)){
                        foreach($pre_stockpiles as $pre_stockpile){
                            array_push($this->incluidos,$pre_stockpile->user_id);
                        }
                    }
                /*----------------Mostrar a los usuarios que tienen pre-reservas cerradas--------------*/
                    $users = User::whereIn('id',$this->incluidos)->select('id','name','lastname')->get();
            /*---------------DATOS DEL MODAL PARA VALIDACION------------------------------------------------------*/
                /*--------------IMPLEMENTOS DEL OPERADOR------------------------------------*/
                    $implements = PreStockpile::join('implements', function($join){
                        $join->on('implements.id','pre_stockpiles.implement_id');
                    })->join('implement_models', function($join){
                        $join->on('implement_models.id','implements.implement_model_id');
                    })->where('pre_stockpiles.user_id',$this->id_operador)->select('implements.*','implement_models.implement_model')->get();

                    $pre_stockpile_detail_operator = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->where('quantity','>',0)->where('state','RESERVADO')->get();

                    $pre_stockpile_detail_planner = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)
                                                                        ->where('quantity','>',0)->where(function ($query){
                                                                            $query->where('state','VALIDADO');
                                                                        })->get();

                    $pre_stockpile_detail_rechazado = PreStockpileDetail::where('pre_stockpile_id',$this->id_pre_reserva)->where('quantity','>',0)->where('state','RECHAZADO')->get();

            return view('livewire.validate-pre-reserva',compact('sedes','locations','users','implements','pre_stockpile_detail_operator','pre_stockpile_detail_planner','pre_stockpile_detail_rechazado'));
        }
}
