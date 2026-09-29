import {Component, inject, signal} from '@angular/core';
import {FormBuilder, ReactiveFormsModule, Validators} from '@angular/forms';
import {HttpErrorResponse} from '@angular/common/http';
import {AuthService} from '../../core/auth/auth.service';

@Component({
  imports: [
    ReactiveFormsModule
  ],
  selector: 'app-login',
  templateUrl: './login.html',
  styleUrl: './login.css'
})
export class Login {
  private readonly fb = inject(FormBuilder)
  private readonly authService = inject(AuthService)

  readonly form = this.fb.nonNullable.group({
    email: ['', Validators.required, Validators.email],
    password: ['', Validators.required]
  })

  readonly loading = signal(false)
  readonly errorMessage = signal<string | null>(null)
  readonly loggedInUser = signal<string | null>(null)

  submit(): void {
    if (this.form.invalid || this.loading()) {
      this.form.markAllAsTouched()
      return
    }

    this.loading.set(true)
    this.errorMessage.set(null)

    this.authService.login(this.form.getRawValue()).subscribe({
      next: (response) => {
        this.loading.set(false)
        this.loggedInUser.set(`${response.user.fullName} (${response.user.role})`)
      },
      error: (err: unknown) => {
        this.loading.set(false)
        this.errorMessage.set(this.mapError(err))
      }
    })
  }

  private mapError(err: unknown) : string{
    if (err instanceof HttpErrorResponse){
      if (err.status === 401) {
        return err.error?.title ?? 'Credenciales inválidas'
      }
      if (err.status === 429){
        return 'Demasiados intentos. Espera un minuto e intenta de nuevo.'
      }
    }
    return 'No se pudo conectar con el servidor. Intenta de nuevo.'
  }
}
