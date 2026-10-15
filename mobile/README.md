# coopsol_mobile

App Flutter para socios de CoopSol. Solo acepta cuentas con rol `Socio`.

## Requisitos

- Flutter estable (ver `pubspec.yaml`).
- API de CoopSol en ejecución.

## Cómo correr en desarrollo

Sin `API_URL`, la app usa `http://10.0.2.2:5143` en el emulador de Android y `http://localhost:5143` en el resto de plataformas.

```powershell
flutter run
```

Para apuntar a otra API:

```powershell
flutter run --dart-define=API_URL=http://192.168.1.50:5143
```

## Cómo compilar en release

En release `API_URL` es obligatoria y debe ser una URL `https` absoluta. Sin ella, la app lanza un error al arrancar.

```powershell
flutter build apk --release --dart-define=API_URL=https://api.ejemplo.hn
```

La URL queda dentro del binario: no es un secreto. Los secretos reales viven solo en el backend.

## Tests

```powershell
flutter test
flutter analyze
```