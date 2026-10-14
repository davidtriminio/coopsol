import { UserRole } from '../../core/auth/auth.model'
import { ChangeDetectionStrategy, Component, inject, OnInit, signal } from '@angular/core'
import { AuthService } from '../../core/auth/auth.service'
import { Router } from '@angular/router'

const ROLE_LABELS: Record<UserRole, string> = {
  Socio: 'Socio',
  Cajero: 'Cajero',
  OficialCredito: 'Oficial crédito',
  Gerente: 'Gerente',
  Admin: 'Administrador'
}

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [],
  templateUrl: './profile.html',
  styleUrl: './profile.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Profile implements OnInit {
  private readonly authService = inject(AuthService)
  private readonly router = inject(Router)

  readonly currentUser = this.authService.currentUser
  readonly roleLabels = ROLE_LABELS
  readonly refreshing = signal(false)
  readonly loggingOut = signal(false)
  readonly errorMessage = signal<string | null>(null)

  ngOnInit() : void {
    this.refresh()
  }

  refresh(): void {
    this.refreshing.set(true)
    this.errorMessage.set(null)

    this.authService.refreshProfile().subscribe({
      next: () => this.refreshing.set(false),
      error: () => {
        this.refreshing.set(false)
        this.errorMessage.set('No se pudo actualizar tu perfil. Intenta de nuevo.')
      }
    })
  }

  logout(): void {
    this.loggingOut.set(true)

    this.authService.logout().subscribe(() => {
      this.router.navigateByUrl('/login')
    })
  }
}
