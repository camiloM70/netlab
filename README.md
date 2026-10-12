# NetLab — Laboratorio de Redes

Aplicación Flutter para la actividad de Programación Móvil, **Tema 5: Redes (API REST y conectividad)**.
Permite demostrar con un dispositivo real cómo una app detecta cambios de conectividad y se comunica con servidores mediante HTTP/REST.



## 1. Problema que resuelve
Estar conectado a Wi-Fi no significa tener Internet, y una respuesta HTTP 404 no es un fallo de red. NetLab separa
ambos conceptos: muestra lo que **reporta el sistema** (`connectivity_plus`) y lo que **comprueba una petición HTTP real**.

## 1.1 Diseño y responsive
- **Tema centralizado** en `lib/core/theme/app_theme.dart`: colores (`NetColors`), espaciados (`NetSpacing`), radios (`NetRadius`), tipografía (`TextTheme`), botones, chips, navegación y campos de texto. Tipografía: la del sistema (Roboto en Android); no se añadieron fuentes ni paquetes.
- **Puntos de quiebre** (`widgets/responsive.dart`): <600 móvil, 600–1023 tableta, ≥1024 pantalla grande. Los paneles deciden según el ancho DISPONIBLE (`LayoutBuilder`).
- **Navegación:** barra inferior en móvil (o con poca altura), riel lateral en tableta, riel extendido en pantalla grande.
- **Dashboard:** tarjetas en 1 columna (móvil) o 2/4 columnas según el espacio.
- **API REST:** solicitud y respuesta lado a lado desde ≈860 dp; selector de método con Wrap (GET, POST, PUT, PATCH, DELETE), botones Formatear/Limpiar JSON, pestañas Cuerpo/Encabezados.
- **Historial:** tarjetas en móvil; columnas alineadas desde 720 dp. Las URLs largas se recortan con elipsis.
- **Diagnóstico:** separa "red del dispositivo" (la reporta el sistema) de "acceso real al servicio" (petición HTTP).
- Componentes reutilizables: `PanelCard`, `StatusCard`, `MetricTile`, `PrimaryButton`, `ActionTile`, `EmptyState`, `LoadingState`, `ErrorState`, `MethodBadge`, `ResponsiveGrid`, `TwoPane`, `AdaptiveChipRow`, `confirmDialog`, `HttpMethodSelector`, `RequestEditor`, `ResponseViewer`.
- `test/responsive_test.dart` recorre las 4 secciones con anchos de 320, 360, 390, 430, 600, 768 y 1024 dp buscando errores de layout.

## 2. Funcionalidades
- **Inicio:** conectividad del sistema, accesibilidad del servidor (petición real con timeout), último tiempo de respuesta, contadores de la sesión, actividad reciente.
- **API REST:** GET/POST/PUT/PATCH/DELETE reales, encabezados y cuerpo JSON validados, código de estado, tiempo (cronómetro), encabezados relevantes, JSON formateado, copiar respuesta, cancelar, confirmación en DELETE y ejemplos precargados.
- **Diagnóstico:** cambios de conectividad en vivo, prueba de acceso a un endpoint HTTPS (URL editable), clasificación del tiempo de respuesta HTTP y panel de depuración con **Dio** (interceptor, timeout forzado, 404, DNS).
- **Historial:** registro real de cada solicitud/comprobación, filtros por tipo y resultado, detalle expandible y limpieza con confirmación. Es **en memoria** (se pierde al cerrar la app).

## 3. Tecnologías
| Paquete | Uso |
|---|---|
| `http` | Explorador REST y comprobación del servidor |
| `dio` | Depuración avanzada: interceptor, timeouts, clasificación de errores |
| `connectivity_plus` | Eventos de conectividad del sistema |
| `flutter_localizations` (SDK) | Textos de Material en español |



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
```
`NetLabController` (ChangeNotifier) une los servicios, es el único que se suscribe a la conectividad y cancela todo en `dispose`.
No se usa gestor de estado externo para mantener el código fácil de explicar.

## 5. Instalación
Requisitos: Flutter estable reciente (Dart ≥ 3.5), Android SDK/dispositivo real con depuración USB.


Este repositorio contiene el código Dart, pruebas y `pubspec.yaml`. Las carpetas de plataforma se generan con Flutter:
```bash
# Linux / macOS / Windows
flutter create --org co.netlab --project-name netlab --platforms=android,ios,web .
#   (si Flutter creó lib/main.dart o test/widget_test.dart de ejemplo, restaura los de este proyecto)
#   añade los permisos de la sección 7 y ejecuta:
flutter pub get
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
por `http://` añade `android:usesCleartextTraffic="true"` **solo** en `android/app/src/debug/AndroidManifest.xml`.

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

## 9. Cómo probar errores y falta de conexión
1. **Sin conexión:** activa el modo avión (o apaga Wi-Fi/datos), pulsa *Ejecutar prueba* → "Sin conexión". Observa el cambio en el panel de conectividad.
2. **Wi-Fi sin Internet:** conéctate a una red sin salida: el sistema dirá "Wi-Fi" pero la prueba HTTP fallará.
3. **DNS:** Diagnóstico → Dio → *Host inexistente*.
4. **Timeout:** Diagnóstico → Dio → *Timeout forzado*.
5. **HTTP 404:** API REST → ejemplo *GET 404* (llega respuesta válida; no es fallo de red).
6. **JSON malformado / URL inválida:** escribe un cuerpo roto o una URL sin `https://`: se valida antes de enviar.

## 10. Guion de demostración
1. **Inicio:** "Esto es lo que reporta el sistema (Wi-Fi) y esto lo que comprobó una petición real al servidor."
2. **API REST → GET lista:** muestra el JSON real, el 200 y el tiempo.
3. **POST crear:** muestra el 201 y el aviso de que JSONPlaceholder no persiste; luego *¿Persistió el POST?* → 404.
4. **Tiempo de respuesta:** señala el cronómetro y el tamaño.
5. **Modo avión → Diagnóstico → Ejecutar prueba:** mensaje "Sin conexión" y entrada en el historial.
6. **Desactiva modo avión:** la app detecta el cambio y vuelve a comprobar sola (≈1 s); repite la prueba.
7. **Historial:** filtra por método/resultado y abre un detalle.



## 11. Limitaciones conocidas
- Verificación pendiente (ver aviso inicial). iOS no probado.
- Historial solo en memoria.
- Cancelar una solicitud ignora la respuesta pero no aborta la conexión (con `http` clásico no es posible abortar).
- JSONPlaceholder no persiste los cambios enviados con POST, PUT o DELETE.
- Los datos de `connectivity_plus` varían por plataforma.

## 12. Capturas
_Pendiente: 

## 13. Créditos
El código de NetLab se distribuye bajo la licencia [MIT](./LICENSE).

API de pruebas: [JSONPlaceholder](https://jsonplaceholder.typicode.com), que indica que se puede usar en desarrollos y pruebas; su proyecto no especifica una licencia formal. Consulta su [repositorio](https://github.com/typicode/jsonplaceholder).
