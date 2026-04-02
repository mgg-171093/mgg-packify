# mgg-packgen v3 — Prompt de Contexto Completo

> Este documento contiene TODO el contexto necesario para construir la versión 3 de mgg-packgen
> desde cero. Es un prompt pensado para ser entregado a un agente de IA o a un equipo de desarrollo.

---

## 1. ¿Qué es mgg-packgen?

`mgg-packgen` es una herramienta de escritorio para **Portal Retail de Skandia México**.
Su propósito: automatizar la generación de **packages de instalación** que se envían al equipo
de infraestructura cuando se hace un deploy. Un "package" es un artefacto compuesto por:

1. **Estructura de carpetas** con las subcarpetas de cada tipo de componente (API, SQL, LIFERAY, etc.)
2. **Un manual `.docx`** de instalación con formato corporativo exacto: banner verde, tabla de
   componentes agrupados, sección de proceso numerada por tipo, footer con autor y fecha.
3. **Un `package_meta.json`** en la raíz del package para permitir clonado.

La herramienta la usa **una sola persona** (el autor, Manuel García González) en Windows.
No es un producto comercial — es una herramienta interna personal.

---

## 2. Historia de versiones

| Versión | Nombre físico del repo | Tecnología | Estado |
|---------|------------------------|-----------|--------|
| v1 | `mgg-packgen-v1` (antes `Portal-Retail`) | Python — CLI interactivo con `input()`, single file 1265 líneas | Estable, referencia, NO tocar |
| v2 | `mgg-packgen-v2` (antes `portal-retail-v2`) | Python — TUI Textual, arquitectura en capas | Completa, 45 tests pasan |
| **v3** | `mgg-packgen-v3` | **Flutter Desktop (UI) + Python FastAPI (backend)** | **A construir** |

---

## 3. Arquitectura de v3

### Decisión de stack

- **UI**: Flutter Desktop (Windows) — Material Design 3, fluido, declarativo
- **Backend**: Python FastAPI — HTTP local en `localhost`, reutiliza el 100% de la lógica de v2
- **Comunicación**: REST JSON sobre HTTP local (el servidor FastAPI corre como proceso hijo
  lanzado por Flutter al iniciar)

### Por qué esta separación

La lógica de negocio (generación de `.docx`, manejo de carpetas, persistencia de config) está
completamente probada en Python (v2, 45 tests). Reescribirla en Dart sería duplicar trabajo y
perder la madurez de `python-docx`. Flutter hace lo que mejor hace: UI rica y fluida.

### Diagrama de arquitectura

```
┌─────────────────────────────────────┐
│   Flutter Desktop App (Windows)     │
│                                     │
│  ┌──────────┐  ┌──────────────────┐ │
│  │  Screens │  │  State (Riverpod)│ │
│  └──────────┘  └──────────────────┘ │
│         │             │             │
│         └──── HTTP ───┘             │
│                  │                  │
│           localhost:8787            │
└─────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Python FastAPI (proceso hijo)     │
│                                     │
│  POST /packages/generate            │
│  POST /packages/clone               │
│  GET  /packages/list                │
│  GET  /settings                     │
│  PUT  /settings                     │
│  GET  /health                       │
│                                     │
│  ── Reutiliza de v2 ────────────── │
│  core/component.py   (modelos)      │
│  core/package.py     (PackageConfig)│
│  services/doc_generator.py  (.docx) │
│  services/folder_service.py         │
│  services/copy_service.py           │
│  config/settings.py  (platformdirs) │
└─────────────────────────────────────┘
```

---

## 4. Dominio — Tipos de componente

Existen exactamente **8 tipos de componente** (enum `ComponentType`):

