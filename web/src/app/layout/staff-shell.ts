import {ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import {AuthService} from '../core/auth/auth.service';
import { Router, RouterLink, RouterOutlet } from '@angular/router'
import { routes } from '../app.routes'

@Component({
  selector: 'app-staff-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink],
  templateUrl: './staff-shell.html',
  styleUrl: './staff-shell.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class StaffShell {
  private readonly authService = inject(AuthService)
  private readonly router = inject(Router)

  readonly currentUser = this.authService.currentUser
  readonly loggingOut = signal(false)

  logout(): void {
    this.loggingOut.set(true)

    this.authService.logout().subscribe(() => {
      this.router.navigateByUrl('/login')
    })
  }
}
