from ninja import Router, Schema
from django.http import HttpResponse, JsonResponse
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
from .models import BarberShop, Appointment, Staff, Service, WhatsAppFlow, WhatsAppTemplate, MetaConfig
from .utils import WhatsAppClient
from .flow_crypto import FlowCrypto
import json
import logging
import os
from datetime import datetime
from decimal import Decimal

logger = logging.getLogger(__name__)
router = Router()

class LocationUpdateSchema(Schema):
    address: str
    latitude: Decimal
    longitude: Decimal
    business_hours: str

class ShopDetailSchema(Schema):
    id: int
    name: str
    address: str = None
    latitude: Decimal = None
    longitude: Decimal = None
    business_hours: str = None

@router.get("/shops/{shop_id}", response=ShopDetailSchema)
def get_shop_location(request, shop_id: int):
    from django.shortcuts import get_object_or_404
    shop = get_object_or_404(BarberShop, pk=shop_id)
    return shop

@router.put("/shops/{shop_id}/location")
def update_shop_location(request, shop_id: int, payload: LocationUpdateSchema):
    from django.shortcuts import get_object_or_404
    shop = get_object_or_404(BarberShop, pk=shop_id)
    shop.address = payload.address
    shop.latitude = payload.latitude
    shop.longitude = payload.longitude
    shop.business_hours = payload.business_hours
    shop.save()
    return {"success": True, "message": "Ubicación y horarios actualizados correctamente"}

def get_verify_token():
    config = MetaConfig.objects.filter(is_active=True).first()
    return config.verify_token if config and config.verify_token else getattr(settings, 'WHATSAPP_VERIFY_TOKEN', "flowcuts_secret_token_2026")

@router.get("/test-flow/{flow_id}")
def test_flow_api(request, flow_id: int):
    try:
        flow = WhatsAppFlow.objects.get(pk=flow_id)
        shop = BarberShop.objects.filter(is_active=True).first()
        if not shop: return {"success": False, "message": "No hay barberías"}
        client = WhatsAppClient(phone_number_id=shop.whatsapp_phone_number_id)
        res = client.send_flow(to="524521006283", flow_id=flow.flow_id, flow_token="test", flow_cta="Probar")
        return {"success": True, "message": "Enviado"}
    except Exception as e: return {"success": False, "message": str(e)}

@router.get("/test-template/{template_id}")
def test_template_api(request, template_id: int):
    try:
        template = WhatsAppTemplate.objects.get(pk=template_id)
        shop = BarberShop.objects.filter(is_active=True).first()
        if not shop: return {"success": False, "message": "No hay barberías"}
        client = WhatsAppClient(phone_number_id=shop.whatsapp_phone_number_id)
        res = client.send_template(to="524521006283", template_name=template.name, language_code=template.language_code)
        return {"success": True, "message": "Enviado"}
    except Exception as e: return {"success": False, "message": str(e)}

@router.get("/webhook")
def verify_webhook(request, hub_mode: str = None, hub_verify_token: str = None, hub_challenge: str = None):
    if hub_mode == "subscribe" and hub_verify_token == get_verify_token():
        return HttpResponse(hub_challenge)
    return HttpResponse("Verification failed", status=403)

@router.get("/logs")
def view_logs(request):
    """Muestra las últimas 50 líneas del archivo debug.log"""
    try:
        log_path = os.path.join(settings.BASE_DIR, 'debug.log')
        if not os.path.exists(log_path):
            return HttpResponse("<pre>No hay logs todavía. Envía un mensaje!</pre>")
        
        with open(log_path, 'r') as f:
            lines = f.readlines()
            last_lines = lines[-50:]
            return HttpResponse(f"<pre>{''.join(last_lines)}</pre>")
    except Exception as e:
        return HttpResponse(f"<pre>Error al leer logs: {str(e)}</pre>")

