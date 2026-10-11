# NetLab — Laboratorio de Redes

Aplicación Flutter para la actividad de Programación Móvil, **Tema 5: Redes (API REST y conectividad)**.
Permite demostrar con un dispositivo real cómo una app detecta cambios de conectividad y se comunica con servidores mediante HTTP/REST.

> **Estado de verificación:** el código se escribió en un entorno sin Flutter ni acceso a `pub.dev`, por lo que
> **`flutter pub get`, `flutter analyze`, `flutter test` y `flutter run` NO se han ejecutado todavía**.
> Antes de la exposición ejecuta los comandos de la sección 6 y corrige lo que aparezca.

## 1. Problema que resuelve
Estar conectado a Wi-Fi no significa tener Internet, y una respuesta HTTP 404 no es un fallo de red. NetLab separa
ambos conceptos: muestra lo que **reporta el sistema** (`connectivity_plus`) y lo que **comprueba una petición HTTP real**.

## 2. Funcionalidades
- **Inicio:** conectividad del sistema, accesibilidad del servidor (petición real con timeout), último tiempo de respuesta, contadores de la sesión, actividad reciente.
- **API REST:** GET/POST/PUT/DELETE reales, encabezados y cuerpo JSON validados, código de estado, tiempo (cronómetro), encabezados relevantes, JSON formateado, copiar respuesta, cancelar, confirmación en DELETE y ejemplos precargados.
- **Diagnóstico:** cambios de conectividad en vivo, prueba de acceso a un endpoint HTTPS (URL editable), clasificación del tiempo de respuesta HTTP y panel de depuración con **Dio** (interceptor, timeout forzado, 404, DNS).
- **Historial:** registro real de cada solicitud/comprobación, filtros por tipo y resultado, detalle expandible y limpieza con confirmación. Es **en memoria** (se pierde al cerrar la app).

## 3. Tecnologías
| Paquete | Uso |
|---|---|
| `http` | Explorador REST y comprobación del servidor |
| `dio` | Depuración avanzada: interceptor, timeouts, clasificación de errores |
| `connectivity_plus` | Eventos de conectividad del sistema |
| `flutter_localizations` (SDK) | Textos de Material en español |

Los números de versión de `pubspec.yaml` son rangos (`^`); si `pub get` se queja con tu SDK, ajusta el rango.

## 4. Arquitectura
```
lib/
  main.dart, app.dart
  core/  config/endpoints.dart · theme/app_theme.dart · errors/net_error.dart · utils/ (json, formato, estados HTTP)
  models/  api_result · history_entry · connectivity_snapshot · severity
  services/ connectivity_service · api_service (http) · dio_api_service · diagnostics_service · history_service · netlab_controller
  features/ shell · dashboard · api_explorer · connectivity (diagnóstico) · history
  widgets/  componentes compartidos
test/       pruebas unitarias y de widgets (clientes HTTP simulados)
backend_local/db.json   API local que SÍ persiste (json-server)
tools/      setup.sh y snippet del AndroidManifest
```
`NetLabController` (ChangeNotifier) une los servicios, es el único que se suscribe a la conectividad y cancela todo en `dispose`.
No se usa gestor de estado externo para mantener el código fácil de explicar.

## 5. Instalación
Requisitos: Flutter estable reciente (Dart ≥ 3.5), Android SDK/dispositivo real con depuración USB.

Este repositorio contiene el código Dart, pruebas y `pubspec.yaml`. Las carpetas de plataforma se generan con Flutter:
```bash
# Linux / macOS / Git Bash
./tools/setup.sh
# Windows (PowerShell) — equivalente manual:
#   flutter create --org co.netlab --project-name netlab --platforms=android,ios,web .
#   (si Flutter creó lib/main.dart o test/widget_test.dart de ejemplo, restaura los de este proyecto)
#   añade los permisos de la sección 7 y ejecuta: flutter pub get
```

## 6. Ejecución y pruebas
```bash
flutter pub get
flutter analyze
flutter test
flutter run            # con el dispositivo Android conectado
flutter run -d chrome  # Web (ver CORS)
```

## 7. Permisos y plataformas
### Android
`android/app/src/main/AndroidManifest.xml`, antes de `<application>`:
- `android.permission.INTERNET`: permite abrir conexiones de red. **Sin él la app funciona en debug pero falla en release.**
- `android.permission.ACCESS_NETWORK_STATE`: permite consultar el estado de la red (lo usa `connectivity_plus`).

Son permisos "normales": **no hay diálogo de autorización en tiempo de ejecución** y NetLab no simula ninguno.
Android bloquea HTTP sin cifrar (cleartext) desde Android 9; por eso las APIs remotas usan HTTPS. Para el backend local
por `http://` añade `android:usesCleartextTraffic="true"` **solo** en `android/app/src/debug/AndroidManifest.xml` (ver `tools/AndroidManifest.snippet.xml`).

