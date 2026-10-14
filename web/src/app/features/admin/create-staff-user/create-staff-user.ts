import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core'
import { UserRole } from '../../../core/auth/auth.model'
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms'
import { AdminApiService } from '../../../core/admin/admin-api.service'
import { HttpErrorResponse } from '@angular/common/http'

const STAFF_ROLES: UserRole[] = ['Cajero', 'OficialCredito', 'Gerente', 'Admin']

const ROLE_LABELS: Record<UserRole, string> = {
  Socio: 'Socio',
  Cajero: 'Cajero',
  OficialCredito: 'Oficial crédito',
  Gerente: 'Gerente',
  Admin: 'Administrador',
}

@Component({
  selector: 'app-create-staff-user',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './create-staff-user.html',
  styleUrl: './create-staff-user.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CreateStaffUser {
  private readonly fb = inject(FormBuilder)
  private readonly adminApi = inject(AdminApiService)

  readonly staffRoles = STAFF_ROLES
  readonly roleLabels = ROLE_LABELS

  readonly form = this.fb.nonNullable.group({
    fullName: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(150)]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8), Validators.maxLength(128)]],
    role: ['' as UserRole | '', [Validators.required]],
  })

  readonly submitting = signal(false)
  readonly errorMessage = signal<string | null>(null)
  readonly createdName = signal<string | null>(null)

  submit(): void {
    if (this.form.invalid || this.submitting()) {
      this.form.markAllAsTouched()
      return
    }

    this.submitting.set(true)
    this.errorMessage.set(null)
    this.createdName.set(null)

    const value = this.form.getRawValue()

    this.adminApi.createStaffUser({ ...value, role: value.role as UserRole }).subscribe({
      next: (user) => {
        this.submitting.set(false)
        this.createdName.set(user.fullName)
        this.form.reset({ fullName: '', email: '', password: '', role: '' })
      },
      error: (err: unknown) => {
        this.submitting.set(false)
        this.errorMessage.set(this.mapError(err))
      },
    })
  }

  private mapError(err: unknown): string {
    if (err instanceof HttpErrorResponse) {
      if (err.status === 409) {
        return err.error?.title ?? 'Ya existe un usuario con ese correo.'
      }
      if (err.status === 400) {
        const details = err.error?.errors as Record<string, string[]> | undefined
        const messages = details ? Object.values(details).flat() : []
        return messages[0] ?? 'Revisa los datos del formulario.'
      }
    }
    return 'No se pudo crear el usuario. Intenta de nuevo'
  }
}