@router.post("/webhook")
def receive_whatsapp_message(request):
    try:
        data = json.loads(request.body)
        logger.info(f"--- Webhook Payload ---")
        logger.info(json.dumps(data, indent=2))
        
        if not data.get("entry"): return {"status": "ignored"}
        
        entry = data["entry"][0]
        if not entry.get("changes"): return {"status": "ignored"}
        
        value = entry["changes"][0]["value"]
        
        # Ignorar si es un cambio de estado (sent, delivered, read)
        if "messages" not in value:
            return {"status": "ignored"}

        message = value["messages"][0]
        from_number = message.get("from")
        business_number_id = value.get("metadata", {}).get("phone_number_id")
        
        if not from_number or not business_number_id:
            logger.warning("Faltan datos críticos en el mensaje")
            return {"status": "missing_data"}

        shop = BarberShop.objects.filter(whatsapp_phone_number_id=business_number_id, is_active=True).first()
        if not shop:
            logger.warning(f"Tienda no encontrada para ID: {business_number_id}")
            return {"status": "error", "reason": "shop_not_found"}

        client = WhatsAppClient(phone_number_id=shop.whatsapp_phone_number_id)

        # Lógica de respuesta
        if message.get("type") == "text":
            body = message["text"]["body"].lower().strip()
            if any(k in body for k in ["ubicacion", "donde", "llegar"]):
                return send_location(client, from_number, shop)
            if any(k in body for k in ["catalogo", "precios"]):
                return send_catalog_preview(client, from_number, shop)
            return send_main_menu(client, from_number, shop)

        elif message.get("type") == "interactive":
            interactive = message["interactive"]
            if interactive["type"] == "button_reply":
                button_id = interactive["button_reply"]["id"]
                if button_id == "btn_book":
                    flow = shop.default_flow
                    if flow: client.send_flow(from_number, flow.flow_id, f"bk_{from_number}", "Agendar Ahora", flow_action="data_exchange")
                    else: client.send_text(from_number, "Servicio en mantenimiento")
                elif button_id == "btn_catalog": return send_catalog_preview(client, from_number, shop)
                elif button_id == "btn_info": return send_location(client, from_number, shop)

        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error Webhook Fatal: {str(e)}")
        return {"status": "error"}

def send_main_menu(client, to, shop):
    data = {
        "type": "interactive",
        "interactive": {
            "type": "button",
            "body": {"text": f"¡Hola! Bienvenido a *{shop.name}*. 💈\n¿Cómo podemos ayudarte?"},
            "action": {
                "buttons": [
                    {"type": "reply", "reply": {"id": "btn_book", "title": "📅 Agendar Cita"}},
                    {"type": "reply", "reply": {"id": "btn_catalog", "title": "🖼️ Ver Catálogo"}},
                    {"type": "reply", "reply": {"id": "btn_info", "title": "📍 Ubicación/Horas"}}
                ]
            }
        }
    }
    return client.send_message(to, data)

def send_location(client, to, shop):
    # Intentamos obtener coordenadas, dirección y horario del shop o usamos valores demo de Uruapan, Michoacán
    latitude = getattr(shop, 'latitude', None) or 19.414000
    longitude = getattr(shop, 'longitude', None) or -102.052000
    address = getattr(shop, 'address', None) or "Uruapan, Michoacán."
    hours = getattr(shop, 'business_hours', None) or "🕒 Lunes a Sábado de 10:00 AM a 8:00 PM"
    
    # Generamos el enlace oficial de Google Maps con las coordenadas exactas para que dibuje el Pin perfectamente
    maps_url = f"https://www.google.com/maps/search/?api=1&query={latitude},{longitude}"
    
    # 1. Enviamos el mensaje descriptivo con la dirección, horario y el link directo
    info_text = (
        f"📍 *{shop.name}*\n"
        f"🏠 *Dirección:* {address}\n"
        f"🕒 *Horario:* {hours}\n\n"
        f"🗺️ *Cómo llegar (Google Maps):*\n{maps_url}\n\n"
        f"Aquí tienes también el mapa interactivo nativo 👇"
    )
    client.send_text(to, info_text)
    
    # 2. Enviamos el mapa interactivo de WhatsApp
    return client.send_location(
        to=to,
        latitude=latitude,
        longitude=longitude,
        name=shop.name,
        address=address
    )

def send_catalog_preview(client, to, shop):
    services = shop.services.filter(is_active=True)[:30] # Meta allows up to 30 items
    if not services:
        return client.send_text(to, "Catálogo no disponible.")
        
    from core.models import MetaConfig
    db_config = MetaConfig.objects.filter(is_active=True).first()
    catalog_id = db_config.catalog_id if db_config else None
    
    if not catalog_id:
        return client.send_text(to, "Catálogo no configurado.")
        
    retailer_ids = [s.get_retailer_id() for s in services]
    body_text = f"✨ *Nuestro Catálogo* ✨\n\nAquí tienes nuestros servicios disponibles. Haz clic en 'Ver Catálogo' para ver fotos, precios y agregarlos a tu carrito."
    
    response = client.send_product_list(to, catalog_id, retailer_ids, body_text)
    
    # Si Meta rechaza el catálogo (por retrasos de sincronización o revisión), usamos el menú de texto como plan B
    if "error" in response:
        text = "✨ *Nuestro Catálogo* ✨\n\n"
        for s in services:
            text += f"• *{s.name}*: ${s.price}\n"
        fallback_data = {
            "type": "interactive",
            "interactive": {
                "type": "button",
                "body": {"text": text},
                "action": {"buttons": [{"type": "reply", "reply": {"id": "btn_book", "title": "📅 Agendar Ahora"}}]}
            }
        }
        return client.send_message(to, fallback_data)
        
    return response

