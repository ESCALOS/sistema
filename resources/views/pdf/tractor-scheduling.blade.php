<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>Programación de Tractores del {{ $fecha }}</title>

    <style>
        html{
            margin-top: 0.2rem;
            margin-left: 2rem;
            margin-right: 2rem;
        }
        table{
            font-family: Arial, Helvetica, sans-serif;
            border-collapse: collapse;
            width: 100%;
            font-size: 15px;
        }
        th,td{
            border: 3px solid black;
            padding: 1rem;
            text-align: center
        }
        .container{
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .sub{
            padding-bottom: 0.5rem;
            margin-top: 0.5rem;
        }
        .title{
            text-align: center;
            align-items: center;
        }
        .page-break{
            page-break-before: always;
        }
    </style>

</head>
<body>
    <div>
        <div class="container">
            <div>
                <div class="sub">
                    <div class="title">
                        <h2>
                            Programación de Tractores del {{ $fecha }} Turno Mañana 
                        </h2>
                    </div>
                    <table>
                        <thead>
                            <th>Operador</th>
                            <th>Tractor</th>
                            <th>Implemento</th>
                            <th>Labor</th>
                            <th>Lote</th>
                        </thead>
                        <tbody>
                            @foreach ($schedule as $item)
                                @if ($item->shift == "MAÑANA")
                                    <tr>
                                        <td> {{$item->user->name}} </td>
                                        <td> {{$item->implement->implementModel->implement_model}} {{$item->implement->implement_number}} </td>
                                        <td> {{$item->tractor->tractorModel->model}} {{$item->tractor->tractor_number}} </td>
                                        <td> {{$item->labor->labor}} </td>
                                        <td> {{$item->lote->lote}} </td>
                                    </tr>   
                                @endif
                            @endforeach
                        </tbody>
                    </table>
                </div>
                <div class="sub page-break">
                    <div class="title">
                        <h2>Programación de Tractores del {{ $fecha }} Turno Noche </h2>
                    </div>
                    <table>
                        <thead>
                            <th>Operador</th>
                            <th>Tractor</th>
                            <th>Implemento</th>
                            <th>Labor</th>
                            <th>Lote</th>
                        </thead>
                        <tbody>
                            @foreach ($schedule as $item)
                                @if ($item->shift == "NOCHE")
                                    <tr>
                                        <td> {{$item->user->name}} </td>
                                        <td> {{$item->implement->implementModel->implement_model}} {{$item->implement->implement_number}} </td>
                                        <td> {{$item->tractor->tractorModel->model}} {{$item->tractor->tractor_number}} </td>
                                        <td> {{$item->labor->labor}} </td>
                                        <td> {{$item->lote->lote}} </td>
                                    </tr>   
                                @endif
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div> 
        </div>
    </div>

</body>
</html>