### iOS
No requiere permisos para esta app. App Transport Security (ATS) exige HTTPS por defecto; NetLab usa HTTPS y **no** añade excepciones.
Para un backend local por HTTP en iOS necesitarías una excepción ATS en `Info.plist` (solo para desarrollo). iOS no se ha probado (requiere macOS).

### Web — CORS
El navegador bloquea respuestas si el servidor no autoriza el origen con `Access-Control-Allow-Origin`. En ese caso `http` falla con un error
genérico (`XMLHttpRequest error`) y NetLab lo reporta como "Servidor inaccesible" con una pista sobre CORS. **No se intenta eludir CORS desde el cliente.**
Si usas tu propia API, habilita CORS en el backend (p. ej. en json-server ya viene habilitado; en Express, el middleware `cors`).

### Qué es común y qué depende de la plataforma
- Común: peticiones HTTP, tiempos de respuesta, manejo de errores, historial.
- Depende de la plataforma: qué tipos de red reporta `connectivity_plus` (en Web es limitado), el mensaje exacto de los errores de red, cleartext/ATS/CORS.
- No se puede: controlar el Wi-Fi del dispositivo, ni conocer detalles de la red física. NetLab no mide ping ICMP ni velocidad de descarga/subida:
  mide **tiempo de respuesta HTTP**.

## 8. Endpoints
| Endpoint (JSONPlaceholder) | Métodos | Nota |
|---|---|---|
| `/posts?_limit=5`, `/posts/1` | GET | Lectura real |
| `/posts` | POST | 201 con id simulado (101). **No persiste** |
| `/posts/1` | PUT, DELETE | 200. **No persiste** |
| `/posts/99999` | GET | 404 (respuesta HTTP válida) |
| `/posts/101` | GET | 404 tras el POST: demuestra que no se guardó |
| `/todos/1` | GET | Comprobación de servidor |

**Persistencia real:** `cd backend_local && npx json-server@0.17.4 --watch db.json --host 0.0.0.0 --port 3000`.
Emulador Android: `http://10.0.2.2:3000/posts`. Dispositivo físico: `http://IP-DE-TU-PC:3000/posts` (misma red; requiere cleartext en debug).
POST a `/posts` y luego GET a `/posts` mostrará el recurso guardado.

## 9. Cómo probar errores y falta de conexión
1. **Sin conexión:** activa el modo avión (o apaga Wi-Fi/datos), pulsa *Ejecutar prueba* → "Sin conexión". Observa el cambio en el panel de conectividad.
2. **Wi-Fi sin Internet:** conéctate a una red sin salida: el sistema dirá "Wi-Fi" pero la prueba HTTP fallará.
3. **DNS:** Diagnóstico → Dio → *Host inexistente*.
4. **Timeout:** Diagnóstico → Dio → *Timeout forzado*.
5. **HTTP 404:** API REST → ejemplo *GET 404* (llega respuesta válida; no es fallo de red).
6. **JSON malformado / URL inválida:** escribe un cuerpo roto o una URL sin `https://`: se valida antes de enviar.

## 10. Guion de demostración (2–3 min)
1. **Inicio:** "Esto es lo que reporta el sistema (Wi-Fi) y esto lo que comprobó una petición real al servidor."
2. **API REST → GET lista:** muestra el JSON real, el 200 y el tiempo.
3. **POST crear:** muestra el 201 y el aviso de que JSONPlaceholder no persiste; luego *¿Persistió el POST?* → 404.
4. **Tiempo de respuesta:** señala el cronómetro y el tamaño.
5. **Modo avión → Diagnóstico → Ejecutar prueba:** mensaje "Sin conexión" y entrada en el historial.
6. **Desactiva modo avión:** la app detecta el cambio y vuelve a comprobar sola (≈1 s); repite la prueba.
7. **Historial:** filtra por método/resultado y abre un detalle.

*Reparto sugerido (3–4 integrantes):* (1) conceptos REST/HTTP/códigos; (2) arquitectura y `http` + explorador; (3) conectividad, Dio y manejo de errores; (4) permisos, CORS/ATS, pruebas y demo.

## 11. Limitaciones conocidas
- Verificación pendiente (ver aviso inicial). iOS no probado.
- Historial solo en memoria.
- Cancelar una solicitud ignora la respuesta pero no aborta la conexión (con `http` clásico no es posible abortar).
- Con JSONPlaceholder no hay persistencia; usa `backend_local` para demostrarla.
- Los datos de `connectivity_plus` varían por plataforma.

## 12. Capturas
_Pendiente: añadir capturas reales tomadas en el dispositivo._

## 13. Integrantes
- Nombre 1: ______
- Nombre 2: ______
- Nombre 3: ______
- Nombre 4: ______

## 14. Créditos
API de pruebas: [JSONPlaceholder](https://jsonplaceholder.typicode.com). Licencia: definir por el equipo.
