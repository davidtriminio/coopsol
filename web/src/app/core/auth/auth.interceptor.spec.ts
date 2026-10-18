import {HttpClient, provideHttpClient, withInterceptors} from '@angular/common/http'
import {HttpTestingController, provideHttpClientTesting} from '@angular/common/http/testing'
import {TokenStore} from './token-store'
import {authInterceptor} from '../../core/auth/auth.interceptor'
import { environment } from '../../../environments/environment'
import {AuthUser} from './auth.model'
import {afterEach, beforeEach, expect} from 'vitest'
import {TestBed} from '@angular/core/testing'

describe('authInterceptor', () => {
  let http: HttpClient
  let httpMock: HttpTestingController
  let tokenStore: TokenStore

  const user: AuthUser = {
    id: 'u1',
    email: 'cajero@coopsol.local',
    fullName: 'Cajero de Prueba',
    role: 'Cajero',
    isActive: true
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting()
      ]
    })

    http = TestBed.inject(HttpClient)
    httpMock = TestBed.inject(HttpTestingController)
    tokenStore = TestBed.inject(TokenStore)
  })

  afterEach(() => {
    httpMock.verify()
  })

  it('attaches the access token to request aimed at the api', () => {
    tokenStore.setSession({accessToken: 'access-1', expiresInSeconds: 900, user})

    http.get(`${environment.apiUrl}/api/socios`).subscribe()
    const req = httpMock.expectOne(`${environment.apiUrl}/api/socios`)
    expect(req.request.headers.get('Authorization')).toBe('Bearer access-1')
    req.flush({})
  })

  it('does not attach a token to requests outside the api', () => {
    tokenStore.setSession({ accessToken: 'access-1', expiresInSeconds: 900, user })

    http.get('https://otrodominio.example/data').subscribe()

    const req = httpMock.expectOne('https://otrodominio.example/data')
    expect(req.request.headers.has('Authorization')).toBe(false)
    req.flush({})
  })

  it('on a 401 it refreshes once and retries the original request', () => {
    tokenStore.setSession({ accessToken: 'expired-access', expiresInSeconds: 900, user })

    let result: unknown
    http.get(`${environment.apiUrl}/api/socios`).subscribe((r) => (result = r))

    httpMock.expectOne(`${environment.apiUrl}/api/socios`)
      .flush({}, { status: 401, statusText: 'Unauthorized' })

    const refreshReq = httpMock.expectOne(`${environment.apiUrl}/api/auth/refresh`)
    expect(refreshReq.request.body).toBeNull()
    expect(refreshReq.request.withCredentials).toBe(true)
    expect(refreshReq.request.headers.get('X-Auth-Mode')).toBe('cookie')
    refreshReq.flush({ accessToken: 'new-access', expiresInSeconds: 900, user })

    const retryReq = httpMock.expectOne(`${environment.apiUrl}/api/socios`)
    expect(retryReq.request.headers.get('Authorization')).toBe('Bearer new-access')
    retryReq.flush({ ok: true })

    expect(result).toEqual({ ok: true })
    expect(tokenStore.accessToken()).toBe('new-access')
  })

  it('does not try to refresh when the 401 comes from login itself', () => {
    let error: unknown
    http.post(`${environment.apiUrl}/api/auth/login`, { email: 'x', password: 'y' })
      .subscribe({ error: (e) => (error = e) })

    httpMock.expectOne(`${environment.apiUrl}/api/auth/login`)
      .flush({}, { status: 401, statusText: 'Unauthorized' })

    expect(error).toBeTruthy()
  })

  it('sends only one refresh when two requests fail with 401 at the same time', () => {
    tokenStore.setSession({ accessToken: 'expired-access', expiresInSeconds: 900, user })

    http.get(`${environment.apiUrl}/api/socios`).subscribe()
    http.get(`${environment.apiUrl}/api/prestamos`).subscribe()

    httpMock.expectOne(`${environment.apiUrl}/api/socios`).flush({}, { status: 401, statusText: 'Unauthorized' })
    httpMock.expectOne(`${environment.apiUrl}/api/prestamos`).flush({}, { status: 401, statusText: 'Unauthorized' })

    const refreshReq = httpMock.expectOne(`${environment.apiUrl}/api/auth/refresh`)
    refreshReq.flush({ accessToken: 'new-access', expiresInSeconds: 900, user })

    httpMock.expectOne(`${environment.apiUrl}/api/socios`).flush({})
    httpMock.expectOne(`${environment.apiUrl}/api/prestamos`).flush({})
  })

  it('clears the session and propagates the error when the refresh itself fails', () => {
    tokenStore.setSession({ accessToken: 'expired-access', expiresInSeconds: 900, user })

    let error: unknown
    http.get(`${environment.apiUrl}/api/socios`).subscribe({ error: (e) => (error = e) })

    httpMock.expectOne(`${environment.apiUrl}/api/socios`).flush({}, { status: 401, statusText: 'Unauthorized' })
    httpMock.expectOne(`${environment.apiUrl}/api/auth/refresh`).flush({}, { status: 401, statusText: 'Unauthorized' })

    expect(error).toBeTruthy()
    expect(tokenStore.accessToken()).toBeNull()
  })
})
