import {computed, Injectable, signal} from '@angular/core'
import {AuthResponse, AuthUser, UserRole} from './auth.model'

@Injectable({providedIn: 'root'})
export class TokenStore {
  private readonly accessTokenSignal = signal<string | null>(null)
  private readonly refreshTokenSignal = signal<string | null>(null)
  private readonly userSignal = signal<AuthUser | null>(null)

  readonly accessToken = this.accessTokenSignal.asReadonly()
  readonly refreshToken = this.refreshTokenSignal.asReadonly()
  readonly currentUser = this.userSignal.asReadonly()
  readonly isAuthenticated = computed(() => this.accessTokenSignal() !== null)

  setSession(response: AuthResponse): void {
    this.accessTokenSignal.set(response.accessToken)
    this.refreshTokenSignal.set(response.refreshToken)
    this.userSignal.set(response.user)
  }

  updateUser(user: AuthUser): void{
    this.userSignal.set(user)
  }

  clear(): void {
    this.accessTokenSignal.set(null)
    this.refreshTokenSignal.set(null)
    this.userSignal.set(null)
  }

  hasRole(...roles: UserRole[]): boolean {
    const user = this.userSignal()
    return user !== null && roles.includes(user.role)
  }
}
