import {Routes} from '@angular/router';
import {authGuard} from './core/auth/auth.guard';
import { roleGuard } from './core/auth/role.guard'

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/login/login').then((m) => m.Login)
  },
  {
    path: '',
    loadComponent: () => import('./layout/staff-shell').then((m) => m.StaffShell),
    canActivate: [authGuard],
    children: [
      {
        path: 'profile',
        loadComponent: () => import('./features/profile/profile').then((m) => m.Profile)
      },
      {
        path: 'admin/users/new',
        loadComponent: () => import('./features/admin/create-staff-user/create-staff-user').then((m) => m.CreateStaffUser),
        canActivate: [roleGuard('Admin')]
      }
    ]
  },
  {
    path: '**',
    redirectTo: ''
  }
];