@router.post("/flow-endpoint/")
def flow_endpoint_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    try:
        body = json.loads(request.body)
        
        # Meta usa llaves para encriptación
        encrypted_flow_data_b64 = body.get("encrypted_flow_data")
        encrypted_aes_key_b64 = body.get("encrypted_aes_key")
        initial_vector_b64 = body.get("initial_vector")
        
        # Si faltan datos encriptados, asumimos que es un error o petición malformada
        if not all([encrypted_flow_data_b64, encrypted_aes_key_b64, initial_vector_b64]):
            return JsonResponse({"error": "Missing encryption parameters"}, status=400)

        # Cargar llave privada desde la base de datos
        config = MetaConfig.objects.filter(is_active=True).first()
        if not config or not config.flow_private_key:
            logger.error("Flow Private Key is not configured in DB.")
            return JsonResponse({"error": "Internal Server Error"}, status=500)

        crypto = FlowCrypto(config.flow_private_key)
        
        try:
            decrypted_payload, aes_key, iv = crypto.decrypt_request(
                encrypted_flow_data_b64, 
                encrypted_aes_key_b64, 
                initial_vector_b64
            )
            logger.info(f"Flow Decrypted Payload: {decrypted_payload}")
        except Exception as e:
            import traceback
            logger.error(f"Failed to decrypt flow payload: {e}")
            logger.error(traceback.format_exc())
            return JsonResponse({"error": "Decryption failed"}, status=400)

        action = decrypted_payload.get("action")
        data = decrypted_payload.get("data", {})
        
        # Si la acción raíz es 'data_exchange', la acción real viene dentro de 'data'
        if action == "data_exchange":
            action = data.get("flow_action")
        
        # Respuesta por defecto
        response_data = {}

        if action == "ping":
            response_data = {
                "data": {
                    "status": "active"
                }
            }
            
        elif action in ["INIT", "BACK"]:
            # Cuando el usuario abre el flujo por primera vez o regresa a la pantalla de inicio
            # Simulamos que esto pertenece a una barbería genérica o buscamos por algún parámetro
            shop = BarberShop.objects.first()
            services = Service.objects.filter(shop=shop, is_active=True)
            staff = Staff.objects.filter(shop=shop, is_active=True)
            
            if not staff.exists():
                # Si no hay subordinados, el dueño/tienda es el barbero por defecto
                staff_options = [{"id": "default", "title": shop.client_name or shop.name}]
            else:
                staff_options = [{"id": str(st.id), "title": st.name} for st in staff]
            
            service_options = [{"id": str(s.id), "title": f"{s.name} - ${s.price}"} for s in services]
            
            # Calcular la fecha de hoy local del shop para la validación min-date
            from zoneinfo import ZoneInfo
            from django.utils import timezone
            tz_name = shop.timezone or 'America/Mexico_City'
            local_tz = ZoneInfo(tz_name)
            now_local = timezone.now().astimezone(local_tz)
            today_local_str = now_local.strftime("%Y-%m-%d")
            
            response_data = {
                "screen": "SCREEN_BOOKING_START",
                "data": {
                    "services": service_options,
                    "staff_members": staff_options,
                    "min_date": today_local_str
                }
            }
            
        elif action == "get_slots":
            # El usuario eligió una fecha y un barbero, pide las horas libres
            date_str = data.get("selected_date") # "YYYY-MM-DD"
            staff_id_raw = data.get("staff_id")
            
            # Resolver staff_id si es "default"
            shop = BarberShop.objects.first()
            if staff_id_raw == "default":
                staff, _ = Staff.objects.get_or_create(
                    shop=shop, 
                    name=shop.client_name or shop.name,
                    defaults={'is_active': True}
                )
                staff_id = staff.id
            else:
                staff_id = staff_id_raw
            
            # Validar si la fecha es en el pasado a nivel de backend
            from zoneinfo import ZoneInfo
            from django.utils import timezone
            import datetime as dt_module
            
            # Obtener la zona horaria comercial del shop
            tz_name = shop.timezone or 'America/Mexico_City'
            local_tz = ZoneInfo(tz_name)
            
            # Obtener tiempo actual en la zona de la tienda
            now_local = timezone.now().astimezone(local_tz)
            today_local_str = now_local.strftime("%Y-%m-%d")
            
            if date_str and date_str < today_local_str:
                # Regresamos al usuario a la primera pantalla y le mandamos el error_message nativo
                services = Service.objects.filter(shop=shop, is_active=True)
                staff = Staff.objects.filter(shop=shop, is_active=True)
                
                if not staff.exists():
                    staff_options = [{"id": "default", "title": shop.client_name or shop.name}]
                else:
                    staff_options = [{"id": str(st.id), "title": st.name} for st in staff]
                
                service_options = [{"id": str(s.id), "title": f"{s.name} - ${s.price}"} for s in services]
                
                response_data = {
                    "screen": "SCREEN_BOOKING_START",
                    "data": {
                        "services": service_options,
                        "staff_members": staff_options,
                        "min_date": today_local_str,
                        "error_message": "⚠️ La fecha seleccionada no puede ser en el pasado. Por favor selecciona hoy o un día futuro."
                    }
                }
            else:
                slots = []
                if date_str:
                    base_date = dt_module.datetime.strptime(date_str, "%Y-%m-%d").date()
                    
                    # Generamos los intervalos (10:00 AM a 8:00 PM, cada 30 minutos)
                    for hour in range(10, 20):
                        for minute in [0, 30]:
                            time_str = f"{hour:02d}:{minute:02d}"
                            
                            # Construir datetime local para este slot
                            slot_time = dt_module.time(hour, minute)
                            slot_datetime = dt_module.datetime.combine(base_date, slot_time)
                            slot_datetime_aware = slot_datetime.replace(tzinfo=local_tz)
                            
                            # Si la fecha es hoy, filtrar slots que ya pasaron
                            if date_str == today_local_str and slot_datetime_aware <= now_local:
                                continue
                            
                            # Revisar si existe una cita en esa fecha y hora para ese barbero
                            conflict = Appointment.objects.filter(
                                staff_id=staff_id, 
                                start_time=slot_datetime_aware
                            ).exists()
                            
                            if not conflict:
                                slots.append({"id": time_str, "title": f"{hour:02d}:{minute:02d}"})
                                
                if not slots:
                    # Si no hay horarios libres, regresamos al usuario a la primera pantalla y le mandamos el error_message amigable
                    services = Service.objects.filter(shop=shop, is_active=True)
                    staff = Staff.objects.filter(shop=shop, is_active=True)
                    
                    if not staff.exists():
                        staff_options = [{"id": "default", "title": shop.client_name or shop.name}]
                    else:
                        staff_options = [{"id": str(st.id), "title": st.name} for st in staff]
                    
                    service_options = [{"id": str(s.id), "title": f"{s.name} - ${s.price}"} for s in services]
                    
                    response_data = {
                        "screen": "SCREEN_BOOKING_START",
                        "data": {
                            "services": service_options,
                            "staff_members": staff_options,
                            "min_date": today_local_str,
                            "error_message": "⚠️ Ya no quedan horarios disponibles para este día. Por favor, selecciona otra fecha."
                        }
                    }
                else:
                    flow_token = decrypted_payload.get("flow_token", "")
                    phone_number = flow_token.replace("bk_", "") if flow_token else ""
                    
                    prefilled_name = ""
                    if phone_number:
                        prev_appt = Appointment.objects.filter(client_phone=phone_number).exclude(client_name="").order_by('-created_at').first()
                        if prev_appt:
                            prefilled_name = prev_appt.client_name
                            
                    response_data = {
                        "screen": "SCREEN_SELECT_TIME",
                        "data": {
                            "service_id": data.get("service_id"),
                            "staff_id": staff_id_raw,
                            "selected_date": date_str,
                            "available_slots": slots,
                            "client_name": prefilled_name
                        }
                    }
            
        elif action == "submit":
            # Confirmación final de la cita
            shop = BarberShop.objects.first()
            service_id = data.get("service_id")
            staff_id = data.get("staff_id")
            date_str = data.get("selected_date")
            time_str = data.get("selected_time")
            client_name = data.get("client_name", "Cliente Flow")
            
            # Obtener el teléfono del cliente desde el flow_token o desde data
            flow_token = decrypted_payload.get("flow_token", "")
            client_phone = flow_token.replace("bk_", "") if flow_token else data.get("client_phone", "")
            
            # Guardar en base de datos de manera timezone-aware
            from zoneinfo import ZoneInfo
            import datetime as dt_module
            tz_name = shop.timezone or 'America/Mexico_City'
            local_tz = ZoneInfo(tz_name)
            
            naive_dt = dt_module.datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %H:%M")
            dt = naive_dt.replace(tzinfo=local_tz)
            
            service = Service.objects.get(id=service_id)
            
            if staff_id == "default":
                # Buscar o crear un staff "genérico" para esta tienda si no existe
                staff, _ = Staff.objects.get_or_create(
                    shop=shop, 
                    name=shop.client_name or shop.name,
                    defaults={'is_active': True}
                )
            else:
                staff = Staff.objects.get(id=staff_id)
            
            # Verificar conflicto en el momento exacto del submit (evitar doble reserva concurrente)
            conflict = Appointment.objects.filter(
                staff=staff, 
                start_time=dt
            ).exists()
            
            if conflict:
                # Si ya está reservado por otro usuario, regeneramos los horarios disponibles (excluyendo el conflictivo)
                from zoneinfo import ZoneInfo
                from django.utils import timezone
                import datetime as dt_module
                
                slots = []
                tz_name = shop.timezone or 'America/Mexico_City'
                local_tz = ZoneInfo(tz_name)
                now_local = timezone.now().astimezone(local_tz)
                today_local_str = now_local.strftime("%Y-%m-%d")
                base_date = dt_module.datetime.strptime(date_str, "%Y-%m-%d").date()
                
                # Generamos los intervalos (10:00 AM a 8:00 PM, cada 30 minutos)
                for hour in range(10, 20):
                    for minute in [0, 30]:
                        time_str = f"{hour:02d}:{minute:02d}"
                        
                        slot_time = dt_module.time(hour, minute)
                        slot_datetime = dt_module.datetime.combine(base_date, slot_time)
                        slot_datetime_aware = slot_datetime.replace(tzinfo=local_tz)
                        
                        # Si la fecha es hoy, filtrar slots que ya pasaron
                        if date_str == today_local_str and slot_datetime_aware <= now_local:
                            continue
                        
                        # Comprobar conflicto real
                        has_conflict = Appointment.objects.filter(
                            staff=staff, 
                            start_time=slot_datetime_aware
                        ).exists()
                        
                        if not has_conflict:
                            slots.append({"id": time_str, "title": f"{hour:02d}:{minute:02d}"})
                            
                response_data = {
                    "screen": "SCREEN_SELECT_TIME",
                    "data": {
                        "service_id": service_id,
                        "staff_id": staff_id,
                        "selected_date": date_str,
                        "available_slots": slots,
                        "client_name": client_name,
                        "error_message": "⚠️ Lo sentimos, este horario acaba de ser reservado por otro cliente. Por favor selecciona una hora diferente."
                    }
                }
            else:
                appointment = Appointment.objects.create(
                    shop=shop,
                    staff=staff,
                    service=service,
                    client_name=client_name,
                    client_phone=client_phone,
                    start_time=dt,
                    status="scheduled"
                )
                
                response_data = {
                    "screen": "SCREEN_SUCCESS",
                    "data": {
                        "extension_message_response": {
                            "params": {
                                "flow_token": decrypted_payload.get("flow_token"),
                                "appointment_id": appointment.id
                            }
                        }
                    }
                }

            # Enviar mensaje de confirmación
            client = WhatsAppClient()
            if not client_phone and "wa_id" in decrypted_payload:
                # Si el payload del flow tiene el ID de la sesión
                pass
            
            # Como WhatsApp no pasa el teléfono automáticamente en submit sin preguntar,
            # lo ideal es mandarle un mensaje si conocemos al sender.
            # (En un ambiente real, el flow_token o algún state tracking se usa para saber quién fue)

        else:
            response_data = {"error": "Unknown action"}

        # Encriptar la respuesta de vuelta a Meta
        logger.info(f"Flow Response Data: {response_data}")
        encrypted_response_b64 = crypto.encrypt_response(response_data, aes_key, iv)
        return HttpResponse(encrypted_response_b64, content_type="text/plain")

    except Exception as e:
        logger.error(f"Error in flow endpoint: {str(e)}")
        return JsonResponse({"error": "Internal Server Error"}, status=500)
