import { inject, Injectable, Service } from '@angular/core'
import { HttpClient } from '@angular/common/http'
import { environment } from '../../../environments/environment'
import { AuthUser, CreateStaffUserRequest } from '../auth/auth.model'
import { Observable } from 'rxjs'

@Injectable({providedIn: 'root'})
export class AdminApiService {
  private readonly http = inject(HttpClient)
  private readonly baseUrl : string = `${environment.apiUrl}/api/admin/users`

  createStaffUser(request: CreateStaffUserRequest):Observable<AuthUser>{
    return this.http.post<AuthUser>(this.baseUrl, request)
  }
}
