import {inject, Injectable} from '@angular/core';
import {AuthApiService} from './auth-api.service';
import {TokenStore} from './token-store';
import {AuthResponse, AuthUser, LoginRequest} from './auth.model';
import {Observable, tap} from 'rxjs';

@Injectable({providedIn: 'root'})
export class AuthService {
  private readonly authApi = inject(AuthApiService)
  private readonly tokenStore = inject(TokenStore)

  readonly isAuthenticated = this.tokenStore.isAuthenticated
  readonly currentUser = this.tokenStore.currentUser

  login(request: LoginRequest): Observable<AuthResponse>{
    return this.authApi.login(request).pipe(
      tap((response) => this.tokenStore.setSession(response))
    )
  }

  refreshProfile(): Observable<AuthUser>{
    return this.authApi.me().pipe(
      tap((user) => this.tokenStore.updateUser(user))
    )
  }
}
