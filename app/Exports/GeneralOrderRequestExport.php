<?php

namespace App\Exports;

use App\Models\GeneralOrderRequest;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class GeneralOrderRequestExport implements FromCollection,ShouldAutoSize,WithHeadings,WithStyles
{
    private $fecha_pedido;

    public function __construct($fecha_pedido) {
        $this->fecha_pedido = $fecha_pedido;
    }
    
    public function headings(): array
    {
        return [
            'codigo',
            'detalle',
            'centro',
            'precio',
            'unidad',
            'pedido',
            'pendiente',
            'cantidad'
        ];
    }

    public function styles(Worksheet $sheet)
    {
        return [
            1    => [
                        'font' => [
                                    'bold' => true,
                                    'size'=> 12
                                ]
                    ],
        ];
    }

    public function collection()
    {
        return GeneralOrderRequest::join('items',function($join){
            $join->on('items.id','general_order_requests.item_id');
        })->join('measurement_units',function($join){
            $join->on('measurement_units.id','items.measurement_unit_id');
        })->join('sedes',function($join){
            $join->on('sedes.id','general_order_requests.sede_id');
        })->join('order_dates',function($join){
            $join->on('order_dates.id','general_order_requests.order_date_id');
        })->where('general_order_requests.order_date_id',$this->fecha_pedido)
        ->where('general_order_requests.quantity_to_arrive','>',0)
        ->select('items.sku','items.item','sedes.code','general_order_requests.price','measurement_units.abbreviation','order_dates.order_date','general_order_requests.quantity_to_arrive')->get();
    }
}
