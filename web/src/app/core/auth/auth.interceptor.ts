import {HttpErrorResponse, HttpInterceptorFn} from '@angular/common/http';
import {environment} from '../../../environments/environment';
import {inject} from '@angular/core';
import {TokenStore} from './token-store';
import {RefreshCoordinator} from './refresh-coordinator';
import {catchError, switchMap, throwError} from 'rxjs';

const REFRESH_EXEMPT_PATHS = ['/api/auth/login', '/api/auth/refresh']

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.startsWith(environment.apiUrl)){
    return next(req)
  }

  const tokenStore = inject(TokenStore)
  const refreshCoordinator = inject(RefreshCoordinator)

  const accessToken = tokenStore.accessToken()
  const authorizedReq = accessToken ? req.clone({setHeaders: {Authorization: `Bearer ${accessToken}`}}) : req
  return next(authorizedReq).pipe(
    catchError((error: unknown)=> {
      const isUnauthorized = error instanceof HttpErrorResponse && error.status === 401
      const isExempt = REFRESH_EXEMPT_PATHS.some((path) => req.url.includes(path))

      if (!isUnauthorized || isExempt){
        return throwError(() => error)
      }

      return refreshCoordinator.refresh().pipe(
        switchMap((response) =>
        next(req.clone({setHeaders: {Authorization: `Bearer ${response.accessToken}`}})))
      )
    })
  )
}