| Key (string) | Label en UI | Carpeta en package | Campos específicos |
|---|---|---|---|
| `liferay_build` | Liferay (Deploy de build) | LIFERAY (sin carpeta física, solo meta) | `build_id` (string) |
| `sql` | SQL | SQL | `scripts[]`, `base_datos` |
| `api_iis` | API IIS (.zip) | API | `nombre_servicio`, `configs[]` (clave/valor) |
| `api_docker` | API Docker / Pipeline CI-CD | API | `nombre_servicio`, `configs[]` (clave/valor) |
| `blob` | Blob Storage (JS/CSS) | BLOB STORAGE | `archivos[]` (nombre, carpeta) |
| `liferay` | Liferay (Remote App / Página) | LIFERAY | `nombre`, `tipo="remote_app"`, `crear_pagina`, `pagina`, `widgets[]` |
| `assets` | Assets (imágenes Liferay) | ASSETS | `archivos[]` (nombre) |
| `apim` | Azure API Management | API | `nombre_servicio` |

**Orden canónico** (siempre en este orden en tabla y en documento):
`liferay_build → sql → api_iis → api_docker → blob → liferay → assets → apim`

**Multi-instancia**: todos los tipos EXCEPTO `liferay_build` permiten N instancias.
`liferay_build` es único (1 sola instancia).

---

## 5. Modelos de datos (Python — reutilizados en v3 API)

### `ComponentConfig` (dataclass)

```python
@dataclass
class ComponentConfig:
    # Obligatorios
    tipo_clave: ComponentType        # StrEnum
    nombre_display: str
    tipo_display: str
    contenedor: str
    estatus: str = "modificado"

    # SQL
    scripts: list[str] = []
    base_datos: str = ""

    # API IIS / Docker / APIM
    nombre_servicio: str = ""
    configs: list[dict[str, str]] = []  # [{"clave": "...", "valor": "..."}]

    # Blob / Assets
    archivos: list[dict[str, str]] = []  # [{"nombre": "...", "carpeta": "..."}]

    # Liferay Build
    build_id: str = ""

    # Liferay Remote App
    nombre: str = ""
    tipo: str = ""                   # "remote_app"
    crear_pagina: bool = False
    pagina: str = ""
    widgets: list[str] = []
```

### `ServerConfig` (dataclass)

```python
@dataclass
class ServerConfig:
    api: str = ""       # Servidor de servicios/APIs
    bd: str = ""        # Servidor de base de datos
    blob: str = ""      # Cuenta Azure Blob Storage
    liferay: str = ""   # Servidor Liferay
```

### `PackageConfig` (dataclass)

```python
@dataclass
class PackageConfig:
    ticket: str                        # ej: "MX01-274906"
    hu_nombre: str                     # Nombre HU / Fix / Spike
    ambiente: str                      # "QA" | "PROD"
    iteracion: str                     # ej: "01"
    ruta_packages: str = ""            # Directorio base donde crear el package
    componentes: list[ComponentConfig] = []
    servidores: ServerConfig = ServerConfig()

    @property
    def package_name(self) -> str:
        # Formato: {ticket}-PortalRetail_{ambiente}-{iteracion.zfill(2)}
        # Ejemplo: MX01-274906-PortalRetail_QA-01
        return f"{self.ticket}-PortalRetail_{self.ambiente}-{self.iteracion.zfill(2)}"
```

### Config persistida (`config.json` via `platformdirs`)

```json
{
  "version": 1,
  "servers": {
    "qa":   { "api": "", "bd": "", "blob": "", "liferay": "" },
    "prod": { "api": "", "bd": "", "blob": "", "liferay": "" }
  },
  "last_used": {
    "ticket": "",
    "hu_nombre": "",
    "ambiente": "QA",
    "iteracion": "01",
    "hu_carpeta": "",
    "tipo_carpeta": "1.-User-Stories"
  }
}
```

---

## 6. API Python FastAPI — Especificación de endpoints

### `GET /health`
Respuesta: `{ "status": "ok", "version": "3.0.0" }`

---

### `GET /settings`
Devuelve la configuración persistida del usuario.

