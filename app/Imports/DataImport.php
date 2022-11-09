<?php
    namespace App\Imports;

    use Maatwebsite\Excel\Concerns\WithMultipleSheets;
    use Maatwebsite\Excel\Concerns\WithConditionalSheets;

    class DataImport implements WithMultipleSheets 
    {
        use WithConditionalSheets;

        public function conditionalSheets(): array
        {
            return [
                'Personal' => new RolesImport(),
                'Tractores' => new TractorsImport(),
                'Implementos' => new ImplementsImport(),
                'Lotes' => new LotesImport()
            ];
        }
    }