<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

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
            'guard_name' => 'admin',
        ]);

        $asistent = Role::create([
            'name' => 'asistente',
            'guard_name' => 'asistent',
        ]);

        $operator = Role::create([
            'name' => 'operador',
            'guard_name' => 'operator',
        ]);

        $planner = Role::create([
            'name' => 'planner',
            'guard_name' => 'planner',
        ]);

        $supervisor = Role::create([
            'name' => 'supervisor',
            'guard_name' => 'overseer',
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
        ])->syncRoles(['asistente']);

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
        ])->syncRoles(['administrador']);

    }
}