Respuesta:
```json
{
  "servers": {
    "qa":   { "api": "10.42.55.25", "bd": "10.42.55.30", "blob": "", "liferay": "" },
    "prod": { "api": "", "bd": "", "blob": "", "liferay": "" }
  },
  "last_used": {
    "ticket": "MX01-274906",
    "hu_nombre": "Mejora login",
    "ambiente": "QA",
    "iteracion": "01",
    "ruta_packages": "C:\\Packages"
  }
}
```

---

### `PUT /settings`
Guarda la configuración de servidores y last_used.

Body: mismo esquema que `GET /settings`.

Respuesta: `{ "ok": true }`

---

### `POST /packages/generate`
Genera un package completo (carpetas + `.docx` + `package_meta.json`).

Body:
```json
{
  "ticket": "MX01-274906",
  "hu_nombre": "Mejora login",
  "ambiente": "QA",
  "iteracion": "01",
  "ruta_packages": "C:\\Packages",
  "componentes": [
    {
      "tipo_clave": "api_iis",
      "nombre_servicio": "WebRetailAuthentication",
      "configs": [
        { "clave": "ConnectionStrings__Default", "valor": "..." }
      ]
    },
    {
      "tipo_clave": "sql",
      "base_datos": "RAWRAPSIIF",
      "scripts": ["01_MigracionUsuarios.sql"]
    }
  ],
  "servidores": {
    "qa": { "api": "10.42.55.25", "bd": "10.42.55.30", "blob": "", "liferay": "" }
  }
}
```

Respuesta exitosa:
```json
{
  "ok": true,
  "package_name": "MX01-274906-PortalRetail_QA-01",
  "package_dir": "C:\\Packages\\MX01-274906-PortalRetail_QA-01",
  "doc_path": "C:\\Packages\\MX01-274906-PortalRetail_QA-01\\Manual\\MX01-274906-PortalRetail_QA-01.docx",
  "folders_created": ["Manual", "Componentes\\API", "Componentes\\SQL"]
}
```

Respuesta de error:
```json
{
  "ok": false,
  "error": "La ruta no existe: C:\\Packages"
}
```

---

### `POST /packages/clone`
Lee el `package_meta.json` de un package existente y devuelve los datos para pre-llenar el formulario.

Body:
```json
{
  "source_path": "C:\\Packages\\MX01-274906-PortalRetail_QA-01",
  "new_iteracion": "02"
}
```

Respuesta:
```json
{
  "ok": true,
  "prefill": {
    "ticket": "MX01-274906",
    "hu_nombre": "Mejora login",
    "ambiente": "QA",
    "iteracion": "02",
    "ruta_packages": "C:\\Packages",
    "componentes": [ ... ]  // lista de ComponentConfig completa
  }
}
```

---

### `GET /packages/list?base_dir=C:\Packages`
Lista los packages existentes en un directorio (para el selector de clone).

Respuesta:
```json
{
  "packages": [
    {
      "name": "MX01-274906-PortalRetail_QA-01",
      "path": "C:\\Packages\\MX01-274906-PortalRetail_QA-01",
      "has_meta": true,
      "created_at": "2026-03-31T10:00:00"
    }
  ]
}
```

---

## 7. Flutter App — Pantallas y flujo de navegación

### Estructura de pantallas

```
SplashScreen (logo + "conectando al servidor...")
  └── HomeScreen (menú principal)
        ├── NewPackageScreen (formulario completo)
        │     └── SuccessScreen (resultado: nombre, ruta, botón abrir carpeta)
        ├── CloneScreen (selector de package existente)
        │     └── NewPackageScreen (pre-llenado)
        └── SettingsScreen (servidores QA/PROD + last_used)
```

### HomeScreen

Pantalla de bienvenida minimalista:
- Logo / título "mgg-packgen v3"
- Subtítulo "Portal Retail · Skandia México"
- 3 botones grandes y claros:
  - "Nuevo Package" (acción principal, color verde `#70AD47`)
  - "Clonar Package" (color azul `#4472C4`)
  - "Configuración" (color gris neutro)

---

