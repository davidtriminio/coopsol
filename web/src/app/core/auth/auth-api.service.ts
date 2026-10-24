import {inject, Injectable} from '@angular/core'
import {HttpClient} from '@angular/common/http'
import {environment} from "../../../environments/environment"
import {AuthUser, LoginRequest, SessionResponse} from './auth.model'
import {Observable} from 'rxjs'

const COOKIE_MODE = {
  headers: {'X-Auth-Mode': 'cookie'},
  withCredentials: true,
}

@Injectable({providedIn: 'root'})
export class AuthApiService {
  private readonly http = inject(HttpClient)
  private readonly baseUrl: string = `${environment.apiUrl}/api/auth`

  login(request: LoginRequest): Observable<SessionResponse> {
    return this.http.post<SessionResponse>(`${this.baseUrl}/login`, request, COOKIE_MODE)
  }

  refresh(): Observable<SessionResponse> {
    return this.http.post<SessionResponse>(`${this.baseUrl}/refresh`, null, COOKIE_MODE)
  }

  logout(): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/logout`, null, COOKIE_MODE)
  }

  me(): Observable<AuthUser> {
    return this.http.get<AuthUser>(`${this.baseUrl}/me`)
  }
}
