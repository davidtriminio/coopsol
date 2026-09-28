export type UserRole = 'Socio' | 'Cajero' | 'OficialCredito' | 'Gerente' | 'Admin'

export interface AuthUser{
  id: string
  email: string
  fullName: string
  role: UserRole
  isActive: boolean
}

export interface LoginRequest {
  email: string
  password: string
}

export interface RefreshTokenRequest {
  refreshToken: string
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  expiresInSeconds: number
  user: AuthUser
}

export interface CreateStaffUserRequest{
  email: string
  password: string
  fullName: string
  role: UserRole
}
