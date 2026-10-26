# ADR 0002 — Sistema de diseño de vidrio compartido entre web y mobile

- **Estado:** aceptada (implementada en mobile y en web)
- **Fecha:** 2026-10-19
- **Contexto de fase:** deuda de F1 (rama `fix/pre-f2-debt`)

## Contexto

El login de la web usa una línea gráfica de **vidrio**: fondo con gradiente, tarjeta translúcida con desenfoque, fuentes Sora e IBM Plex Sans. El resto de la web de staff es plano. La app móvil usaba el estilo por defecto de Material.

La primera iteración de mobile copió el interior plano de la web y dejó el vidrio solo en el login. No era lo buscado: el objetivo es que **toda la app** siga la línea del vidrio.

## Decisión

- **El vidrio es el estilo de toda la app**, no de una pantalla. El fondo con gradiente se pinta una sola vez, por encima del `Navigator`, para que cualquier pantalla futura lo herede.
- **Una sola paleta** con modo claro y oscuro, que sigue el modo del sistema. El claro usa la familia violeta y lila del oscuro, con más contraste que la versión anterior en teal.
- **Los tokens se duplican a mano** en cada cliente. Esta tabla es la fuente de verdad.
- **Fuentes empaquetadas** (no descargadas en ejecución), con las mismas versiones que la web: Sora v17 e IBM Plex Sans v23, subset latin.
- **Pesos:** cuerpo 500, etiquetas y botones 600, títulos 600. Sora 600 es el peso más alto empaquetado.
- **Nombres en la web:** cada token es una variable CSS `--glass-*` en `web/src/styles.css`: `glow-top`, `glow-bottom`, `base-start`, `base-end`, `card-bg`, `card-border`, `card-shadow`, `text`, `text-muted`, `field-bg`, `field-border`, `btn-bg`, `btn-fg` y `error`. El modo oscuro los redefine dentro de `prefers-color-scheme: dark`.

### Tokens

| Token | Claro | Oscuro |
|---|---|---|
| Brillo superior | `#a99bf0` | `#4b3fae` |
| Brillo inferior | `#e6a3d8` | `#7a2f6b` |
| Base (inicio → fin del gradiente) | `#ece7ff` → `#f6e8f8` | `#1a1330` → `#100b1e` |
| Tarjeta: relleno | `rgba(255,255,255,.55)` | `rgba(255,255,255,.07)` |
| Tarjeta: borde | `rgba(255,255,255,.70)` | `rgba(255,255,255,.20)` |
| Tarjeta: sombra | `rgba(61,50,160,.18)` | `rgba(0,0,0,.35)` |
| Texto | `#1c1436` | `#f5f2ff` |
| Texto secundario | `#4a3f7a` | `#d9d2fa` |
| Campo: relleno | `rgba(255,255,255,.60)` | `rgba(255,255,255,.06)` |
| Campo: borde | `rgba(28,20,54,.22)` | `rgba(255,255,255,.28)` |
| Botón: fondo / texto | `#3d32a0` / `#f2efff` | `#b2a1ff` / `#1c1436` |
| Error | `#b3261e` | `#ffc8c8` |

### Geometría

- Fondo: degradado lineal a 160° (base) más dos brillos radiales elípticos: 120 % × 90 % centrado en 15 % / 10 %, que se desvanece al 55 %, y 120 % × 100 % centrado en 90 % / 85 %, que se desvanece al 60 %.
- Tarjeta: radio 24, desenfoque 20 y saturación 180 %, sombra `0 8px 32px` **solo por fuera** de la tarjeta.
- Campos: radio 10. Botones: píldora, mínimo 140 × 44. Marca: cuadro de 32 con radio 10 y las letras "CS".

## Alternativas consideradas

| Alternativa | Por qué se descartó |
|---|---|
| Interior plano y vidrio solo en las pantallas de acceso | Es lo que se hizo primero y no era el objetivo |
| Generar los tokens para web y mobile desde un solo archivo | Sobre-ingeniería para dos clientes; el costo es mantener la tabla en dos sitios |
| `google_fonts` (descarga en ejecución) | Falla sin red, justo el caso de offline-read, y añade una dependencia |
| Fondo por pantalla (`GlassScaffold`) | Depende de que cada pantalla futura lo recuerde |

## Consecuencias

- **La web aplica el mismo vidrio** (tarea F1d): fondo en `body`, tarjeta como clase global `.glass-card`, y login, barra superior, perfil y alta de staff con los tokens de esta tabla. Los tokens se duplican a mano en cada cliente y un test en la web (`glass-tokens.spec.ts`) lee `styles.css` y fija el contraste.
- **Excepciones en la web:** la barra superior usa radio 18 en lugar de 24, porque una barra tan baja con radio 24 parecería una píldora. No hay token de éxito: el mensaje del alta usa el texto principal en peso 600.
- `BackdropFilter` es costoso en teléfonos de gama baja. Una tarjeta por pantalla es razonable; **en listas largas se usarán tarjetas translúcidas sin desenfoque**.
- El contraste mínimo está fijado con tests (4,5:1 para texto normal). La excepción conocida: las etiquetas dentro de los campos del modo oscuro llegan a 4,1:1 sobre la zona más brillante del brillo violeta.
- El error del modo oscuro (`#ffc8c8`) difiere del `#ff9b9b` que usaba el login web, porque este último llegaba a 3,3:1 sobre el brillo.