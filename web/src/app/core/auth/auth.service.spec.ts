import {provideHttpClient} from '@angular/common/http'
import {HttpTestingController, provideHttpClientTesting} from '@angular/common/http/testing'
import {TestBed} from '@angular/core/testing'
import {afterEach, beforeEach, expect, it} from 'vitest'
import {environment} from '../../../environments/environment'
import {AuthService} from './auth.service'
import {AuthUser, SessionResponse} from './auth.model'
import {TokenStore} from './token-store'

describe('AuthService', () => {
  let service: AuthService
  let tokenStore: TokenStore
  let httpMock: HttpTestingController

  const user: AuthUser = {
    id: 'u1',
    email: 'admin@coopsol.local',
    fullName: 'Admin de Prueba',
    role: 'Admin',
    isActive: true
  }

  const session: SessionResponse = {accessToken: 'access-1', expiresInSeconds: 900, user}

  const loginUrl = `${environment.apiUrl}/api/auth/login`
  const refreshUrl = `${environment.apiUrl}/api/auth/refresh`
  const logoutUrl = `${environment.apiUrl}/api/auth/logout`
  const meUrl = `${environment.apiUrl}/api/auth/me`

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()]
    })

    service = TestBed.inject(AuthService)
    tokenStore = TestBed.inject(TokenStore)
    httpMock = TestBed.inject(HttpTestingController)
  })

  afterEach(() => {
    httpMock.verify()
  })

  it('login stores the session', () => {
    service.login({email: user.email, password: 'secret'}).subscribe()

    httpMock.expectOne(loginUrl).flush(session)

    expect(service.isAuthenticated()).toBe(true)
    expect(tokenStore.accessToken()).toBe('access-1')
    expect(service.currentUser()).toEqual(user)
  })

  it('restoreSession emits true and stores the session when the cookie is valid', () => {
    let restored: boolean | undefined
    service.restoreSession().subscribe((value) => (restored = value))

    httpMock.expectOne(refreshUrl).flush(session)

    expect(restored).toBe(true)
    expect(tokenStore.accessToken()).toBe('access-1')
    expect(service.currentUser()).toEqual(user)
  })

  it('restoreSession emits false without a session when there is no valid cookie', () => {
    let restored: boolean | undefined
    service.restoreSession().subscribe((value) => (restored = value))

    httpMock.expectOne(refreshUrl).flush({}, {status: 401, statusText: 'Unauthorized'})

    expect(restored).toBe(false)
    expect(service.isAuthenticated()).toBe(false)
    expect(tokenStore.currentUser()).toBeNull()
  })

  it('restoreSession emits false instead of failing when the server is unreachable', () => {
    let restored: boolean | undefined
    let failed = false
    service.restoreSession().subscribe({
      next: (value) => (restored = value),
      error: () => (failed = true)
    })

    httpMock.expectOne(refreshUrl).error(new ProgressEvent('error'))

    expect(failed).toBe(false)
    expect(restored).toBe(false)
  })

  it('logout calls the api and clears the session', () => {
    tokenStore.setSession(session)

    let completed = false
    service.logout().subscribe({complete: () => (completed = true)})

    const req = httpMock.expectOne(logoutUrl)
    expect(req.request.method).toBe('POST')
    req.flush(null)

    expect(completed).toBe(true)
    expect(service.isAuthenticated()).toBe(false)
  })

  it('logout clears the session even when the api call fails', () => {
    tokenStore.setSession(session)

    let completed = false
    service.logout().subscribe({complete: () => (completed = true)})

    httpMock.expectOne(logoutUrl).flush({}, {status: 500, statusText: 'Server Error'})

    expect(completed).toBe(true)
    expect(service.isAuthenticated()).toBe(false)
  })

  it('refreshProfile updates the user in the store', () => {
    tokenStore.setSession(session)
    const updated: AuthUser = {...user, fullName: 'Admin Renombrado'}

    service.refreshProfile().subscribe()

    httpMock.expectOne(meUrl).flush(updated)

    expect(service.currentUser()?.fullName).toBe('Admin Renombrado')
  })
})
