import {inject, Injectable} from '@angular/core'
import {AuthApiService} from './auth-api.service'
import {TokenStore} from './token-store'
import {AuthUser, LoginRequest, SessionResponse} from './auth.model'
import {catchError, map, Observable, of, tap} from 'rxjs'
import {RefreshCoordinator} from './refresh-coordinator';

@Injectable({providedIn: 'root'})
export class AuthService {
  private readonly authApi = inject(AuthApiService)
  private readonly refreshCoordinator = inject(RefreshCoordinator)
  private readonly tokenStore = inject(TokenStore)

  readonly isAuthenticated = this.tokenStore.isAuthenticated
  readonly currentUser = this.tokenStore.currentUser

  login(request: LoginRequest): Observable<SessionResponse> {
    return this.authApi.login(request).pipe(
      tap((response) => this.tokenStore.setSession(response))
    )
  }

  restoreSession(): Observable<boolean>{
    return this.refreshCoordinator.refresh().pipe(
      map(() => true),
      catchError(() => of(false))
    )
  }

  refreshProfile(): Observable<AuthUser> {
    return this.authApi.me().pipe(
      tap((user) => this.tokenStore.updateUser(user))
    )
  }

  logout(): Observable<void> {
    return this.authApi.logout().pipe(
      catchError(() => of(void 0)),
      tap(() => this.tokenStore.clear())
    )
  }
}
