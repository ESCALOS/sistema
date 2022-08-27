@php
    $item = 0;
@endphp
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>Programación de Tractores del {{ $date }}</title>

    <style>
        html{
            margin-top: 1.4rem;
            margin-left: 2rem;
            margin-right: 2rem;
        }
        table{
            font-family: Arial, Helvetica, sans-serif;
            border-collapse: collapse;
            width: 100%;
            font-size: 12px;
            margin-top: 0.99rem;
        }
        th,td{
            border: 3px solid black;
            padding: 0.2rem;
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
        .title label{
            font-size: 22px;
            font-weight: 700;
        }
        .detalle label{
            font-size: 16px;
            font-weight: 400;
        }
        .page-break{
            page-break-before: always;
        }
        .checkbox {
            position: relative;
            width: 22px;
            height: 20px;
            border: 3px solid #555;
            margin-right: auto;
            margin-left: auto;
        }
        .checkbox label {
            position: absolute;
            width: 22px;
            height: 20px;
            top: 0px;
            left: 0px;

            -webkit-box-shadow: inset 0px 1px 1px rgba(0,0,0,0.5), 0px 1px 0px rgba(255,255,255,1);
            -moz-box-shadow: inset 0px 1px 1px rgba(0,0,0,0.5), 0px 1px 0px rgba(255,255,255,1);
            box-shadow: inset 0px 1px 1px rgba(0,0,0,0.5), 0px 1px 0px rgba(255,255,255,1);

            background: -webkit-linear-gradient(top, rgb(255, 255, 255) 0%, #ffffff 100%);
            background: -moz-linear-gradient(top, rgb(255, 255, 255) 0%, #ffffff 100%);
            background: -o-linear-gradient(top, #222 0%, #ffffff 100%);
            background: -ms-linear-gradient(top, #222 0%, #ffffff 100%);
            background: linear-gradient(top, #222 0%, #ffffff 100%);
            filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#222', endColorstr='#45484d',GradientType=0 );
        }
        .checkbox label:after {
            -ms-filter: "progid:DXImageTransform.Microsoft.Alpha(Opacity=30)";
            filter: alpha(opacity=30);
            opacity: 0.3;
            content: '';
            position: absolute;
            width: 9px;
            height: 5px;
            background: transparent;
            top: 4px;
            left: 4px;
            border: 3px solid #000000;
            border-top: none;
            border-right: none;

            -webkit-transform: rotate(-45deg);
            -moz-transform: rotate(-45deg);
            -o-transform: rotate(-45deg);
            -ms-transform: rotate(-45deg);
            transform: rotate(-45deg);
        }
        #observations {
            margin-top: 1rem;
            width: 100%;
            height: 200px;
            border-radius: 10px;
            border: 3px solid black;
            text-align: center;
        }
        #observations p {
            font-size: 18px;
            font-weight: 700;
            margin-top: 0.3rem;
            text-decoration-line: underline;
        }
    </style>

</head>
<body>
    <div>
        <div class="container">
            <div>
                @foreach ($implements as $implement)
                    <div class="sub{{ $loop->index > 0 ? ' page-break' : '' }}">
                        <div class="title">
                            <label>Rutinario del Implemento: {{ $implement->implement_model }} {{ $implement->implement_number }} </label>
                            <div class="detalle">
                                <label>Operador: {{ $implement->name }} {{$implement->lastname}} </label><br>
                                <label>Fecha: {{ $date }} </label>
                                <label>Turno: {{ $implement->shift }} </label>
                            </div>
                        </div>
                        <table>
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th>Componente</th>
                                    <th>Tarea</th>
                                    <th>¿Verficado?</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($tasks as $task)
                                    @if($task->routine_task_id == $implement->id)
                                        <tr>
                                            <td> {{++$item}} </td>
                                            <td> {{$task->component}} </td>
                                            <td> {{$task->task}} </td>
                                            <td>
                                                <div class="checkbox">
                                                    <label for="checkbox"></label>
                                                </div>
                                            </td>
                                        </tr>
                                    @endif
                                @endforeach
                            </tbody>
                        </table>
                        <div id="observations">
                            <p>Observaciones:</p>
                        </div>
                    </div>
                    @php
                        $item = 0;
                    @endphp
                @endforeach
            </div> 
        </div>
    </div>
</body>
</html>