import {inject, Injectable} from '@angular/core'
import {AuthApiService} from './auth-api.service'
import {TokenStore} from './token-store'
import {AuthResponse} from './auth.model'
import {catchError, finalize, Observable, shareReplay, tap, throwError} from 'rxjs'

@Injectable({providedIn: 'root'})
export class RefreshCoordinator {
  private readonly authApi = inject(AuthApiService)
  private readonly tokenStore = inject(TokenStore)
  private inFlight: Observable<AuthResponse> | null = null

  refresh(): Observable<AuthResponse> {
    if (this.inFlight) {
      return this.inFlight
    }
    const refreshToken = this.tokenStore.refreshToken()
    if (!refreshToken) {
      this.tokenStore.clear()
      return throwError(() => new Error('No hay refresh token disponible.'))
    }

    this.inFlight = this.authApi.refresh({refreshToken}).pipe(
      tap((response) => this.tokenStore.setSession(response)),
      catchError((err) => {
        this.tokenStore.clear()
        return throwError(() => err)
      }),
      finalize(() => (this.inFlight = null)),
      shareReplay(1)
    )
    return this.inFlight
  }
}
