import {inject, Injectable} from '@angular/core'
import {AuthApiService} from './auth-api.service'
import {TokenStore} from './token-store'
import {catchError, finalize, Observable, shareReplay, tap, throwError} from 'rxjs'
import {SessionResponse} from './auth.model';

@Injectable({providedIn: 'root'})
export class RefreshCoordinator {
  private readonly authApi = inject(AuthApiService)
  private readonly tokenStore = inject(TokenStore)
  private inFlight: Observable<SessionResponse> | null = null

  refresh(): Observable<SessionResponse> {
    if (this.inFlight) {
      return this.inFlight
    }

    this.inFlight = this.authApi.refresh().pipe(
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
