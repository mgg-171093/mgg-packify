# Portal Retail — Generador de Packages de Instalación

Script CLI en Python que automatiza la creación de la estructura de carpetas y el manual `.docx` para los packages de instalación del proyecto Portal Retail.

---

## Requisitos

- **Python 3.10+** — verificá con `python --version`
- **python-docx** — librería para generar archivos Word

### Instalación de la dependencia

```powershell
pip install python-docx
```

> Solo se hace una vez. Si ya lo instalaste, podés saltear este paso.

---

## Uso

Desde la carpeta raíz del proyecto:

```powershell
python package_generator.py
```

El script es interactivo: te va haciendo preguntas una por una y al final genera todo automáticamente.

---

## Flujo paso a paso

### 1. Datos del package

El script arranca pidiendo los datos generales:

| Campo | Ejemplo |
|---|---|
| Número de ticket | `MX01-274950` |
| Nombre de la HU / Fix / Spike | `Mejora 4 - Alta usuario 1° vez con OTP` |
| Ambiente | `1` para QA, `2` para PROD |
| Número de iteración | `01`, `02`, `03`... |

> El nombre del package se construye automáticamente:  
> `MX01-274950-PortalRetail_QA-01`

---

### 2. Ubicación de la HU

El script pregunta si el package pertenece a:

```
1. 1.-User-Stories
2. 2.-Spikes
3. 3.-Fixes
```

Luego muestra las carpetas existentes para que elijas o crees una nueva:

```
  Carpetas existentes en 1.-User-Stories:
    1. 1.-HU 2.2 Datos resumen de cuentas
    2. 22.- HU 7.1 Retiro por portal
    ...
    0. Crear nueva carpeta
```

---

### 3. Componentes del package

Para cada componente podés elegir:

```
1. API IIS (.zip)
2. API Docker / Pipeline CI-CD
3. SQL
4. Blob Storage (JS/CSS)
5. Liferay (Deploy de build)
6. Liferay (Remote App / Página)
7. Assets (imágenes Liferay)
8. Azure API Management
```

Podés agregar tantos componentes como necesites. Al terminar de agregar cada uno, el script pregunta:

```
¿Agregar otro componente? [S/n]
```

#### Detalles por tipo de componente

**API IIS (.zip)**
- Nombre del servicio (sin `.zip`), ej: `WebRetailApi`
- ¿Hay cambios en `appsettings` o `web.config`? → Si decís que sí, ingresás pares `clave=valor`

**API Docker / Pipeline CI-CD**
- Nombre del servicio, ej: `WebPersonasApi`
- ¿Hay cambios en variables de entorno? → Si decís que sí, ingresás pares `clave=valor`

**SQL**
- Base de datos:
  - `1` RAWRAPSIIF
  - `2` VinculacionDigital
  - `3` SecurityGlobalApp
  - `4` SOC_Core
  - `5` Otra (la ingresás manualmente)
- Lista de scripts SQL (uno por línea, Enter vacío para terminar)
- Para cada script indica si es `nuevo` o `modificado`

**Blob Storage (JS/CSS)**
- Nombre de la carpeta en Blob Storage, ej: `skmx-personas-retail-bank-accounts`
- Lista de archivos a subir (con extensión), ej: `skmx-personas-retail-bank-accounts.js`
- Para cada archivo indica si es `nuevo` o `modificado`

**Liferay (Deploy de build)**
- Número de build ID, ej: `9229`
- En el manual genera: `Hacer deploy de Liferay en ambiente UAT la build # 9229`
- En la tabla de componentes aparece como: `LIFERAY Build ID: 9229`

**Liferay (Remote App / Página)**
- Nombre de la Remote App, ej: `skmx-personas-retail-bank-accounts`
- ¿Es nueva o modificada?
- ¿Hay que crear/actualizar una página en Liferay?
  - Si sí: nombre de la página y widgets a agregar (separados por coma)

**Assets (imágenes Liferay)**
- Lista de archivos a subir a Documents and Media (con extensión), ej: `cuentas_bancarias.png`

**Azure API Management**
- Nombre del servicio, ej: `WebRetailAuthentication`

---

### 4. Servidores

El script **solo pregunta los servidores que apliquen** según los componentes que elegiste. Si usaste solo SQL y API, no te pregunta el servidor de Liferay.

```
  Servidor de servicios/APIs en QA (IP o nombre): 10.42.55.25
  Servidor de base de datos en QA (IP o nombre): 10.42.55.30
```

> Podés dejar el campo vacío si no sabés la IP — el manual quedará con texto genérico como `QA`.

