import {SessionResponse} from './auth.model';
import {beforeEach, expect, it} from 'vitest';
import {TokenStore} from './token-store';

describe('TokenStore', () => {
  let store: TokenStore

  const response: SessionResponse = {
    accessToken: 'access-123',
    expiresInSeconds: 900,
    user: {
      id: 'a1b2c3d4-0000-0000-0000-000000000000',
      email: 'cajero@coopsol.local',
      fullName: 'Cajero de Prueba',
      role: 'Cajero',
      isActive: true,
    }
  }

  beforeEach(() => {
    store = new TokenStore()
  })

  it('starts with no session', () => {
    expect(store.isAuthenticated()).toBe(false)
    expect(store.accessToken()).toBeNull()
    expect(store.currentUser()).toBeNull()
  })

  it('setSession stores the access token and the user', () => {
    store.setSession(response)

    expect(store.isAuthenticated()).toBe(true)
    expect(store.accessToken()).toBe('access-123')
    expect(store.currentUser()).toEqual(response.user)
  })

  it('clear resets the session', () => {
    store.setSession(response)

    store.clear()

    expect(store.isAuthenticated()).toBe(false)
    expect(store.accessToken()).toBeNull()
    expect(store.currentUser()).toBeNull()
  })

  it('hasRole returns the only when the current user has one of the given roles', () => {
    store.setSession(response)

    expect(store.hasRole('Cajero')).toBe(true)
    expect(store.hasRole('Admin', 'Cajero')).toBe(true)
    expect(store.hasRole('Admin', 'Gerente')).toBe(false)
  })

  it('hasRole returns false when there is no session', () => {
    expect(store.hasRole('Admin')).toBe(false)
  })
})
