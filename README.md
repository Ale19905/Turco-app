# Turco — Gestión de turnos de peluquería

Aplicación móvil desarrollada en Flutter para Android, como parte del Primer Examen Parcial de Programación para Dispositivos Móviles, tercer año de Ingeniería Informática.

**Estudiante:** Alejandro del Llano  
**Nombre de la aplicación:** Turco  
**Application ID:** `com.alejandrodelllano.turco`  
**Versión de Flutter:** Flutter 3.47.5

## Descripción

Turco permite al personal de recepción de una peluquería mixta gestionar clientes, servicios, estilistas y turnos mediante una agenda diaria.

Incluye seis pantallas: Agenda, Detalle de turno, Formulario de turno, Clientes, Servicios y Estilistas.

## Tecnologías y arquitectura

- Flutter y Dart para Android.
- Material 3 con tipografía Poppins y modos claro, oscuro y sistema.
- Arquitectura MVVM con `ChangeNotifier` y `ListenableBuilder`.
- Navegación mediante `go_router` y `StatefulShellRoute.indexedStack`.
- Datos de prueba cargados en memoria, sin servidor, autenticación ni base de datos.

## Instalación y ejecución

Tener Flutter y el SDK de Android instalados. Desde la raíz del proyecto, ejecutar:

`flutter pub get`

`flutter run`

## Pruebas

Ejecutar:

`flutter analyze`

`flutter test`

## Generar el APK release

Ejecutar:

`flutter build apk --release`

El APK generado se encuentra en:

`build/app/outputs/flutter-apk/app-release.apk`

Una copia del APK se incluye en la carpeta `entrega/` y también se publica en GitHub Releases.

## Estructura

- `lib/app/`: configuración y navegación.
- `lib/core/`: tema y utilidades.
- `lib/data/`: repositorio y datos de prueba.
- `lib/models/`: entidades y reglas de negocio.
- `lib/viewmodels/`: lógica de presentación.
- `lib/views/`: pantallas.
- `lib/widgets/`: componentes reutilizables.
- `assets/`: fuentes e imágenes.
- `test/`: pruebas automatizadas.
- `capturas/`: capturas reales de la aplicación.
- `entrega/`: APK release.

## Consideraciones

El salón funciona de lunes a sábado de 9:00 a 19:00. Los turnos comienzan en franjas de 30 minutos y deben respetar la disponibilidad de clientes y estilistas.

Los datos se mantienen únicamente durante la ejecución de la aplicación y se reinician cuando se vuelve a iniciar desde cero.