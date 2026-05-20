# Citas - SaaS de Reservaciones Automatizadas por WhatsApp 💈📅

Este proyecto es una plataforma multi-tenant (SaaS) construida en Django y Django Ninja, diseñada para automatizar la reservación de citas para barberías, clínicas y negocios de servicios directamente desde WhatsApp, utilizando la **API de WhatsApp Cloud** y **WhatsApp Flows**.

---

## 🚀 Arquitectura y Tecnologías

El backend está diseñado para soportar alta concurrencia y un procesamiento extremadamente rápido de los payloads encriptados de Meta.

*   **Core:** Python 3.12 & Django 5.0 / 6.0.
*   **Capa de API:** [Django Ninja](https://django-ninja.rest-framework.com/) (Endpoints rápidos, tipados con Pydantic y autogeneración de OpenAPI).
*   **Base de Datos:** PostgreSQL en producción (Soporte local en SQLite para desarrollo rápido).
*   **Seguridad y Criptografía:** `cryptography` & `pycryptodome` (Cifrado RSA/AES para la desencriptación en tiempo real de los payloads de WhatsApp Flows).
*   **Infraestructura:** Docker & Docker Compose (Gunicorn como servidor de aplicaciones y Whitenoise para la gestión eficiente de recursos estáticos).

---

## 🛠️ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:
*   [Docker](https://docs.docker.com/get-docker/) y [Docker Compose](https://docs.docker.com/compose/install/)
*   O bien, un entorno local de **Python 3.12** si no utilizas Docker.

---

## ⚙️ Configuración del Entorno (`.env`)

Crea un archivo `.env` en la raíz del proyecto basándote en las siguientes variables obligatorias:

```env
# Configuración General de Django
SECRET_KEY=tu-clave-secreta-django
DEBUG=True

# Credenciales de WhatsApp (Meta Cloud API)
WHATSAPP_ACCESS_TOKEN=tu-system-user-access-token
WHATSAPP_PHONE_NUMBER_ID=tu-phone-number-id
WHATSAPP_VERIFY_TOKEN=token-de-verificacion-webhook

# Base de Datos
DATABASE_URL=postgres://postgres:postgres@db:5432/flowcuts_db
```

---

## 📦 Inicialización con Docker Compose

La forma recomendada de arrancar el sistema en desarrollo y producción es mediante Docker Compose:

1.  **Construir y levantar los contenedores:**
    ```bash
    docker-compose up --build -d
    ```

2.  **Ejecutar las migraciones de la base de datos:**
    ```bash
    docker-compose exec web python manage.py migrate
    ```

3.  **Crear el superusuario administrador:**
    ```bash
    docker-compose exec web python manage.py createsuperuser
    ```

4.  **Acceder a la aplicación:**
    *   **Panel de Administración (Django Admin):** `http://localhost:8051/admin/`
    *   **Swagger API Docs:** `http://localhost:8051/api/docs`

---

## 🧬 Estructura del Repositorio

*   **`core/`:** La aplicación Django principal.
    *   `api.py`: Contiene los controladores y endpoints de la API (Webhook, Flow Endpoint, logs en tiempo real, etc.).
    *   `models.py`: Estructura del modelo multinivel (`BarberShop` como tenant, `Staff`, `Service`, `Appointment`, `MetaConfig`).
    *   `flow_crypto.py`: Lógica criptográfica para desencriptar peticiones de WhatsApp Flows utilizando la llave privada RSA del negocio, y encriptar las respuestas con la llave AES simétrica generada por Meta.
    *   `utils.py`: Cliente HTTP de WhatsApp (`WhatsAppClient`) para el envío de mensajes interactivos, plantillas y sincronización de catálogo con el Commerce Manager de Meta.
    *   `admin.py`: Interfaz enriquecida de administración de Django con simulador de webhooks y botones interactivos de prueba.
*   **`flowcuts/`:** Directorio del proyecto Django (Configuraciones de rutas, settings, ASGI y WSGI).
*   **`Dockerfile` / `docker-compose.yml`:** Recetas de contenedorización y orquestación multi-contenedor (App + PostgreSQL).

---

## 🔗 Configuración e Integración con Meta (WhatsApp)

Para que el bot procese las citas y los flujos interactivos, debes configurar los siguientes endpoints en tu panel de **Meta Developers**:

### 1. Webhook Principal (Recepción de mensajes)
*   **Callback URL:** `https://tu-dominio.com/api/webhook`
*   **Verify Token:** El valor que definas en `WHATSAPP_VERIFY_TOKEN` (o en el registro activo de `MetaConfig`).
*   **Eventos a suscribir:** `messages`.

### 2. Endpoint del Flujo (WhatsApp Flow Data Exchange)
*   **Endpoint URL:** `https://tu-dominio.com/api/flow-endpoint/`
*   Este endpoint recibe las interacciones que hace el cliente dentro del formulario interactivo de WhatsApp (selección de barbero, día, horario, confirmación), calcula la disponibilidad de horarios disponibles en tiempo real, guarda la cita evitando conflictos de horario y encripta la respuesta de vuelta a Meta.

### 3. Configuración en Django Admin (`MetaConfig`)
Dentro de `http://localhost:8051/admin/core/metaconfig/` debes rellenar la configuración de Meta para activar el flujo:
*   **Verify Token:** Token de seguridad del Webhook.
*   **Catalog ID:** El identificador del catálogo de Meta Commerce Manager para mostrar los servicios como productos interactivos en WhatsApp.
*   **Flow Private Key / Public Key:** Llaves RSA de 2048 bits generadas para el encriptado y validación de WhatsApp Flows.

---

## 🛰️ Referencia de Endpoints API

*   `GET /api/webhook`: Verificación del Webhook por parte de Meta.
*   `POST /api/webhook`: Recepción y respuesta automática de mensajes interactivos de WhatsApp (menú de opciones, previsualización de catálogo nativa, ubicación física y horarios).
*   `POST /api/flow-endpoint/`: Punto de intercambio seguro de datos para **WhatsApp Flows 6.0**. Soporta las siguientes acciones internas:
    *   `INIT` / `BACK`: Carga de servicios, miembros de staff y cálculo de la fecha mínima de reservación.
    *   `get_slots`: Retorna los horarios disponibles (cada 30 min) para un barbero y día específicos, filtrando citas preexistentes en la zona horaria del tenant.
    *   `submit`: Guarda la cita de forma segura y retorna una pantalla de confirmación exitosa con su ID único de reservación.
*   `GET /api/logs`: Visualización rápida en navegador de las últimas 50 líneas del registro de logs (`debug.log`), ideal para depuración en vivo.
*   `GET /api/shops/{shop_id}`: Detalle de ubicación y horarios comerciales del tenant.

---

## 🔒 Aislamiento Multi-Tenant

*   Cada negocio se define en la tabla **`BarberShop`** (tenant independiente).
*   Los servicios (`Service`) y el personal (`Staff`) están ligados directamente al tenant mediante una relación de clave foránea (`ForeignKey`).
*   La lógica de reserva de citas (`Appointment`) valida automáticamente la disponibilidad y las franjas horarias específicas de cada negocio basándose en su zona horaria local asignada (por ejemplo, `America/Mexico_City`), impidiendo que se agenden citas concurrentes para el mismo barbero y fecha.