---

## Resultado

Al terminar el script crea:

```
1.-User-Stories/
  22.- HU 7.1 Retiro por portal/
    packages/
      MX01-274950-PortalRetail_QA-01/         ← carpeta del package
        Componentes/
          API/                                 ← según lo que elegiste
          SQL/
          BLOB STORAGE/
        Manual/
          MX01-274950-PortalRetail_QA-01.docx  ← manual listo para revisar
```

El `.docx` generado tiene el **mismo estilo visual** que los manuales existentes:

- Título con banner verde
- Tabla de componentes afectados (encabezado verde, bordes verdes)
- Nota estándar de respaldo
- Sección de proceso numerada por tipo de componente
- Pasos numerados con los keywords en negrita

---

## Próximos pasos después de generar el package

1. **Copiar los archivos** de componentes a las subcarpetas correspondientes dentro de `Componentes/`
2. **Revisar el manual** en Word — ajustar cualquier detalle puntual
3. **Comprimir** la carpeta como `.zip` cuando esté lista para enviar

---

## Estructura de carpetas del proyecto (referencia)

```
5.-Portal-Retail/
  1.-User-Stories/          ← HUs de desarrollo
    XX.- HU X.X Nombre/
      packages/             ← packages de instalación
        MX01-XXXXXX-PortalRetail-X.X_QA-01/
          Componentes/
            API/            ← zips de builds
            SQL/            ← scripts .sql
            BLOB STORAGE/   ← archivos .js y .css
            ASSETS/         ← imágenes
          Manual/
            MX01-XXXXXX-PortalRetail-X.X_QA-01.docx
      documents/            ← documentos de la HU (diseños, flujos)
      sql/                  ← scripts SQL de referencia
      changes/              ← ajustes que no son código
  2.-Spikes/                ← investigaciones técnicas
  3.-Fixes/                 ← correcciones puntuales
  package_generator.py      ← este script
  README.md                 ← este archivo
```

---

## Convención de nombres de packages

```
MX01-{ticket}-PortalRetail-{hu}_{AMBIENTE}-{iteracion}
```

| Parte | Ejemplo | Descripción |
|---|---|---|
| `MX01-{ticket}` | `MX01-274906` | Número de ticket del sistema |
| `PortalRetail` | `PortalRetail` | Fijo, identifica el proyecto |
| `{hu}` | `9.7` o vacío en fixes | Número de HU (omitir guion si no aplica) |
| `{AMBIENTE}` | `QA` o `PROD` | Ambiente destino, siempre en mayúsculas |
| `{iteracion}` | `01`, `02`, `03` | Número de iteración con cero a la izquierda |

**Ejemplos reales:**

```
MX01-273779-PortalRetail-2.2_QA-02
MX01-274120-PortalRetail-7.1_PROD-01
MX01-274906-PortalRetail_QA-01        ← sin número de HU (fix/mejora general)
MX01-274359-PortalRetail-9.7_QA-04
```

---

## Tipos de componentes — referencia rápida

| Tipo | Carpeta en Componentes | Contenedor | Notas |
|---|---|---|---|
| API IIS (.zip) | `API/` | IIS | El zip se despliega directo en el servidor |
| API Docker | `API/` | Docker | Se hace CI/CD por Jenkins + update schema APIM |
| SQL | `SQL/` | BD específica | Puede haber scripts para múltiples BDs en un mismo package |
| Blob Storage | `BLOB STORAGE/` | Azure Blob Storage | Siempre genera URL SAS después de subir |
| Liferay (build) | `LIFERAY/` | Liferay | Solo pide el Build ID — un único paso en el proceso |
| Liferay (Remote App) | `LIFERAY/` | Liferay | Puede incluir creación de página y widgets |
| Assets | `ASSETS/` | Liferay | Van a Documents and Media |
| Azure APIM | `API/` | Azure API Management | Actualización de schema/definición |

---

## Solución de problemas

**Error: `python` no se reconoce**
```powershell
# Probá con:
python3 package_generator.py
# o verificá que Python esté en el PATH
python --version
```

**Error: `No module named 'docx'`**
```powershell
pip install python-docx
```

**Error al abrir el `.docx` generado**  
Verificá que el archivo no esté siendo usado por otro proceso. Si Word lo tiene abierto, cerralo primero antes de regenerar.

**El manual generado no tiene todos los pasos que necesito**  
El script cubre los patrones estándar. Si hay un caso especial (configuración de Keycloak, migración de BD, pasos manuales en servidor, etc.), completalo directamente en Word después de generar el documento base.
