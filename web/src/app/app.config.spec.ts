import {ApplicationInitStatus} from '@angular/core'
import {HttpTestingController, provideHttpClientTesting} from '@angular/common/http/testing'
import {TestBed} from '@angular/core/testing'
import {beforeEach, expect, it} from 'vitest'
import {environment} from '../environments/environment'
import {appConfig} from './app.config'
import {TokenStore} from './core/auth/token-store'

describe('appConfig session restore', () => {
  const refreshUrl = `${environment.apiUrl}/api/auth/refresh`

  const session = {
    accessToken: 'access-1',
    expiresInSeconds: 900,
    user: {
      id: 'u1',
      email: 'admin@coopsol.local',
      fullName: 'Admin de Prueba',
      role: 'Admin',
      isActive: true
    }
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [...appConfig.providers, provideHttpClientTesting()]
    })
  })

  it('holds the app initialization until the session is restored', async () => {
    const httpMock = TestBed.inject(HttpTestingController)
    const initStatus = TestBed.inject(ApplicationInitStatus)

    let initialized = false
    initStatus.donePromise.then(() => (initialized = true))
    await Promise.resolve()
    expect(initialized).toBe(false)

    httpMock.expectOne(refreshUrl).flush(session)
    await initStatus.donePromise

    expect(initialized).toBe(true)
    expect(TestBed.inject(TokenStore).isAuthenticated()).toBe(true)
    httpMock.verify()
  })

  it('finishes initializing without a session when the refresh is rejected', async () => {
    const httpMock = TestBed.inject(HttpTestingController)
    const initStatus = TestBed.inject(ApplicationInitStatus)

    httpMock.expectOne(refreshUrl).flush({}, {status: 401, statusText: 'Unauthorized'})
    await initStatus.donePromise

    expect(TestBed.inject(TokenStore).isAuthenticated()).toBe(false)
    httpMock.verify()
  })
})
