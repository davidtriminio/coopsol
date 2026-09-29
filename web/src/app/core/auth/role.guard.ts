import {CanActivateFn, Router} from '@angular/router'
import {UserRole} from './auth.model';
import {inject} from '@angular/core';
import {TokenStore} from './token-store';

export const roleGuard = (...roles: UserRole[]): CanActivateFn => () => {
  const tokenStore = inject(TokenStore)
  const router = inject(Router)

  if (!tokenStore.isAuthenticated()) {
    return router.createUrlTree(['/login'])
  }

  if (tokenStore.hasRole(...roles)) {
    return true
  }

  return router.createUrlTree([''])
}
