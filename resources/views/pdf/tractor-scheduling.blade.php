<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Programación de Tractores</title>
</head>
<body>
    @foreach ($schedule as $item)
        <table>
            <thead>
                <th>
                    <th>
                        <td>Operador</td>
                        <td>Tractor</td>
                        <td>Implemento</td>
                        <td>Labor</td>
                        <td>Lote</td>
                        <td>Día</td>
                        <td>Turno</td>
                    </th>
                </th>
            </thead>
            <tbody>
                <tr>
                    <td> {{$item->user->name}} </td>
                    <td> {{$item->implement->implementModel->implement_model}} {{$item->implement->implement_number}} </td>
                    <td> {{$item->tractor->tractorModel->model}} {{$item->tractor->tractor_number}} </td>
                    <td> {{$item->labor->labor}} </td>
                    <td> {{$item->lote->lote}} </td>
                    <td> {{$item->date}} </td>
                    <td> {{$item->shift}} </td>
                </tr>
            </tbody>
        </table>
    @endforeach
</body>
</html>