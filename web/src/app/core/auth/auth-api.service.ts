import {inject, Injectable} from '@angular/core'
import {HttpClient} from '@angular/common/http'
import {environment} from "../../../environments/environment"
import {AuthResponse, AuthUser, LoginRequest, RefreshTokenRequest} from './auth.model'
import {Observable} from 'rxjs'

@Injectable({providedIn: 'root'})
export class AuthApiService {
  private readonly http = inject(HttpClient)
  private readonly baseUrl: string = `${environment.apiUrl}/api/auth`

  login(request: LoginRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/login`, request)
  }

  refresh(request: RefreshTokenRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.baseUrl}/refresh`, request)
  }

  logout(request: RefreshTokenRequest): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/logout`, request)
  }

  me():Observable<AuthUser>{
    return this.http.get<AuthUser>(`${this.baseUrl}/me`)
  }
}
