import { AuthApiService } from "./auth-api.service"
import {HttpTestingController, provideHttpClientTesting} from '@angular/common/http/testing';
import {TestBed} from '@angular/core/testing';
import {afterEach, beforeEach, describe, expect, it} from 'vitest';
import {provideHttpClient} from '@angular/common/http';
import {environment} from '../../../environments/environment';

describe('AuthApiService', () => {
  let api: AuthApiService
  let httpMock: HttpTestingController

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()]
    })

    api = TestBed.inject(AuthApiService)
    httpMock = TestBed.inject(HttpTestingController)
  })

  afterEach(() => {
    httpMock.verify()
  })

  it('login posts the credentials in cookie mode and with credentials', () => {
    const credentials = {email: 'admin@coopsol.local', password: 'secret'}

    api.login(credentials).subscribe()

    const req = httpMock.expectOne(`${environment.apiUrl}/api/auth/login`)
    expect(req.request.method).toBe('POST')
    expect(req.request.body).toEqual(credentials)
    expect(req.request.headers.get('X-Auth-Mode')).toBe('cookie')
    expect(req.request.withCredentials).toBe(true)
    req.flush({})
  })

  it('refresh posts without a body, in cookie mode and with credentials', () => {
    api.refresh().subscribe()

    const req = httpMock.expectOne(`${environment.apiUrl}/api/auth/refresh`)
    expect(req.request.method).toBe('POST')
    expect(req.request.body).toBeNull()
    expect(req.request.headers.get('X-Auth-Mode')).toBe('cookie')
    expect(req.request.withCredentials).toBe(true)
    req.flush({})
  })

  it('logout posts without a body, in cookie mode and with credentials', () => {
    api.logout().subscribe()

    const req = httpMock.expectOne(`${environment.apiUrl}/api/auth/logout`)
    expect(req.request.method).toBe('POST')
    expect(req.request.body).toBeNull()
    expect(req.request.headers.get('X-Auth-Mode')).toBe('cookie')
    expect(req.request.withCredentials).toBe(true)
    req.flush(null)
  })

  it('me does not use cookie mode or credentials', () => {
    api.me().subscribe()

    const req = httpMock.expectOne(`${environment.apiUrl}/api/auth/me`)
    expect(req.request.method).toBe('GET')
    expect(req.request.headers.has('X-Auth-Mode')).toBe(false)
    expect(req.request.withCredentials).toBe(false)
    req.flush({})
  })
})
