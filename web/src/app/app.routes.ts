import {Routes} from '@angular/router';
import {authGuard} from './core/auth/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/login/login').then((m) => m.Login)
  },
  {
    path: '',
    loadComponent: () => import('./layout/staff-shell').then((m) => m.StaffShell),
    canActivate: [authGuard],
    children: []
  },
  {
    path: '**',
    redirectTo: ''
  }
];
