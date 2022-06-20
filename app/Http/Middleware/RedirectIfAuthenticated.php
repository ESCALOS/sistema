<?php

namespace App\Http\Middleware;

use App\Providers\RouteServiceProvider;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RedirectIfAuthenticated
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @param  string|null  ...$guards
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next, ...$guards)
    {
        $guards = empty($guards) ? [null] : $guards;

        foreach ($guards as $guard) {
            if (Auth::guard($guard)->check()) {
                switch (auth()->user()->role) {
                    case 'administrador':
                        return route('admin.user.index');
                        break;

                    case 'asistente':
                        return route('asistent.index');
                        break;
                    
                    case 'operador':
                        return route('operator.request-materials');
                        break;

                    case 'planner':
                        return route('planner.validate-request-materials');
                        break;
                    
                    case 'supervisor':
                        return route('overseer.tractor-scheduling');
                        break;
                    
                    default:
                        auth()->logout();
                        return redirect('/');
                        break;
                }
                //return redirect(RouteServiceProvider::HOME);
            }
        }

        return $next($request);
    }
}