### NewPackageScreen

Formulario en un solo scroll vertical. Secciones:

#### Sección 1 — Datos del Package
| Campo | Tipo | Validación |
|---|---|---|
| Ticket | TextFormField | obligatorio, ej: `MX01-274906` |
| Nombre HU / Fix / Spike | TextFormField | opcional |
| Ambiente | DropdownButton / SegmentedButton | QA | PROD |
| Iteración | TextFormField | obligatorio, default `01` |
| Ruta de packages | TextFormField + botón carpeta | obligatorio, debe existir |

**Preview del nombre**: debajo de iteración mostrar en tiempo real el nombre que tendrá el package:
`MX01-274906-PortalRetail_QA-01` (actualiza live mientras el usuario escribe).

#### Sección 2 — Componentes

**Selector de componentes**: checkboxes o chips seleccionables para los 8 tipos.
Al seleccionar un tipo, aparece su sección de detalles debajo (animación de expansión).
Al deseleccionar, desaparece la sección (con animación). Los datos ingresados se conservan
mientras el tipo siga seleccionado en la misma sesión.

**Orden de visualización** (siempre este orden canónico):
1. Liferay (Deploy de build)
2. SQL
3. API IIS (.zip)
4. API Docker / Pipeline CI-CD
5. Blob Storage (JS/CSS)
6. Liferay (Remote App / Página)
7. Assets (imágenes Liferay)
8. Azure API Management

#### Sección 3 — Detalles por tipo de componente

Cada tipo tiene un card expandible con sus campos. Todos (excepto `liferay_build`) tienen
un botón "+ Agregar otro [tipo]" para agregar múltiples instancias.

**`liferay_build`** — Card única (sin multi-instancia):
- Build ID (TextField, placeholder: `7957`)

**`sql`** — Multi-instancia, por instancia:
- Nombre del script (TextField, placeholder: `01_MigracionUsuarios.sql`)
- Base de datos (TextField, placeholder: `RAWRAPSIIF`)

**`api_iis`** — Multi-instancia, por instancia:
- Nombre del servicio (TextField, placeholder: `WebRetailAuthentication`)
- Lista de configs clave/valor expandible (botón "+ Agregar config")
  - Cada config: [Clave] [Valor] en fila horizontal

**`api_docker`** — Igual que `api_iis`

**`apim`** — Multi-instancia, por instancia:
- Nombre del servicio (TextField)

**`blob`** — Multi-instancia, por instancia:
- Nombre del archivo (TextField, placeholder: `styles.css`)
- Carpeta destino en Blob (TextField, placeholder: `assets/css`)

**`liferay`** — Multi-instancia, por instancia:
- Nombre de la Remote App (TextField, placeholder: `MXAuthentication`)
- Toggle: ¿Es nueva? (Switch/Checkbox)
- Toggle: ¿Crear/actualizar página? (Switch/Checkbox)
  - Si activado: Nombre de página (TextField), Widgets a agregar (TextField, separados por coma)

**`assets`** — Multi-instancia, por instancia:
- Nombre del archivo (TextField, placeholder: `logo.png`)

#### Sección 4 — Servidores

Solo aparecen los campos de servidores que apliquen según los componentes seleccionados:
- Si hay `api_iis`, `api_docker` o `apim` → mostrar "Servidor de servicios/APIs"
- Si hay `sql` → mostrar "Servidor de base de datos"
- Si hay `blob` → mostrar "Azure Blob Storage (URL o cuenta)"
- Si hay `liferay` o `assets` → mostrar "Servidor Liferay"

Pre-llenados con los valores guardados en `settings` para el ambiente seleccionado.
Un toggle "Guardar servidores" permite persistirlos para el próximo uso.

#### Botón Generar

Botón grande verde al final. Al presionar:
1. Validar campos obligatorios (mostrar errores inline en cada campo)
2. Llamar `POST /packages/generate`
3. Mostrar loading indicator
4. Si éxito → navegar a `SuccessScreen`
5. Si error → mostrar snackbar con el error

