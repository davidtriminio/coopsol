# Tarea F1d — Web en vidrio

**Rama:** `feature/web-glass-ui` (10 commits sobre `develop`)
**Fecha:** 2026-10

## Objetivo
Llevar a la web de staff la misma línea gráfica de vidrio que ya tiene la app móvil, para que ambos clientes sean consistentes. La fuente de verdad es la tabla de tokens del [ADR 0002](../adr/0002-sistema-de-diseno-de-vidrio-compartido.md). No hay cambios de lógica, rutas, backend ni mobile.

## Qué cambió

### Web
| Commit | Cambio |
|---|---|
| `feat(web): add glass design tokens and global background` | Tokens `--glass-*` claros y oscuros en `styles.css`, fondo con degradado y dos brillos sobre `body`, clase global `.glass-card` y `color-scheme: light dark` |
| `fix(web): clean up login template markup` | Corrige `class="brand-mark-"`, un `]` suelto en `[animate.enter]` y quita los comentarios de plantilla |
| `feat(web): apply glass style to login` | Login con la tarjeta compartida y los tokens nuevos; pesos 500/600; botón de 44 de alto |
| `feat(web): apply glass style to staff shell` | Barra superior como tarjeta de vidrio flotante y marca "CS" de 32 con radio 10 |
| `feat(web): apply glass style to profile` | Datos del perfil en la tarjeta compartida y botón de 44 de alto |
| `fix(web): use glass tokens on profile logout button` | El botón de cerrar sesión había quedado con los tokens planos |
| `feat(web): apply glass style to staff creation form` | Formulario de alta de staff dentro de una sola tarjeta de vidrio |
| `refactor(web): remove legacy flat design tokens` | Se eliminan los 16 tokens planos que ya nada usaba |
| `test(web): cover glass token contrast` | 11 tests que leen `styles.css` y miden el contraste WCAG; añade `@types/node` como dependencia de desarrollo |

### Repositorio
| Commit | Cambio |
|---|---|
| `chore: stop tracking editor configuration` | `web/.vscode` deja de versionarse y `.vscode/` pasa a `.gitignore`, como ya ocurría con `.idea/` |

## Decisiones clave
- **Vidrio global en `styles.css`:** el fondo se pinta una vez sobre `body` y la tarjeta es una clase global, para que cualquier pantalla futura los herede ([ADR 0002](../adr/0002-sistema-de-diseno-de-vidrio-compartido.md)).
- **Migración sin romper:** los tokens nuevos llevan el prefijo `--glass-` y conviven con los planos; cada pantalla se migró en su propio commit y los planos se borraron al final, tras comprobar con una búsqueda que nada los usaba.
- **Campos y botones siguen en cada componente:** hay duplicación entre login y alta, aceptada. Una clase global o un componente de campo sería sobre-ingeniería para dos pantallas.
- **Sin color de éxito:** el ADR no lo define. El mensaje del alta usa el texto principal en peso 600.
- **Barra superior con radio 18:** una barra tan baja con radio 24 parecería una píldora. Excepción documentada en el ADR.
- **El test lee el CSS real:** copiar los colores dentro del test habría verificado la copia. `?raw` no sirve porque Angular lo trata como CSS; se lee con `fs`.

## Configuración
No hay claves ni variables de entorno nuevas.

## Paquetes
| Proyecto | Paquete | Versión resuelta | Uso |
|---|---|---|---|
| `web` | `@types/node` (dependencia de desarrollo) | 24.19.2 | Solo tipos de `node:fs`, `node:path` y `process` para el spec de tokens. No entra en la app |

El `pnpm-lock.yaml` cambia unas 185 líneas: varios paquetes (`@inquirer/*`, `vite`, `vitest`, `@angular/build`) declaran `@types/node` como dependencia opcional y pnpm los resuelve de nuevo. No se actualizó ninguna versión.

## Validación ejecutada
- [x] `ng build` sin errores tras cada paso, en una copia fuera del repo
- [x] `ng test`: **41 tests** (30 anteriores y 11 nuevos de tokens)
- [x] El test de contraste muerde: con el error oscuro en `#ff9b9b` fallan exactamente 2 tests (valor acordado y contraste)
- [x] Navegador: login, barra, perfil y alta en modo claro y oscuro, con una API simulada de `/api/auth/*`
- [ ] Backend (57) y mobile (145): sin cambios en esta tarea, no se volvieron a correr
- [ ] No se comprobaron los estados de error ni de carga con un backend real, ni el ancho móvil (≤480 px)

## Deuda técnica
- Campos y botones duplicados entre login y alta de staff.
- `button:not(.logout)` del perfil es código muerto.
- El ADR no define un color de éxito.
- El test no cubre qué componente usa qué token: eso es revisión visual.
- Los tokens se mantienen a mano en web y mobile.
- Las listas largas (F2 en adelante) deben usar tarjetas translúcidas sin desenfoque.
- `CorsExtensions.cs` solo permite `GET` y `POST`: F2 deberá ampliarlo para `PUT`, `PATCH` y `DELETE`.
- Sin CI todavía (F10).
