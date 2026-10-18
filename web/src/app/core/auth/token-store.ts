import {computed, Injectable, signal} from '@angular/core'
import {AuthUser, SessionResponse, UserRole} from './auth.model'

@Injectable({providedIn: 'root'})
export class TokenStore {
  private readonly accessTokenSignal = signal<string | null>(null)
  private readonly userSignal = signal<AuthUser | null>(null)

  readonly accessToken = this.accessTokenSignal.asReadonly()
  readonly currentUser = this.userSignal.asReadonly()
  readonly isAuthenticated = computed(() => this.accessTokenSignal() !== null)

  setSession(response: SessionResponse): void {
    this.accessTokenSignal.set(response.accessToken)
    this.userSignal.set(response.user)
  }

  updateUser(user: AuthUser): void {
    this.userSignal.set(user)
  }

  clear(): void {
    this.accessTokenSignal.set(null)
    this.userSignal.set(null)
  }

  hasRole(...roles: UserRole[]): boolean {
    const user = this.userSignal()
    return user !== null && roles.includes(user.role)
  }
}