---

### SuccessScreen

Pantalla de confirmación tras generar un package exitosamente:
- Título "¡Package generado!"
- Nombre del package generado (en grande, verde)
- Ruta de la carpeta (clickeable para abrir en Explorer con `url_launcher`)
- Nombre del archivo `.docx` generado
- Botones:
  - "Abrir carpeta" (abre en Windows Explorer)
  - "Nuevo Package" (vuelve a NewPackageScreen limpio)
  - "Inicio" (vuelve a HomeScreen)

---

### CloneScreen

Dos opciones para clonar:

**Opción A — Ingresar ruta manualmente:**
- TextField para la ruta del package existente
- Botón "Examinar" (FilePicker de carpeta)
- Al ingresar una ruta válida con `package_meta.json`, mostrar preview:
  `Package: MX01-274906-PortalRetail_QA-01 | Ambiente: QA | Componentes: 3`

**Opción B — Listar packages existentes:**
- Si el usuario tiene una `ruta_packages` configurada en last_used, mostrar
  automáticamente la lista de packages en esa carpeta
- Lista con cards: nombre del package, fecha de creación, componentes

Nueva iteración: TextField obligatorio (default: la iteración del package original + 1)

Botón "Continuar" → llama `POST /packages/clone` → navega a `NewPackageScreen` pre-llenado.

---

### SettingsScreen

Dos secciones con tabs o expansión:

**Servidores QA:**
- API/Servicios
- Base de datos
- Azure Blob Storage
- Liferay

**Servidores PROD:**
- Mismos 4 campos

Botón "Guardar" → llama `PUT /settings`.
Botón "Limpiar todo" → resetea a vacíos.

---

## 8. Proceso de arranque del servidor Python

Flutter lanza el servidor FastAPI como **proceso hijo** al iniciar:

```
1. Flutter arranca
2. Busca `mgg-packgen-api.exe` (o `python mgg_packgen_api/main.py`) en la misma carpeta del ejecutable
3. Lo lanza como proceso hijo en background en puerto 8787
4. Muestra SplashScreen con "Iniciando servidor..."
5. Hace poll a `GET /health` cada 500ms hasta recibir respuesta (timeout 10s)
6. Si timeout → mostrar error "No se pudo iniciar el servidor"
7. Si OK → navegar a HomeScreen
8. Al cerrar Flutter → matar el proceso hijo
```

Puerto: `localhost:8787` (fijo, no configurable por el usuario).

---

## 9. Estructura de directorios del proyecto v3

```
mgg-packgen-v3/
├── api/                         ← Python FastAPI backend
│   ├── pyproject.toml
│   ├── README.md
│   └── src/
│       └── mgg_packgen_api/
│           ├── __init__.py
│           ├── main.py          ← FastAPI app + uvicorn
│           ├── routes/
│           │   ├── __init__.py
│           │   ├── health.py
│           │   ├── packages.py
│           │   └── settings.py
│           ├── schemas/
│           │   ├── __init__.py
│           │   ├── package.py   ← Pydantic models (request/response)
│           │   └── settings.py
│           └── services/        ← reutilizado de v2 (copy exacta o import)
│               ├── __init__.py
│               ├── component.py
│               ├── package.py
│               ├── doc_generator.py
│               ├── folder_service.py
│               ├── copy_service.py
│               └── settings_service.py
│
└── app/                         ← Flutter Desktop app
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart             ← MaterialApp + router
    │   ├── core/
    │   │   ├── api_client.dart  ← HTTP client (http o dio)
    │   │   ├── server_manager.dart ← lanza/mata proceso Python
    │   │   └── constants.dart
    │   ├── models/
    │   │   ├── component_config.dart
    │   │   ├── package_config.dart
    │   │   └── settings_model.dart
    │   ├── providers/           ← Riverpod
    │   │   ├── package_provider.dart
    │   │   └── settings_provider.dart
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── home_screen.dart
    │   │   ├── new_package_screen.dart
    │   │   ├── success_screen.dart
    │   │   ├── clone_screen.dart
    │   │   └── settings_screen.dart
    │   └── widgets/
    │       ├── component_selector.dart
    │       ├── component_detail_card.dart
    │       ├── server_form.dart
    │       └── package_name_preview.dart
    └── windows/                 ← config Windows desktop
```

