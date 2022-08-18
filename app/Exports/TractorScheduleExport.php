<?php

namespace App\Exports;

use App\Models\TractorScheduling;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class TractorScheduleExport implements FromCollection,ShouldAutoSize,WithHeadings,WithStyles
{

    private $start_date;
    private $end_date;

    public function __construct($dia_inicial,$dia_final) {
        $this->start_date = $dia_inicial;
        $this->end_date = $dia_final;
    }

    public function headings(): array
    {
        return [
            'Operador',
            'Tractor',
            'Implemento',
            'Fecha',
            'Turno',
            'Lote',
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
        return TractorScheduling::all();
    }
}
