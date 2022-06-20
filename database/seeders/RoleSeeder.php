<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $admin = Role::create([
            'name' => 'administrador',
        ]);

        $asistent = Role::create([
            'name' => 'asistente',
        ]);

        $operador = Role::create([
            'name' => 'operador',
        ]);

        $planner = Role::create([
            'name' => 'planner',
        ]);

        $supervisor = Role::create([
            'name' => 'supervisor',
        ]);

        $jefe = Role::create([
            'name' => 'jefe',
        ]);

        Permission::create([
            'name' => 'overseer.tractor-scheduling',
            'guard_name' => 'overseer',
        ])->syncRoles(['supervisor']);

        Permission::create([
            'name' => 'asistent.index',
            'guard_name' => 'asistent',
        ])->syncRoles(['asistent']);

        Permission::create([
            'name' => 'operator.request-materials',
            'guard_name' => 'operator',
        ])->syncRoles(['operador']);

        Permission::create([
            'name' => 'planner.validate-request-materials',
            'guard_name' => 'planner',
        ])->syncRoles(['planner']);

        Permission::create([
            'name' => 'admin.user.index',
            'guard_name' => 'admin',
        ])->syncRoles(['admin']);

    }
}
