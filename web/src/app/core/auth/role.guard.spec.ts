import { AuthResponse, UserRole } from './auth.model'
import { TokenStore } from './token-store'
import { provideRouter, Router, UrlTree } from '@angular/router'
import { TestBed } from '@angular/core/testing'
import { roleGuard } from './role.guard'

function buildAuthResponse(role: UserRole): AuthResponse{
  return {
    accessToken: 'fake-access-token',
    refreshToken: 'fake-refresh-token',
    expiresInSeconds: 900,
    user: {
      id: 'u1',
      email: 'user@coopsol.local',
      fullName: 'Usuario de prueba',
      role,
      isActive: true
    },
  }
}

describe('roleGuard', () => {
  let tokenStore: TokenStore
  let router: Router

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideRouter([])],
    })
    tokenStore = TestBed.inject(TokenStore)
    router = TestBed.inject(Router)
  })

  function runGuard(...roles: UserRole[]) {
    const guard = roleGuard(...roles)
    return TestBed.runInInjectionContext(() => guard({} as never, {} as never))
  }

  it('redirects to /login when there is no session', () => {
    const result = runGuard('Admin') as UrlTree

    expect(router.serializeUrl(result)).toBe('/login')
  })

  it('redirects to / when the session role is not allowed', () => {
    tokenStore.setSession(buildAuthResponse('Socio'))

    const result = runGuard('Admin') as UrlTree

    expect(router.serializeUrl(result)).toBe('/')
  })

  it('allows navigation when the session role is allowed', () => {
    tokenStore.setSession(buildAuthResponse('Admin'))

    expect(runGuard('Admin')).toBe(true)
  })

  it('allows navigation when the session role matches one of several allowed roles', () => {
    tokenStore.setSession(buildAuthResponse('Gerente'))

    expect(runGuard('Admin', 'Gerente')).toBe(true)
  })

})
