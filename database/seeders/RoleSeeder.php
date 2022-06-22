<?php

namespace Database\Seeders;

use App\Models\User;
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
            'name' => 'asistent',
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

        $users = User::all();
        $user1 = $users->find(1);

        $roles = Role::all();
        $role1 = Role::find(1);

        $user1->assignRole($role1);

        $users = User::all();
        $user2 = $users->find(2);

        $roles = Role::all();
        $role2 = Role::find(2);

        $user2->assignRole($role2);

        $users = User::all();
        $user3 = $users->find(3);

        $roles = Role::all();
        $role3 = Role::find(3);

        $user3->assignRole($role3);

        $users = User::all();
        $user4 = $users->find(4);

        $roles = Role::all();
        $role4 = Role::find(4);

        $user4->assignRole($role4);

        $users = User::all();
        $user5 = $users->find(5);

        $roles = Role::all();
        $role5 = Role::find(5);

        $user5->assignRole($role5);


    }
}