---

## 10. Reglas de negocio críticas (NO romper)

Estas reglas vienen de v1 y son contratos del dominio:

1. **Nombre del package**: siempre `{ticket}-PortalRetail_{ambiente}-{iteracion.zfill(2)}`
   - El `hu_nombre` NO va en el nombre de la carpeta, solo en el título del `.docx`
   - Ejemplos válidos: `MX01-274906-PortalRetail_QA-01`, `MX01-273779-PortalRetail_PROD-02`

2. **QA → UAT en Liferay Build**: cuando el ambiente es QA, el documento escribe "UAT" en la
   sección de Liferay Build. Esto es intencional y específico de este tipo.
   ```python
   ambiente_display = "UAT" if ambiente == "QA" else ambiente
   ```

3. **Footer del `.docx`**: autor siempre "Manuel García González", fecha del día en español
   formato "31 de marzo del 2026". XML directo con tabs en posición 4419 (centro) y 8838 (derecha).

4. **Orden canónico de componentes** en tabla y en secciones del documento:
   `liferay_build → sql → api_iis → api_docker → blob → liferay → assets → apim`

5. **`liferay_build` no crea carpeta física** en Componentes/ — es solo un deploy de build
   que no tiene archivos.

6. **`api_iis` y `api_docker` comparten carpeta `API/`** (igual que `apim`).

7. **Tabla de componentes del `.docx`**: 5 columnas (NOMBRE, ESTATUS, TIPO, CONTENEDOR, UBICACIÓN),
   con filas separadoras de grupo en verde claro `#E2EFD9`. El header es verde `#70AD47` con texto
   blanco. Los bordes de toda la tabla son verde `#C5E0B3`.

8. **Columna NOMBRE**: alineación LEFT. Las otras 4 columnas: alineación CENTER.

9. **`package_meta.json`** se guarda en la raíz del package (no en Manual/).
   Permite clonar el package en el futuro.

10. **Persistencia de servidores**: los servidores QA y PROD se guardan por separado en config.json
    usando `platformdirs`. No deben mezclarse entre ambientes.

---

## 11. Paleta de colores del proyecto

| Color | Hex | Uso |
|---|---|---|
| Verde principal | `#70AD47` | Acciones primarias, headers, títulos |
| Verde claro | `#C5E0B3` | Bordes de tabla en docx |
| Verde muy claro | `#E2EFD9` | Filas separadoras de grupo en tabla |
| Azul | `#4472C4` | Acción "Clonar Package" |
| Fondo oscuro API | `#264D1A` | Botón "agregar instancia" (fondo) |
| Azul oscuro cfg | `#1A1A2E` | Botón "agregar config" (fondo) |

---

## 12. Dependencias Python (API v3)

```toml
[project]
name = "mgg-packgen-api"
version = "3.0.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.110",
    "uvicorn[standard]>=0.29",
    "python-docx>=1.0",
    "platformdirs>=4.0",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "httpx>=0.27",  # para TestClient de FastAPI
    "ruff>=0.4",
]

[project.scripts]
mgg-packgen-api = "mgg_packgen_api.main:start"
```

---

## 13. Dependencias Flutter (app v3)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0      # State management
  http: ^1.2.0                   # HTTP client para la API
  go_router: ^14.0.0             # Routing declarativo
  file_picker: ^8.0.0            # Selector de carpetas (clone, ruta packages)
  url_launcher: ^6.3.0           # Abrir carpeta en Explorer
  google_fonts: ^6.2.0           # Tipografía (Inter o Roboto)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 14. Entorno de desarrollo

