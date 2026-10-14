import { AuthResponse } from './auth.model'
import { TokenStore } from './token-store'
import { provideRouter, Router, UrlTree } from '@angular/router'
import { TestBed } from '@angular/core/testing'
import { authGuard } from './auth.guard'

function buildAuthResponse(): AuthResponse {
  return {
    expiresInSeconds: 900,
    accessToken: 'fake-access-token',
    refreshToken: 'fake-refresh-token',
    user: {
      id: 'u1',
      email: 'admin@coopsol.local',
      fullName: 'Admin de prueba',
      role: 'Admin',
      isActive: true,
    },
  }
}

describe('authGuard', () => {
  let tokenStore: TokenStore
  let router: Router

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideRouter([])],
    })
    tokenStore = TestBed.inject(TokenStore)
    router = TestBed.inject(Router)
  })

  function runGuard() {
    return TestBed.runInInjectionContext(() => authGuard({} as never, {} as never))
  }

  it('allows navigation when there is an active session', () => {
    tokenStore.setSession(buildAuthResponse())

    expect(runGuard()).toBe(true)
  })

  it('redirects to /login when there is no session', () => {
    const result = runGuard() as UrlTree

    expect(router.serializeUrl(result)).toBe('/login')
  })
})
