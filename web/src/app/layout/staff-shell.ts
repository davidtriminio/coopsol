import {ChangeDetectionStrategy, Component, inject} from '@angular/core';
import {AuthService} from '../core/auth/auth.service';
import {RouterOutlet} from '@angular/router';

@Component({
  selector: 'app-staff-shell',
  standalone: true,
  imports: [
    RouterOutlet
  ],
  templateUrl: './staff-shell.html',
  styleUrl: './staff-shell.css',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class StaffShell {
  private readonly authService = inject(AuthService)
  readonly currentUser = this.authService.currentUser
}