- **OS**: Windows 11
- **Python**: 3.14.3
- **Dart**: 3.11.0
- **Flutter**: 3.41.2 (stable, ya instalado)
- **.NET**: 10.0 preview (no relevante para este proyecto)
- **Node**: 24.14.0 (no relevante para este proyecto)
- **Directorio del proyecto**: `D:\Drive\Personal\repos\mgg-packgen-v3\`
- **Referencia v2** (NO modificar): `D:\Drive\Personal\repos\mgg-packgen-v2\`
- **Referencia v1** (NO modificar): `D:\Drive\Personal\repos\mgg-packgen-v1\`

---

## 15. Lo que v3 MEJORA respecto a v2

| Limitación v2 (TUI) | Mejora v3 (GUI Flutter) |
|---|---|
| Multi-instancia y configs clave/valor son incómodos de ingresar en TUI | Cards expandibles, filas horizontales bien alineadas, mucho más visual |
| No hay file picker para la ruta de packages | FilePicker nativo integrado |
| No hay vista previa del nombre del package en tiempo real | Preview live debajo del campo iteración |
| El clone muestra solo texto plano | Cards con metadata visual, lista de packages disponibles |
| Sin pantalla de éxito rica | SuccessScreen con botón "Abrir carpeta" directo a Explorer |
| Servidores configurables pero en pantalla separada poco accesible | Servidores integrados al flujo de generación + Settings screen dedicada |
| No hay indicador de progreso al generar | Loading indicator mientras el servidor procesa |
| Bindings de teclado poco descubribles | Botones y navegación 100% por mouse (más accesible) |

---

## 16. Instrucciones para comenzar el desarrollo

### Paso 1 — API Python

1. Crear `mgg-packgen-v3/api/` con la estructura descripta en sección 9
2. Copiar `services/` de v2 a `api/src/mgg_packgen_api/services/` (copia exacta)
3. Implementar los schemas Pydantic en `schemas/`
4. Implementar los routers en `routes/`
5. Levantar con `uvicorn mgg_packgen_api.main:app --host 127.0.0.1 --port 8787`
6. Verificar con `GET http://localhost:8787/health`

### Paso 2 — Flutter App

1. Crear `mgg-packgen-v3/app/` con `flutter create --org dev.mgg --project-name mgg_packgen app`
2. Agregar dependencias al `pubspec.yaml`
3. Implementar `ServerManager` (lanza proceso hijo Python)
4. Implementar `ApiClient` (wrapper HTTP)
5. Implementar screens en orden: Splash → Home → Settings → NewPackage → Success → Clone

### Paso 3 — Integración

1. Empaquetar la API como ejecutable standalone con PyInstaller:
   `pyinstaller --onefile --name mgg-packgen-api src/mgg_packgen_api/main.py`
2. Copiar el `.exe` a la carpeta de assets de Flutter
3. En producción, Flutter copia el `.exe` junto al ejecutable y lo lanza como proceso hijo

---

## 17. Notas adicionales importantes

- El servidor FastAPI corre en `localhost:8787`. Si el puerto está ocupado, mostrar error claro.
- Todos los paths son Windows (usar `\` o path raw strings). La API debe manejar tanto `/` como `\`.
- El `.docx` generado tiene el autor hardcodeado como "Manuel García González" — no es configurable.
- La columna NOMBRE de la tabla de componentes es LEFT, las demás CENTER. Esto es un detalle
  específico del formato corporativo que se introdujo en v2 y debe mantenerse.
- El campo `hu_nombre` es OPCIONAL — si está vacío, el título del `.docx` queda como
  `{ticket} - Portal Retail - ` (con trailing dash, como en v1).
- `liferay_build` en la tabla de componentes aparece como `LIFERAY Build ID: {build_id}`.
- Para Blob Storage, la columna TIPO es "blob", CONTENEDOR es "Azure Blob Storage".
- Para Assets, el CONTENEDOR es "Liferay" y el TIPO es "recurso".
